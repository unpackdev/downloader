// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./OwnedUpgradeable.sol";

abstract contract TrustedUpgradeable is OwnedUpgradeable {
    event TrustedUpdated(address trusted, bool setOrUnset);

    mapping(address => uint256) public whitelist;

    modifier onlyTrusted() virtual {
        if (whitelist[msg.sender] == 0) revert Unauthorized();

        _;
    }

    function __Trusted_init() internal {
        __Owned_init();
        whitelist[owner] = 1;
    }

    function setTrusted(address trusted) public virtual onlyOwner {
        whitelist[trusted] = 1;
        emit TrustedUpdated(trusted, true);
    }

    function unsetTrusted(address trusted) public virtual onlyOwner {
        delete whitelist[trusted];
        emit TrustedUpdated(trusted, false);
    }

    uint256[49] private __gap;
}
