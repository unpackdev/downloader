// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/**
 * @notice Used when an array has invalid length.
 */
error InvalidArrayLength();

/**
 * @notice Used when group of smart vaults or strategies do not have same asset group.
 */
error NotSameAssetGroup();

/**
 * @notice Used when configuring an address with a zero address.
 */
error ConfigurationAddressZero();

/**
 * @notice Used when constructor or intializer parameters are invalid.
 */
error InvalidConfiguration();

/**
 * @notice Used when fetched exchange rate is out of slippage range.
 */
error ExchangeRateOutOfSlippages();

/**
 * @notice Used when an invalid strategy is provided.
 * @param address_ Address of the invalid strategy.
 */
error InvalidStrategy(address address_);

/**
 * @notice Used when doing low-level call on an address that is not a contract.
 * @param address_ Address of the contract
 */
error AddressNotContract(address address_);

/**
 * @notice Used when invoking an only view execution and tx.origin is not address zero.
 * @param address_ Address of the tx.origin
 */
error OnlyViewExecution(address address_);
