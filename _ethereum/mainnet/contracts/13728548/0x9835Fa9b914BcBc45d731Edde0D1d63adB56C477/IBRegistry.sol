//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IBRegistry
 * @author Protofire
 * @dev Balancer BRegistry contract interface.
 *
 */

interface IBRegistry {
    function getBestPoolsWithLimit(
        address,
        address,
        uint256
    ) external view returns (address[] memory);

    function addPoolPair(
        address,
        address,
        address
    ) external returns (uint256);

    function sortPools(address[] calldata, uint256) external;
}
