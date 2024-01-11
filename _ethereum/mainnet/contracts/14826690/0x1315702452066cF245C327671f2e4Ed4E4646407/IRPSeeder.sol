// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Access to the batch seeder used by the Raid Party game
interface IRPSeeder {
    function getBatch() external view returns (uint256);

    function getReqByBatch(uint256 batch) external view returns (bytes32);

    function getNextAvailableBatch() external view returns (uint256);

    function getRandomness(bytes32 key) external view returns (uint256);

    function executeRequestMulti() external;
}
