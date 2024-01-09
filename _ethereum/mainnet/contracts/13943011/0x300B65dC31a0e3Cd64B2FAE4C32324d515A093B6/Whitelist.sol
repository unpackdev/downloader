// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./Ownable.sol";

contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;
    address[] public whitelistedAddresses;
    bool public hasWhitelisting = false;

    event AddedToWhitelist(address[] accounts);
    event RemovedFromWhitelist(address indexed account);

    modifier onlyWhitelisted() {
        if (hasWhitelisting) {
            require(isWhitelisted(msg.sender), "Must be in the whitelist");
        }
        _;
    }

    constructor(bool _hasWhitelisting) {
        hasWhitelisting = _hasWhitelisting;
    }

    function add(address[] memory _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            require(whitelist[_addresses[i]] != true);
            whitelist[_addresses[i]] = true;
            whitelistedAddresses.push(_addresses[i]);
        }
        emit AddedToWhitelist(_addresses);
    }

    function remove(address _address, uint256 _index) public onlyOwner {
        require(_address == whitelistedAddresses[_index]);
        whitelist[_address] = false;
        delete whitelistedAddresses[_index];
        emit RemovedFromWhitelist(_address);
    }

    function getWhitelistedAddresses() public view returns (address[] memory) {
        return whitelistedAddresses;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }
}
