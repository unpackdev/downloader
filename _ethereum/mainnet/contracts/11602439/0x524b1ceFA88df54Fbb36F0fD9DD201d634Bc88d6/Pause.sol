// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./Pausable.sol";

import "./Roles.sol";

abstract contract Pause is Pausable, Roles {
    function pause()
        public
        virtual
        onlySuperAdminOrAdmin
    {
        if (!paused()) {
            _pause();
        }
    }

    function unpause()
        public
        virtual
        onlySuperAdminOrAdmin
    {
        if (paused()) {
            _unpause();
        }
    }
}
