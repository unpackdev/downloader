// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface ITaskStorage {
    function storeTask(bytes calldata _bytesBlob) external returns (uint256);

    function removeTask(bytes32 _taskHash) external;

    function taskId() external view returns (uint256);

    function taskOwner(bytes32 _taskHash) external view returns (address);
}
