// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Ops Ltd. All rights reserved.
pragma solidity 0.8.17;

import "./IAccessController.sol";
import "./Context.sol";
import "./Errors.sol";

contract SecurityBase {
    IAccessController public immutable accessController;

    error UndefinedAddress();

    constructor(address _accessController) {
        if (_accessController == address(0)) revert UndefinedAddress();

        accessController = IAccessController(_accessController);
    }

    modifier onlyOwner() {
        accessController.verifyOwner(msg.sender);
        _;
    }

    modifier hasRole(bytes32 role) {
        if (!accessController.hasRole(role, msg.sender)) revert Errors.AccessDenied();
        _;
    }

    ///////////////////////////////////////////////////////////////////
    //
    //  Forward all the regular methods to central security module
    //
    ///////////////////////////////////////////////////////////////////

    function _hasRole(bytes32 role, address account) internal view returns (bool) {
        return accessController.hasRole(role, account);
    }

    // NOTE: left commented forward methods in here for potential future use
    //     function _getRoleAdmin(bytes32 role) internal view returns (bytes32) {
    //         return accessController.getRoleAdmin(role);
    //     }
    //
    //     function _grantRole(bytes32 role, address account) internal {
    //         accessController.grantRole(role, account);
    //     }
    //
    //     function _revokeRole(bytes32 role, address account) internal {
    //         accessController.revokeRole(role, account);
    //     }
    //
    //     function _renounceRole(bytes32 role, address account) internal {
    //         accessController.renounceRole(role, account);
    //     }
}
