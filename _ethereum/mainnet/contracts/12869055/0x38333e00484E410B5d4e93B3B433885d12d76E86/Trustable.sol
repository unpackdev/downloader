// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

abstract contract Trustable is Ownable {
    mapping(address=>bool) public trusted;

    modifier onlyTrusted {
        require(trusted[msg.sender] || msg.sender == owner(), "not trusted");
        _;
    }

    function setTrusted(address user, bool isTrusted) public onlyOwner {
        trusted[user] = isTrusted;
    }
}
