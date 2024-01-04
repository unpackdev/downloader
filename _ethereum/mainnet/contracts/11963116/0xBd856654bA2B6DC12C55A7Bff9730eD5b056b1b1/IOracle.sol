// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IOracle {
    function getPriceUSD(address reserve) external view returns (uint256);
}