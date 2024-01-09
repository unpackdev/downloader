// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import "./IRariFundPriceConsumer.sol";

/// @notice based on https://github.com/Rari-Capital/rari-stable-pool-contracts/blob/386aa8811e7f12c2908066ae17af923758503739/contracts/RariFundManager.sol
interface IRariFundManager {
    /// @dev Deposits an `amount` of Backing Tokens into pool
    /// @param currencyCode The symbol of the token to be deposited
    /// @param amount The amount of Backing Tokens to be deposited
    function deposit(string calldata currencyCode, uint256 amount) external;

    /// @dev Withdraws an `amount` of Backing Tokens from the pool
    /// @param currencyCode The symbol of the token to withdraw
    /// @param amount The amount of Backing Tokens to withdraw
    /// @return The amount of Backing Tokens that were withdrawn afeter fee deductions (if fees are enabled)
    function withdraw(string calldata currencyCode, uint256 amount) external returns (uint256);

    /// @return Total amount of Backing Tokens in control of the pool
    function getFundBalance() external returns (uint256);

    /// @return The Rari Fund Price Consumer address that is used by the pool
    function rariFundPriceConsumer() external view returns (IRariFundPriceConsumer);

    /// @return The pool's Yield Bearing Token (Fund Token)
    function rariFundToken() external view returns (address);

    /// @return An array of the symbols of the currencies supported by the pool
    function getAcceptedCurrencies() external view returns (string[] memory);

    /// @return Withdrawal Fee Rate (in 18 decimal precision)
    function getWithdrawalFeeRate() external view returns (uint256);
}
