// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;

import "./Ownable.sol";

//operator role
contract OperatorRole is Ownable {
    mapping (address => bool) operators;

    function addOperator(address operator) external onlyOwner {
        operators[operator] = true;
    }

    function removeOperator(address operator) external onlyOwner {
        operators[operator] = false;
    }

    modifier onlyOperator() {
        require(operators[_msgSender()], "OperatorRole: caller is not the operator");
        _;
    }
}
