// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

interface IEPriceOracle {
    function getPrice() external view returns (uint256);
}
