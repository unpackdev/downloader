// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRelayerManager {
    event RelayerAdded(address indexed addr);
    event RelayerRemoved(address indexed addr);
    struct Pool {
        address addr;
        uint256 index;
        uint256 joinTimestamp;
        uint256 amount;
    }

    function addRelayer(address relayerAddr) external;

    function addRelayerBatch(address[] calldata relayerAddr) external;

    function removeRelayer(address relayerAddr) external;

    function removeRelayerBatch(address[] calldata relayerAddr) external;

    function appId() external view returns (bytes32);

    function getRelayer(uint256 index) external view returns (address);

    function getRelayers() external view returns (address[] memory);

    function pickRelayer(bytes32 seed) external view returns (address);
}
