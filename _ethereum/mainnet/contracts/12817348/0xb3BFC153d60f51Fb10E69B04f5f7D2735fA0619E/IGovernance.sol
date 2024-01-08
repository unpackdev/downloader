//SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

abstract contract IGovernance {
    mapping(address => uint16) public tokenIds;

    function addToken(address _token) external virtual;
}
