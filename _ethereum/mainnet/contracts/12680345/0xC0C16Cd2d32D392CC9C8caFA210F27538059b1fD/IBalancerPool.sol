// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IBalancerPool {
    function getSpotPrice(address, address) external view returns (uint256);
}