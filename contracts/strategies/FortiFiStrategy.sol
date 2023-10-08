// SPDX-License-Identifier: MIT
// FortiFiStrategy by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IFortress.sol";
import "./interfaces/IVault.sol";
import "./FortiFiFortress.sol";

pragma solidity 0.8.21;

/// @notice Error when vault does not implement ISAMS or IMASS interface (0x23c01392)
error InvalidVaultImplementation();

/// @title Base FortiFi Strategy contract
/// @notice This contract should be used when a yield strategy requires special logic beyond
/// simple deposit(amount deposit token) and withdraw(receipt tokens to burn). These strategies
/// are designed to only be called by FortiFi SAMS and MASS Vaults.
contract FortiFiStrategy is Ownable, ERC20 {
    using SafeERC20 for IERC20;
    address public immutable _strat;
    address public immutable _wNative;
    IERC20 public immutable _dToken;
    
    mapping(address => bool) public isFortiFiVault;
    mapping(address => mapping(uint256 => address)) public vaultToTokenToFortress;

    event FortressCreated(address indexed vault, uint256 tokenId, address indexed strategy);
    event DepositToFortress(address indexed vault, address indexed user, address indexed strategy, uint256 amountDeposited);
    event WithdrawFromFortress(address indexed vault, address indexed user, address indexed strategy, uint256 amountReceived);
    event VaultSet(address vault, bool approved);
    event ERC20Recovered(address indexed token, uint256 amount);
    event ERC20RecoveredFromFortress(address indexed fortress, address indexed token, uint256 amount);

    constructor(address _strategy, address _depositToken, address _wrappedNative) ERC20("FortiFi Strategy Receipt", "FFSR") {
        require(_strategy != address(0), "FortiFi: Invalid strategy");
        require(_depositToken != address(0), "FortiFi: Invalid deposit token");
        require(_wrappedNative != address(0), "FortiFi: Invalid native token");
        _strat = _strategy;
        _wNative = _wrappedNative;
        _dToken = IERC20(_depositToken);
    }

    /// @notice Function to deposit
    /// @dev If a user has not deposited previously, this function will deploy a FortiFiFortress contract
    /// to interact with the underlying strategy for a specific vault receipt token. This allows user deposits to be isolated
    /// as many strategies utilize special logic that is dependent on the balance of the address interacting with them.
    function depositToFortress(uint256 _amount, address _user, uint256 _tokenId) external virtual {
        require(_amount > 0, "FortiFi: 0 deposit");
        require(isFortiFiVault[msg.sender], "FortiFi: Invalid vault");
        _dToken.safeTransferFrom(msg.sender, address(this), _amount);
        IFortress _fortress;

        // If user has not deposited previously, deploy Fortress
        if (vaultToTokenToFortress[msg.sender][_tokenId] == address(0)) {
            FortiFiFortress _fort = new FortiFiFortress(_strat, address(_dToken), address(_wNative), address(this));
            _fortress = IFortress(address(_fort));
            vaultToTokenToFortress[msg.sender][_tokenId] = address(_fortress);
            emit FortressCreated(msg.sender, _tokenId, address(_strat));
        } else {
            _fortress = IFortress(vaultToTokenToFortress[msg.sender][_tokenId]);
        }

        // approve and deposit
        _dToken.approve(address(_fortress), _amount);
        uint256 _receipts = _fortress.deposit(_amount, _user);

        // mint receipt tokens equal to what was received from Fortress
        _mint(msg.sender, _receipts);

        // Refund left over deposit tokens, if any
        uint256 _depositTokenBalance = _dToken.balanceOf(address(this));
        if (_depositTokenBalance > 0) {
            _dToken.safeTransfer(msg.sender, _depositTokenBalance);
        }

        emit DepositToFortress(msg.sender, _user, address(_strat), _amount);
    }

    /// @notice Function to withdraw
    function withdrawFromFortress(uint256 _amount, address _user, uint256 _tokenId) external virtual {
        require(_amount > 0, "FortiFi: 0 withdraw");
        require(vaultToTokenToFortress[msg.sender][_tokenId] != address(0), "FortiFi: No fortress");

        // burn receipt tokens and withdraw from Fortress
        _burn(msg.sender, _amount);
        IFortress(vaultToTokenToFortress[msg.sender][_tokenId]).withdraw(_user);

        uint256 _depositTokenReceived = _dToken.balanceOf(address(this));

        // transfer received deposit tokens
        _dToken.safeTransfer(msg.sender, _depositTokenReceived);

        emit WithdrawFromFortress(msg.sender, _user, address(_strat), _depositTokenReceived);
    }

    /// @notice Set valid vaults
    function setVault(address _vault, bool _approved) external onlyOwner {
        if (!IVault(_vault).supportsInterface(0x23c01392)) revert InvalidVaultImplementation();
        isFortiFiVault[_vault] = _approved;
        emit VaultSet(_vault, _approved);
    }

    /// @notice Emergency function to recover stuck tokens
    function recoverERC20(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit ERC20Recovered(_token, _amount);
    }

    /// @notice Emergency function to recover stuck tokens from Fortress
    function recoverFromFortress(address _fortress, address _token, uint256 _amount) external onlyOwner {
        IFortress(_fortress).recoverERC20(msg.sender, _token, _amount);
        emit ERC20RecoveredFromFortress(_fortress, _token, _amount);
    }

}