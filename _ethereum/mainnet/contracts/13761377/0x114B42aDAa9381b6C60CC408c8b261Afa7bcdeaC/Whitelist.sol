// SPDX-License-Identifier: Unlicensed
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, hagen@token-forge.io

pragma solidity >=0.8.0 <0.9.0;

import "./AccessControlEnumerable.sol";
import "./Counters.sol";
import "./Context.sol";

contract WhiteList is Context, AccessControlEnumerable {
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST");
    bytes32 public constant WHITELIST_ADMIN_ROLE = keccak256("WHITELIST_ADMIN");

    constructor() {
        _setupRole(WHITELIST_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(WHITELIST_ROLE, WHITELIST_ADMIN_ROLE);
    }

    function addToWhiteList(address beneficiary) public {
        grantRole(WHITELIST_ROLE, beneficiary);
    }

    function removeFromWhiteList(address beneficiary) public {
        revokeRole(WHITELIST_ROLE, beneficiary);
    }

    function isWhitelisted(address beneficiary) public view returns (bool) {
        return hasRole(WHITELIST_ROLE, beneficiary);
    }

    function grantWhiteListerRole(address whitelister) public {
        grantRole(WHITELIST_ADMIN_ROLE, whitelister);
    }

    function revokeWhiteListerRole(address whitelister) public {
        revokeRole(WHITELIST_ADMIN_ROLE, whitelister);
    }

    function isWhiteLister(address whitelister) public view returns (bool) {
        return hasRole(WHITELIST_ADMIN_ROLE, whitelister);
    }
}
