// "SPDX-License-Identifier: MIT"
pragma solidity 0.6.12;


import "./GovernanceOwnable.sol";

abstract contract Whitelist is GovernanceOwnable {
    mapping(address => bool) whitelist;
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function whitelistAdd(address _address) public onlyGovernance {
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function whitelistRemove(address _address) public onlyGovernance {
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }
}