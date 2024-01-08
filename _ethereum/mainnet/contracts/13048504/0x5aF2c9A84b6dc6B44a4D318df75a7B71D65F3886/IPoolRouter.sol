// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

interface IPoolRouter {
    // gets all tokens currently in the pool
    function getPoolTokens() external view returns (address[] memory);

    // gets all tokens currently in the pool
    function getTokenWeights() external view returns (uint256[] memory);
}
