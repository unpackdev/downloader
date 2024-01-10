// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./Context.sol";

import "./Roles.sol";

contract Operator is Context {
    using Roles for Roles.Role;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    Roles.Role private _operators;

    constructor() {
        if (!isOperator(_msgSender())) {
            _addOperator(_msgSender());
        }
    }

    modifier onlyOperator() {
        require(
            isOperator(_msgSender()),
            "OperatorRole: caller does not have the Operator role"
        );
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return _operators.has(account);
    }

    function addOperator(address account) public onlyOperator {
        _addOperator(account);
    }

    function renounceOperator() public {
        _removeOperator(_msgSender());
    }

    function _addOperator(address account) internal {
        _operators.add(account);
        emit OperatorAdded(account);
    }

    function _removeOperator(address account) internal {
        _operators.remove(account);
        emit OperatorRemoved(account);
    }
}