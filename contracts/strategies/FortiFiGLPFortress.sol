// SPDX-License-Identifier: MIT
// FortiFiGLPFortress by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IStrategy.sol";
import "./FortiFiFortress.sol";

pragma solidity 0.8.21;

interface IGLPRewardRouter {
    function glpManager() external view returns(address);
    function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external returns (uint256);
    function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external returns (uint256);
}

interface IGLPManager {
    function getPrice(bool _maximise) external view returns (uint256);
}

/// @title FortiFiFortress for GLP Strategy
/// @notice This Fortress can only be used for FortiFiGLPStrategy contracts
contract FortiFiGLPFortress is FortiFiFortress {
    using SafeERC20 for IERC20;
    
    uint16 public slippageBps = 100;
    uint16 public constant BPS = 10000;

    IERC20 public _stakedGLP;
    IERC20 public constant FSGLP = IERC20(0x9e295B5B976a184B14aD8cd72413aD846C299660); // Avalanche fsGLP

    IGLPRewardRouter public rewardRouter;

    constructor(address _strategy, address _sGLP, address _depositToken, address _wrappedNative, address _rewardRouter) 
        FortiFiFortress(_strategy, _depositToken, _wrappedNative) {
        if (_sGLP == address(0)) revert ZeroAddress();
        if (_rewardRouter == address(0)) revert ZeroAddress();
        _stakedGLP = IERC20(_sGLP);
        rewardRouter = IGLPRewardRouter(_rewardRouter);

        // grant approvals
        _stakedGLP.approve(_strategy, type(uint256).max);
        _dToken.approve(rewardRouter.glpManager(), type(uint256).max);
    }

    event StakedGLPSet(address stakedGLP);
    event GLPRewardRouterSet(address rewardRouter);
    event SlippageSet(uint slippage);

    /// @notice Function to deposit
    function deposit(uint256 _amount, address _user) external virtual override onlyOwner returns(uint256 _newStratReceipts){
        if (_amount == 0) revert InvalidDeposit();
        _dToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _beforeBalance = _strat.balanceOf(address(this));

        // get price and mint GLP
        uint256 _glpPrice = IGLPManager(rewardRouter.glpManager()).getPrice(true); // maximize price
        uint256 _glpOut = _amount * 10**30 / _glpPrice * 10**12; // GLP price decimals are 30, GLP decimals 18 - 6 (USDC decimals) = 12 
        uint256 _glpAmount = rewardRouter.mintAndStakeGlp(address(_dToken), _amount, 0, _glpOut * (BPS - slippageBps) / BPS);

        // deposit to underlying strategy
        _strat.deposit(_glpAmount);

        // calculate new strategy receipt tokens received
        _newStratReceipts = _strat.balanceOf(address(this)) - _beforeBalance;

        // refund left over tokens, if any
        _refund(_user);

        emit DepositMade(_amount, _user);
    }

        /// @notice Function to withdraw everything from vault
    function withdraw(address _user, address[] memory _extraTokens) external virtual override onlyOwner {
        uint256 _balance = _strat.balanceOf(address(this));
        if (_balance == 0) revert InvalidWithdrawal();

        _strat.withdraw(_balance);

        // ensure no strategy receipt tokens remain
        _balance = _strat.balanceOf(address(this));
        if (_balance > 0) {
            IERC20(address(_strat)).safeTransfer(_user, _balance);
        }

        uint256 _fsGlpReceived = FSGLP.balanceOf(address(this));

        // redeem GLP for deposit token
        uint256 _glpPrice = IGLPManager(rewardRouter.glpManager()).getPrice(false); 
        uint256 _dTokenOut = _fsGlpReceived * (_glpPrice / 10**18) / 10**(30 - 6); // GLP decimals are 18, price precision is 30 - 6 (USDC decimals)
        rewardRouter.unstakeAndRedeemGlp(address(_dToken), _fsGlpReceived, _dTokenOut * (BPS - slippageBps) / BPS, msg.sender);

        // transfer received deposit tokens and refund left over tokens, if any
        uint256 _depositTokenBalance = _dToken.balanceOf(address(this));
        if (_depositTokenBalance > 0) {
            _dToken.safeTransfer(msg.sender, _depositTokenBalance);
        }

        // transfer extra reward tokens
        uint256 _length = _extraTokens.length;
        if (_length > 0) {
            for(uint256 i = 0; i < _length; i++) {
                IERC20 _token = IERC20(_extraTokens[i]);
                uint256 _tokenBalance = _token.balanceOf(address(this));
                if (_tokenBalance > 0) {
                    _token.safeTransfer(msg.sender, _tokenBalance);
                }
            }
        }

        _refund(_user);

        emit WithdrawalMade(_user);
    }

    /// @notice Grant max approval to underlying strategy for Staked GLP
    /// @dev Since Fortresses do not hold deposit tokens for longer than it takes to complete the 
    /// transaction there should be no risk in granting max approval
    function refreshGlpApprovals() external {
        _stakedGLP.approve(address(_strat), type(uint256).max);
        _dToken.approve(rewardRouter.glpManager(), type(uint256).max);
        emit ApprovalsRefreshed();
    }

    /// @notice Function to set the Staked GLP Contract
    function setStakedGlp(address _newAddress) public onlyOwner {
        _stakedGLP = IERC20(_newAddress);
        emit StakedGLPSet(_newAddress);
    }

    /// @notice Function to set the GLP Reward Router
    function setRewardRouter(address _newAddress) public onlyOwner {
        rewardRouter = IGLPRewardRouter(_newAddress);
        emit GLPRewardRouterSet(_newAddress);
    }

    /// @notice Function to set the slippage if 1% is not sufficient
    function setSlippage(uint16 _amount) external onlyOwner {
        slippageBps = _amount;
        emit SlippageSet(_amount);
    }

}