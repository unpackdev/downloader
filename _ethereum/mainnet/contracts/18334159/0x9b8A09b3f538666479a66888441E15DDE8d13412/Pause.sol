/*
 * Capital DEX
 *
 * Copyright ©️ 2023 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2023 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Pausable.sol";
import "./AccessControl.sol";

interface IPause {
    function setFullPause(bool pause) external;
    function isPaused() external view returns(bool);
}

contract Pause is IPause, Pausable, AccessControl {
    bytes32 public immutable pauseManagerRole;

    constructor(address admin, bytes32 managerRole) {
        pauseManagerRole = managerRole;
        AccessControl._grantRole(AccessControl.DEFAULT_ADMIN_ROLE, admin);
    }

    function setFullPause(bool pause) public virtual AccessControl.onlyRole(pauseManagerRole) {
        if(pause) {
            Pausable._pause();
        } else {
            Pausable._unpause();
        }
    }

    function isPaused() external view returns(bool) {
        return Pausable.paused();
    }
}
