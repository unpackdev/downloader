pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

library FlagHelper {
    /// Modifiers

    // either severe slashing or all collateralised SLOT was lost
    function kickMember(uint16 flags) internal pure returns (uint16) {
        return setFlag(flags, 1, true);
    }

    // you don't want to be part of the protocol
    function rageQuit(uint16 flags) internal pure returns (uint16) {
        return setFlag(flags, 2, true);
    }

    /// Public read methods

    function exists(uint16 flags) internal pure returns (bool) {
        return getFlag(flags, 0);
    }

    function isKicked(uint16 flags) internal pure returns (bool) {
        return getFlag(flags, 1);
    }

    function hasRageQuit(uint16 flags) internal pure returns (bool) {
        return getFlag(flags, 2);
    }

    /// Flag helpers

    function setFlag(uint16 flags, uint16 pos, bool value) private pure returns (uint16) {
        require(pos < 16, "position overflow");

        if(getFlag(flags, pos) != value) {
            if(value) {
                return uint16(flags + (2 ** pos));
            } else {
                return uint16(flags - (2 ** pos));
            }
        }

        return flags;
    }

    function getFlag(uint16 flags, uint16 pos) private pure returns (bool) {
        require(pos < 16, "position overflow");
        return (flags >> pos) % 2 == 1;
    }
}
