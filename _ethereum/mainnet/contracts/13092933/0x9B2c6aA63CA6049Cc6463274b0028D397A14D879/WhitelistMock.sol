// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

contract WhitelistMock {
    mapping(address => bool) public whitelist;
    address[] public whitelistedAddresses;
    bool public hasWhitelisting = false;

    constructor(bool _hasWhitelisting) {
        hasWhitelisting = _hasWhitelisting;
    }

    function getWhitelistedAddresses() public view returns (address[] memory) {
        return whitelistedAddresses;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }
}
