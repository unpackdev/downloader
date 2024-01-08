// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IOracle {
    function fetch(address token) external returns (uint256 price);

    function fetchPhnxPrice() external returns (uint256 price);
}
