// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "SafeERC20.sol";
import "IERC20.sol";

import "IVaultReserve.sol";
import "Errors.sol";

import "Admin.sol";
import "Vault.sol";

/**
 * @notice Contract holding vault reserves
 * @dev ETH reserves are stored under address(0)
 */
contract VaultReserve is IVaultReserve, Admin {
    using SafeERC20 for IERC20;

    mapping(address => bool) private _whitelistedVaults;
    mapping(address => mapping(address => uint256)) private _balances;

    modifier onlyVault() {
        require(_whitelistedVaults[msg.sender], Error.UNAUTHORIZED_ACCESS);
        _;
    }

    constructor() Admin(msg.sender) {}

    /**
     * @notice Deposit funds into vault reserve.
     * @notice Only callable by a whitelisted vault.
     * @param token Token to deposit.
     * @param amount Amount to deposit.
     * @return True if deposit was successful.
     */
    function deposit(address token, uint256 amount)
        external
        payable
        override
        onlyVault
        returns (bool)
    {
        if (token == address(0)) {
            require(msg.value == amount, Error.INVALID_AMOUNT);
            _balances[msg.sender][token] += msg.value;
            return true;
        }
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 newBalance = IERC20(token).balanceOf(address(this));
        uint256 received = newBalance - balance;
        require(received >= amount, Error.INVALID_AMOUNT);
        _balances[msg.sender][token] += received;
        emit Deposit(msg.sender, token, amount);
        return true;
    }

    /**
     * @notice Withdraw funds from vault reserve.
     * @notice Only callable by a whitelisted vault.
     * @param token Token to withdraw.
     * @param amount Amount to withdraw.
     * @return True if withdrawal was successful.
     */
    function withdraw(address token, uint256 amount) external override onlyVault returns (bool) {
        uint256 accountBalance = _balances[msg.sender][token];
        require(accountBalance >= amount, Error.INSUFFICIENT_BALANCE);

        _balances[msg.sender][token] -= amount;
        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(token).safeTransfer(msg.sender, amount);
        }
        emit Withdraw(msg.sender, token, amount);
        return true;
    }

    /**
     * @notice Whitelist a new vault.
     * @notice Only callable by admin.
     * @param vault Vault to whitelist.
     * @return True if whitelisting was successful.
     */
    function whitelistVault(address vault) external onlyAdmin returns (bool) {
        require(_whitelistedVaults[vault] == false, Error.ADDRESS_WHITELISTED);
        _whitelistedVaults[vault] = true;
        emit VaultListed(vault);
        return true;
    }

    /**
     * @notice Check if a vault is whitelisted.
     * @param vault Vault to whitelist.
     * @return If vault is whitelisted.
     */
    function isWhitelisted(address vault) public view override returns (bool) {
        return _whitelistedVaults[vault];
    }

    /**
     * @notice Check token balance of a specific vault.
     * @param vault Vault to check balance of.
     * @param token Token to check balance in.
     * @return Token balance of vault.
     */
    function getBalance(address vault, address token) public view override returns (uint256) {
        return _balances[vault][token];
    }
}
