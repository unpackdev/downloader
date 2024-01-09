// SPDX-License-Identifier: Unlicense

pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";

contract Controller is Ownable {
    mapping(address => bool) operator;

    modifier onlyOperator() {
        require(operator[msg.sender], "Only-operator");
        _;
    }

    constructor() public {
        operator[msg.sender] = true;
    }

    function setOperator(address _operator, bool _whiteList) public onlyOwner {
        operator[_operator] = _whiteList;
    }
}
