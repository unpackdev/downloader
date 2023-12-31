// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./CoreAccessControl.sol";
import "./CoreStopGuardian.sol";

abstract contract BaseAccessControl is CoreAccessControl, CoreStopGuardian {
    /**
     * @dev
     * Modifiers inherited from CoreAccessControl:
     * onlyDefinitive
     * onlyClients
     * onlyWhitelisted
     * onlyClientAdmin
     * onlyDefinitiveAdmin
     *
     * Modifiers inherited from CoreStopGuardian:
     * stopGuarded
     */

    constructor(CoreAccessControlConfig memory coreAccessControlConfig) CoreAccessControl(coreAccessControlConfig) {}

    /**
     * @dev Inherited from CoreStopGuardian
     */
    function enableStopGuardian() public override onlyAdmins {
        return _enableStopGuardian();
    }

    /**
     * @dev Inherited from CoreStopGuardian
     */
    function disableStopGuardian() public override onlyClientAdmin {
        return _disableStopGuardian();
    }
}
