// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @dev Simple Aave lendingPoolAddressesProvider interface.
 */
interface ILendingPoolAddressesProviderV1 {
    function getLendingPool() external view returns (address);
    function getLendingPoolCore() external view returns (address);
}