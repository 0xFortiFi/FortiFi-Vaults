// SPDX-License-Identifier: MIT
// FortiFiWombatStrategy by FortiFi

import "./FortiFiStrategy.sol";
import "./FortiFiWombatFortress.sol";
import "./interfaces/IWombatFortress.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

pragma solidity 0.8.21;

/// @notice Error caused when trying to set slippage to invalid value
error InvalidSlippage();

/// @title Wombat FortiFi Strategy contract
/// @notice This contract allows for FortiFi vaults to utilize Wombat strategies by minting LP tokens and depositing into a 
/// simple vault like Yield Yak
contract FortiFiWombatStrategy is FortiFiStrategy {
    using SafeERC20 for IERC20;

    uint16 public slippageBps = 50;
    uint16 public withdrawalSlippage = 0;
    uint16 public constant BPS = 10000;

    address public lpToken;
    address public pool;

    constructor(address _strategy, 
        address _depositToken,
        address _wrappedNative,
        address _lpToken,
        address _pool,
        address _feeManager,
        address _feeCalculator) 
        FortiFiStrategy(_strategy, _depositToken, _wrappedNative, _feeManager, _feeCalculator) {
            if (_lpToken == address(0)) revert ZeroAddress();
            if (_pool == address(0)) revert ZeroAddress();
            lpToken = _lpToken;
            pool = _pool;
    }

    event ApprovalsRefreshed();
    event SlippageSet(uint16 newSlippage);
    event WithdrawalSlippageSet(uint16 newSlippage);

    /// @notice Function to deposit
    /// @dev If a user has not deposited previously, this function will deploy a FortiFiWombatFortress contract
    /// instead of the base FortiFiFortress contract
    function depositToFortress(uint256 _amount, address _user, uint256 _tokenId) external override {
        if (_amount == 0) revert InvalidDeposit();
        if (!isFortiFiVault[msg.sender]) revert InvalidCaller();
        if (strategyIsBricked) revert StrategyBricked();
        _dToken.safeTransferFrom(msg.sender, address(this), _amount);
        IWombatFortress _fortress;

        // If user has not deposited previously, deploy Fortress
        if (vaultToTokenToFortress[msg.sender][_tokenId] == address(0)) {
            FortiFiWombatFortress _fort = new FortiFiWombatFortress(_strat, address(_dToken), address(_wNative), lpToken, pool);
            _fortress = IWombatFortress(address(_fort));
            vaultToTokenToFortress[msg.sender][_tokenId] = address(_fortress);
            emit FortressCreated(msg.sender, _tokenId, address(_strat));
        } else {
            _fortress = IWombatFortress(vaultToTokenToFortress[msg.sender][_tokenId]);
        }

        // approve and deposit
        _dToken.approve(address(_fortress), _amount);
        uint256 _receipts = _fortress.depositWombat(_amount, slippageBps, _user);

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
    /// @dev Override is required because Wombat Fortresses need slippage passed in to withdrawal function
    function withdrawFromFortress(uint256 _amount, address _user, uint256 _tokenId) external override {
        if (_amount == 0) revert InvalidWithdrawal();
        if (vaultToTokenToFortress[msg.sender][_tokenId] == address(0)) revert NoFortress();

        // burn receipt tokens and withdraw from Fortress
        _burn(msg.sender, _amount);

        if (strategyIsBricked) {
            IWombatFortress(vaultToTokenToFortress[msg.sender][_tokenId]).withdrawBricked(_user);

            emit WithdrawBrickedFromFortress(msg.sender, _user, address(_strat), _tokenId);
        } else {
            IWombatFortress(vaultToTokenToFortress[msg.sender][_tokenId]).withdrawWombat(_user, withdrawalSlippage, extraTokens);

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

    /// @notice Function to set the slippage if 1% is not sufficient
    function setSlippage(uint16 _amount) external onlyOwner {
        slippageBps = _amount;
        emit SlippageSet(_amount);
    }

    /// @notice Function to set the slippage for withdrawals
    function setWithdrawalSlippage(uint16 _amount) external onlyOwner {
        withdrawalSlippage = _amount;
        emit WithdrawalSlippageSet(_amount);
    }

}