// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IStakingFactory {
    event PoolCreated(address indexed sender, address indexed newPool);

    function createPool(
        address _stakingToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _bufferBlocks
    ) external returns (address);

    function ours(address _a) external view returns (bool);

    function listCount() external view returns (uint256);

    function listAt(uint256 _idx) external view returns (address);
}
