// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OpCommon {
    // auth is shared storage with AccountProxy and any OpCode.
    mapping(address => bool) internal _auth;
    address internal accountCenter;

    receive() external payable {}

    modifier onlyAuth() {
        require(_auth[msg.sender], "CHFRY: Permission Denied");
        _;
    }
}
