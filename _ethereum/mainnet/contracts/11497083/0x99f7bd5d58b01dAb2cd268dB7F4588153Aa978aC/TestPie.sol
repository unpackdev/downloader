// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "./SafeMath.sol";

contract TestPie {
    using SafeMath for uint256;

    mapping(address => uint256) private balance;

    constructor(uint256 _supply, address _address) {
        balance[_address] = _supply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        balance[msg.sender] = balance[msg.sender].sub(_value);
        balance[_to] = balance[_to].add(_value);
        return true;
    }

    function balanceOf(address _address) public view returns (uint256) {
        return balance[_address];
    }
}
