// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./OwnedUpgradeable.sol";

abstract contract TrustedUpgradeable is OwnedUpgradeable {
    event TrustedUpdated(address trusted, bool setOrUnset);

    mapping(address => uint256) public whitelist;

    modifier onlyTrusted() virtual {
        checkTrusted();
        _;
    }

    function checkTrusted() internal view {
        if (whitelist[msg.sender] == 0) revert Unauthorized();
    }

    function __Trusted_init() internal {
        __Owned_init();
        whitelist[owner] = 1;
    }

    function setTrusted(address trusted, bool trust) public virtual onlyOwner {
        if (trust) whitelist[trusted] = 1;
        else delete whitelist[trusted];
        emit TrustedUpdated(trusted, trust);
    }

    uint256[49] private __gap;
}
