// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

library AllowlistStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("keepers.contracts.storage.allowlist");

    struct Layout {
        mapping(address => bool) allowlist;
        mapping(uint256 => uint256) allowlistMintTimestamps;
        // tightly packed into one slot
        bool isAllowlistEnabled;
        uint248 transferRestrictionDuration;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
