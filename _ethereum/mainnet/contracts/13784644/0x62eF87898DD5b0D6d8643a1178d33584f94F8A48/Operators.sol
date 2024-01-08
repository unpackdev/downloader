// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./EnumerableSet.sol";

contract Operators is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet operators;

    event OperatorsAdded(address[] _operators);
    event OperatorsRemoved(address[] _operators);

    constructor() {}

    modifier onlyOperator() {
        require(
            isOperator(_msgSender()) || (owner() == _msgSender()),
            "caller is not operator"
        );
        _;
    }

    function addOperators(address[] calldata _operators) external onlyOwner {
        for (uint256 i = 0; i < _operators.length; i++) {
            operators.add(_operators[i]);
        }
        emit OperatorsAdded(_operators);
    }

    function removeOperators(address[] calldata _operators) external onlyOwner {
        for (uint256 i = 0; i < _operators.length; i++) {
            operators.remove(_operators[i]);
        }
        emit OperatorsRemoved(_operators);
    }

    function isOperator(address _operator) public view returns (bool) {
        return operators.contains(_operator);
    }

    function numberOperators() external view returns (uint256) {
        return operators.length();
    }

    function operatorAt(uint256 i) external view returns (address) {
        return operators.at(i);
    }

    function getAllOperators()
        external
        view
        returns (address[] memory _operators)
    {
        _operators = new address[](operators.length());
        for (uint256 i = 0; i < _operators.length; i++) {
            _operators[i] = operators.at(i);
        }
    }
}
