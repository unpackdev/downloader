// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

library ChonkySpecialStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("chonky.contracts.storage.ChonkySpecial");

    struct Layout {
        address implementation;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
