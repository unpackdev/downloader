// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface ILendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);

    function getPriceOracle() external view returns (address);
}
