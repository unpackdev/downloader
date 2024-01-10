// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./IOracle.sol";

interface IKashiPair {
    function oracle() external view returns (IOracle);

    function oracleData() external view returns (bytes memory);

    function updateExchangeRate() external returns (bool updated, uint256 rate);

    function exchangeRate() external view returns (uint256);
}
