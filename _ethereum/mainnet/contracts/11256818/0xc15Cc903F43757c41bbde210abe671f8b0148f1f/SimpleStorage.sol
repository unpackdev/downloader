pragma solidity ^0.4.24;

contract SimpleStorage {
    string str;

    constructor(string _str) public {
        str = _str;
    }

    function setValue(string _str) public {
        str = _str;
    }

    function getValue() public view returns (string) {
        return str;
    }
}