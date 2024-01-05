//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

interface IVault {
    /// Returns underlying token of the vault
    function token() external returns (address);

    /// Deposit from vault
    /// @param amount amount to deposit
    function deposit(uint256 amount) external;

    /// Withdraw from vault
    /// @param amount amount to withdraw
    function withdraw(uint256 amount) external;
}
