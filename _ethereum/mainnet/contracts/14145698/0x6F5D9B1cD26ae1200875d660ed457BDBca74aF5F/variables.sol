// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

contract Variables {
    // Auth Module(Address of Auth => bool).
    mapping(address => bool) internal _auth;

    // nonces chainId => nonces
    mapping(uint256 => uint256) internal _nonces;
}
