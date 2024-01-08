// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IOracle {
    function fetch(address token, bytes calldata data) external returns (uint256 price);

    function fetchAquaPrice() external returns (uint256 price);
}
