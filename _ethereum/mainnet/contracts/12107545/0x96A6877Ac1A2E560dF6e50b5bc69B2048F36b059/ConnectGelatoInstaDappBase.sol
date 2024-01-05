// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./FTask.sol";

// solhint-disable
abstract contract ConnectGelatoInstaDappBase {
    uint256 internal constant _gasOverhead = 100000;
    address public immutable connectGelatoInstaDappBase;

    uint256 public taskId;
    mapping(bytes32 => address) public taskOwner;

    event LogTaskStored(
        uint256 indexed id,
        address indexed submitter,
        bytes32 indexed taskHash,
        bytes _bytesBlob
    );
    event LogTaskRemoved(address indexed remover, bytes32 indexed taskHash);

    constructor() {
        connectGelatoInstaDappBase = address(this);
    }

    function dsaStoreTask(uint256 _vaultId, string memory _typeOfTask)
        external
    {
        ConnectGelatoInstaDappBase(connectGelatoInstaDappBase).storeTask(
            _vaultId,
            _typeOfTask
        );
    }

    function storeTask(uint256 _vaultId, string memory _typeOfTask)
        external
        returns (uint256)
    {
        return _storeTask(abi.encode(msg.sender, _vaultId, _typeOfTask));
    }

    function _storeTask(bytes memory _bytesBlob)
        internal
        returns (uint256 newTaskId)
    {
        newTaskId = taskId + 1;
        taskId = newTaskId;

        bytes32 taskHash = _hashTask(_bytesBlob, taskId);
        taskOwner[taskHash] = msg.sender;

        emit LogTaskStored(taskId, msg.sender, taskHash, _bytesBlob);
    }

    function dsaRemoveTask(bytes32 _taskHash) public {
        ConnectGelatoInstaDappBase(connectGelatoInstaDappBase).removeTask(
            _taskHash
        );
    }

    function removeTask(bytes32 _taskHash) public {
        // Only address which created task can delete it
        address owner = taskOwner[_taskHash];
        require(
            msg.sender == owner,
            "Task Storage: Only Owner can remove tasks"
        );

        // delete task
        delete taskOwner[_taskHash];
        emit LogTaskRemoved(msg.sender, _taskHash);
    }
}
