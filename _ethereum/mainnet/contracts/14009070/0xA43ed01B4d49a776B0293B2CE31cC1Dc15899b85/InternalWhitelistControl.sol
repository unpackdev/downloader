// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

abstract contract InternalWhitelistControl is Ownable {

    mapping(address => bool) public accessWhitelist;

    // only whitelisted, owner or this contract
    modifier internalWhitelisted(address inComingAddr) {
        require(
            accessWhitelist[inComingAddr] 
            || inComingAddr == owner()
            || inComingAddr == address(this), "IWC:NoInternalAccess"
        );
        _;
    }

    function addToWhitelist(
        address addAddr
    ) external 
    onlyOwner {
        accessWhitelist[addAddr] = true;
    }

    function removeFromWhitelist(
        address addAddr
    ) external
    onlyOwner {
        accessWhitelist[addAddr] = false;
    }
}