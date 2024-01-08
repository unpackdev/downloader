// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./EnumerableSet.sol";
import "./Ownable.sol";

abstract contract ATaskStorage is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => mapping(address => bytes32)) public taskByUsersAction;
    EnumerableSet.AddressSet internal _actions;

    event LogTaskSubmitted(
        bytes32 indexed taskHash,
        address indexed user,
        address indexed action,
        uint256 subBlockNumber,
        bytes payload,
        bool isPermanent
    );
    event LogTaskCancelled(bytes32 indexed taskHash, address indexed user);

    function addAction(address _action) external onlyOwner returns (bool) {
        return _actions.add(_action);
    }

    function removeAction(address _action) external onlyOwner returns (bool) {
        return _actions.remove(_action);
    }

    function isTaskSubmitted(
        address _user,
        bytes32 _taskHash,
        address _action
    ) external view returns (bool) {
        return isUserTask(_user, _taskHash, _action);
    }

    function isActionWhitelisted(address _action) public view returns (bool) {
        return _actions.contains(_action);
    }

    function actions() public view returns (address[] memory actions_) {
        uint256 length = numberOfActions();
        actions_ = new address[](length);
        for (uint256 i; i < length; i++) actions_[i] = _actions.at(i);
    }

    function numberOfActions() public view returns (uint256) {
        return _actions.length();
    }

    function isUserTask(
        address _user,
        bytes32 _taskHash,
        address _action
    ) public view returns (bool) {
        return _taskHash == taskByUsersAction[_user][_action];
    }

    function hashTask(
        address _user,
        uint256 _subBlockNumber,
        bytes memory _payload,
        bool _isPermanent
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(_user, _subBlockNumber, _payload, _isPermanent)
            );
    }

    function _submitTask(
        address _user,
        address _action,
        bytes memory _payload,
        bool _isPermanent
    ) internal {
        require(
            taskByUsersAction[_user][_action] == bytes32(0),
            "ATaskStorage._submitTask : userHasTask."
        );

        bytes32 taskHash = hashTask(
            _user,
            block.number,
            _payload,
            _isPermanent
        );
        taskByUsersAction[_user][_action] = taskHash;

        emit LogTaskSubmitted(
            taskHash,
            _user,
            _action,
            block.number,
            _payload,
            _isPermanent
        );
    }

    function _cancelTask(address _action) internal {
        bytes32 userTask = taskByUsersAction[msg.sender][_action];
        require(
            userTask != bytes32(0),
            "ATaskStorage._cancelTask: noTaskToCancel"
        );

        _removeTask(msg.sender, _action);

        emit LogTaskCancelled(userTask, msg.sender);
    }

    function _verifyAndRemoveTask(
        address _user,
        address _action,
        uint256 _subBlockNumber,
        bytes memory _payload,
        bool _isPermanent
    ) internal returns (bytes32 taskHash) {
        taskHash = _verifyTask(
            _user,
            _action,
            _subBlockNumber,
            _payload,
            _isPermanent
        );
        _removeTask(_user, _action);
    }

    function _removeTask(address _user, address _action) internal {
        delete taskByUsersAction[_user][_action];
    }

    function _modifyTask(
        address _action,
        bytes memory _payload,
        bool _isPermanent
    ) internal {
        _cancelTask(_action);

        bytes32 taskHash = hashTask(
            msg.sender,
            block.number,
            _payload,
            _isPermanent
        );
        taskByUsersAction[msg.sender][_action] = taskHash;

        emit LogTaskSubmitted(
            taskHash,
            msg.sender,
            _action,
            block.number,
            _payload,
            _isPermanent
        );
    }

    function _verifyTask(
        address _user,
        address _action,
        uint256 _subBlockNumber,
        bytes memory _payload,
        bool _isPermanent
    ) internal view returns (bytes32 taskHash) {
        taskHash = hashTask(_user, _subBlockNumber, _payload, _isPermanent);
        require(
            isUserTask(_user, taskHash, _action),
            "ATaskStorage._verifyTask: !userTask"
        );
    }
}
