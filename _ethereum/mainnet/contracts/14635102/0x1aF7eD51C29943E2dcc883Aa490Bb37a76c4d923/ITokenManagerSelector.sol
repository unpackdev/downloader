// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ITokenManagerSelector {
    function getManagerAddress(address tokenAddress) external view returns (address);
}