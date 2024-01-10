// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./Ownable.sol";

contract ArweaveJsonList is Ownable {
    string public arweaveUrl;

    constructor() Ownable() {}

    function set(string memory url) public onlyOwner {
       arweaveUrl = url;
    }
}