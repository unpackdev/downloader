// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";

abstract contract OwnableOperatorControl is OwnableUpgradeable {
    event OperatorAdded(address indexed operator);

    mapping(address => bool) private _operators;

    function __OwnableOperatorControl_init() internal initializer {
        __Ownable_init();
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender), 'Role: not Operator');
        _;
    }

    function isOperator(address address_) public view returns (bool) {
        return _operators[address_] == true;
    }

    function addOperators(address[] calldata operators) external onlyOwner {
        for (uint256 i; i < operators.length; i++) {
            _addOperator(operators[i]);
        }
    }

    function removeOperators(address[] calldata operators) external onlyOwner {
        for (uint256 i; i < operators.length; i++) {
            _operators[operators[i]] = false;
        }
    }

    function _addOperator(address operator) internal {
        require(operator != address(0), 'Role: invalid Operator');
        _operators[operator] = true;
        emit OperatorAdded(operator);
    }
}
