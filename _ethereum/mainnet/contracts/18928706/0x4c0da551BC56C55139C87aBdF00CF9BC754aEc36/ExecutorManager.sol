// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ExecutorManager {
    error NotExecutor(address attempted);
    error CannotRemoveSelf();

    mapping(address => bool) public executors;

    constructor() {
        _addExecutor(msg.sender);
    }

    modifier onlyExecutor() {
        if (isExecutor(msg.sender) != true) revert NotExecutor(msg.sender);
        _;
    }

    function isExecutor(address _executor) public view returns(bool) {
        return(executors[_executor] == true);
    }

    function _addExecutor(address _toAdd) internal {
        executors[_toAdd] = true;
    }

    function addExecutor(address _toAdd) onlyExecutor external virtual {
        _addExecutor(_toAdd);
    }

    function _removeExecutor(address _toRemove) internal {
        if (_toRemove == msg.sender) revert CannotRemoveSelf();
        executors[_toRemove] = false;
    }

    function removeExecutor(address _toRemove) onlyExecutor external virtual {
        _removeExecutor(_toRemove);
    }
}
