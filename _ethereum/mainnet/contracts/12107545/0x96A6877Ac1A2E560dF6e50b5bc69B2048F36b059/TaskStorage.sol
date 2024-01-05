// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

abstract contract TaskStorage {
    uint256 public taskId;
    mapping(bytes32 => address) public taskOwner;

    event LogTaskStored(
        uint256 indexed id,
        address indexed user,
        bytes32 indexed taskHash,
        bytes payload
    );
    event LogTaskRemoved(address indexed remover, bytes32 indexed taskHash);

    function hashTask(bytes memory _blob, uint256 _taskId)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_blob, _taskId));
    }

    function _storeTask(bytes memory _blob, address _owner)
        internal
        returns (uint256 newTaskId)
    {
        newTaskId = ++taskId;

        bytes32 taskHash = hashTask(_blob, taskId);
        taskOwner[taskHash] = _owner;

        emit LogTaskStored(taskId, _owner, taskHash, _blob);
    }

    function _removeTask(
        bytes memory _blob,
        uint256 _taskId,
        address _owner
    ) internal {
        // Only address which created task can delete it
        bytes32 taskHash = hashTask(_blob, _taskId);
        require(
            _owner == taskOwner[taskHash],
            "Task Storage: Only Owner can remove tasks"
        );

        // delete task
        delete taskOwner[taskHash];
        emit LogTaskRemoved(msg.sender, taskHash);
    }

    function _updateTask(
        bytes memory _bytesBlob,
        bytes memory _newBytesBlob,
        uint256 _taskId,
        address _owner
    ) internal {
        _removeTask(_bytesBlob, _taskId, _owner);
        bytes32 taskHash = hashTask(_newBytesBlob, _taskId);
        taskOwner[taskHash] = _owner;

        emit LogTaskStored(_taskId, _owner, taskHash, _bytesBlob);
    }
}
