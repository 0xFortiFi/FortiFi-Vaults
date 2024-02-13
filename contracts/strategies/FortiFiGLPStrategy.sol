// SPDX-License-Identifier: MIT
// FortiFiGLPStrategy by FortiFi

import "./FortiFiStrategy.sol";
import "./FortiFiGLPFortress.sol";
import "./interfaces/IGLPFortress.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

pragma solidity 0.8.21;

/// @notice Error caused when trying to set slippage to invalid value
error InvalidSlippage();

/// @title GLP FortiFi Strategy contract
/// @notice This contract allows for FortiFi vaults to utilize GLP strategies by minting GLP with USDC and depositing into a 
/// simple vault like Yield Yak
contract FortiFiGLPStrategy is FortiFiStrategy {
    using SafeERC20 for IERC20;

    uint16 public slippageBps = 100;
    uint16 public constant BPS = 10000;

    address public stakedGLP = 0x5643F4b25E36478eE1E90418d5343cb6591BcB9d;
    address public rewardRouter = 0xB70B91CE0771d3f4c81D87660f71Da31d48eB3B3;

    constructor(address _strategy, 
        address _depositToken, // MUST BE USDC
        address _wrappedNative,
        address _feeManager,
        address _feeCalculator) 
        FortiFiStrategy(_strategy, _depositToken, _wrappedNative, _feeManager, _feeCalculator) {
    }

    event GLPRewardRouterSet(address newManager);
    event StakedGLPSet(address stakedGLP);
    event ApprovalsRefreshed();
    event SlippageSet(uint16 newSlippage);

    /// @notice Function to deposit
    /// @dev If a user has not deposited previously, this function will deploy a FortiFiVectorFortress contract
    /// instead of the base FortiFiFortress contract
    function depositToFortress(uint256 _amount, address _user, uint256 _tokenId) external override {
        if (_amount == 0) revert InvalidDeposit();
        if (!isFortiFiVault[msg.sender]) revert InvalidCaller();
        if (strategyIsBricked) revert StrategyBricked();
        _dToken.safeTransferFrom(msg.sender, address(this), _amount);
        IGLPFortress _fortress;

        // If user has not deposited previously, deploy Fortress
        if (vaultToTokenToFortress[msg.sender][_tokenId] == address(0)) {
            FortiFiGLPFortress _fort = new FortiFiGLPFortress(_strat, stakedGLP, address(_dToken), address(_wNative), rewardRouter);
            _fortress = IGLPFortress(address(_fort));
            vaultToTokenToFortress[msg.sender][_tokenId] = address(_fortress);
            emit FortressCreated(msg.sender, _tokenId, address(_strat));
        } else {
            _fortress = IGLPFortress(vaultToTokenToFortress[msg.sender][_tokenId]);
        }

        // approve and deposit
        _dToken.approve(address(_fortress), _amount);
        uint256 _receipts = _fortress.deposit(_amount, _user);

        // mint receipt tokens = to what was received from Fortress
        _mint(msg.sender, _receipts);

        // Refund left over deposit tokens, if any
        uint256 _depositTokenBalance = _dToken.balanceOf(address(this));
        if (_depositTokenBalance > 0) {
            _dToken.safeTransfer(msg.sender, _depositTokenBalance);
        }

        emit DepositToFortress(msg.sender, _user, address(_strat), _amount);
    }

    /// @notice Function to withdraw
    /// @dev Override is required because Vector Fortresses need slippage passed in to withdrawal function
    function withdrawFromFortress(uint256 _amount, address _user, uint256 _tokenId) external override {
        if (_amount == 0) revert InvalidWithdrawal();
        if (vaultToTokenToFortress[msg.sender][_tokenId] == address(0)) revert NoFortress();

        // burn receipt tokens and withdraw from Fortress
        _burn(msg.sender, _amount);

        if (strategyIsBricked) {
            IGLPFortress(vaultToTokenToFortress[msg.sender][_tokenId]).withdrawBricked(_user);

            emit WithdrawBrickedFromFortress(msg.sender, _user, address(_strat), _tokenId);
        } else {
            IGLPFortress(vaultToTokenToFortress[msg.sender][_tokenId]).withdraw(_user, extraTokens);

            // Send withdrawn deposit tokens
            uint256 _depositTokenBalance = _dToken.balanceOf(address(this));
            if (_depositTokenBalance > 0) {
                _dToken.safeTransfer(msg.sender, _depositTokenBalance);
            }

            // handle fees on extra reward tokens
            uint256 _length = extraTokens.length;
            if (_length > 0) {
                for(uint256 i = 0; i < _length; i++) {
                    IERC20 _token = IERC20(extraTokens[i]);
                    uint256 _tokenBalance = _token.balanceOf(address(this));
                    if (_tokenBalance > 0) {
                        uint256 _fee = feeCalc.getFees(_user, _tokenBalance);
                        feeMgr.collectFees(extraTokens[i], _fee);
                        _token.safeTransfer(_user, _tokenBalance - _fee);
                    }
                }
            }

            emit WithdrawFromFortress(msg.sender, _user, address(_strat), _tokenId, _depositTokenBalance);
        }
    }


    /// @notice Function to set the GLP Reward Manager
    function setGlpRewardRouter(address _newManager) public onlyOwner {
        rewardRouter = _newManager;
        emit GLPRewardRouterSet(_newManager);
    }

    /// @notice Function to set the GLP Reward Router Contract in FortiFiGLPFortress contracts. 
    /// @dev This function uses the address of the current rewardRouter variable for strategy. Update that first if necessary.
    function setRewardRouterForFortresses(address[] calldata _fortresses) public onlyOwner {
        uint256 _length = _fortresses.length;
        for(uint256 i = 0; i < _length; i++) {
            IGLPFortress(_fortresses[i]).setRewardRouter(rewardRouter);
        }
    }

    /// @notice Function to set the Staked GLP Contract
    function setStakedGlp(address _newAddress) public onlyOwner {
        stakedGLP = _newAddress;
        emit StakedGLPSet(_newAddress);
    }

    /// @notice Function to set the Staked GLP Contract in FortiFiGLPFortress contracts. 
    /// @dev This function uses the address of the current stakedGLP variable for strategy. Update that first if necessary.
    function setStakedGlpForFortresses(address[] calldata _fortresses) public onlyOwner {
        uint256 _length = _fortresses.length;
        for(uint256 i = 0; i < _length; i++) {
            IGLPFortress(_fortresses[i]).setStakedGlp(stakedGLP);
        }
    }

    /// @notice Function to set the slippage if 1% is not sufficient
    function setSlippage(uint16 _amount) external onlyOwner {
        slippageBps = _amount;
        emit SlippageSet(_amount);
    }

    /// @notice Function to set slippage for FortiFiFortress contracts
    function setSlippageForFortresses(address[] calldata _fortresses, uint256 _amount) public onlyOwner {
        if (_amount > 500 || _amount < 10) revert InvalidSlippage();
        uint256 _length = _fortresses.length;
        for(uint256 i = 0; i < _length; i++) {
            IGLPFortress(_fortresses[i]).setSlippage(_amount);
        }
    }

}