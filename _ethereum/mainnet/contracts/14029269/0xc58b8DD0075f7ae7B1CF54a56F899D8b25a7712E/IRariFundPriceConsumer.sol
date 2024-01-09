// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

/// @notice based on https://github.com/Rari-Capital/rari-stable-pool-contracts/blob/386aa8811e7f12c2908066ae17af923758503739/contracts/RariFundPriceConsumer.sol
interface IRariFundPriceConsumer {
    /// @dev The ordering of the returned currencies is hardcoded here - https://github.com/Rari-Capital/rari-stable-pool-contracts/blob/386aa8811e7f12c2908066ae17af923758503739/contracts/RariFundPriceConsumer.sol#L111
    /// @return the price of each supported currency in USD (scaled by 1e18).
    /// `IRariFundManager.getAcceptedCurrencies()` returns the supported currency symbols.
    /// Each `IRariFundManager` has an associated `IRariFundPriceConsumer`, and the prices
    /// returned here correspond to those currencies, in the same order.
    function getCurrencyPricesInUsd() external view returns (uint256[] memory);
}
