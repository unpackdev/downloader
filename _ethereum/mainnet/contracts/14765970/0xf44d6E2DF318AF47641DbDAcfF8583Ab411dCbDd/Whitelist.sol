//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "./Ownable.sol";

contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;

    function isWhitelisted(address account) public view returns (bool) {
        return whitelist[account];
    }

    function toggleWhitelisted(address account, bool toggle) public onlyOwner {
        whitelist[account] = toggle;
    }
}
