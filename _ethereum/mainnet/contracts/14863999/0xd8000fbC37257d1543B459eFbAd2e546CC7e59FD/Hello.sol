//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.23;

contract Hello {

    string public name;

    constructor(string  memory name_) public {
        name = name_;
    }

    function setName(string _name) public {
        name = _name;
    }

    function get() public view returns (string) {
        return string(abi.encodePacked(name, " hello!"));
    }
}