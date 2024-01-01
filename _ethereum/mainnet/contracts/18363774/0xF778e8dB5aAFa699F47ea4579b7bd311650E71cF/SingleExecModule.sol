// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./EnumerableSet.sol";
import "./TaskModuleBase.sol";
import "./LibEvents.sol";

contract SingleExecModule is TaskModuleBase {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @inheritdoc TaskModuleBase
    function postExecCall(
        bytes32 _taskId,
        address _taskCreator,
        address,
        bytes calldata
    ) external override {
        _createdTasks[_taskCreator].remove(_taskId);

        emit LibEvents.TaskCancelled(_taskId, _taskCreator);
    }
}
