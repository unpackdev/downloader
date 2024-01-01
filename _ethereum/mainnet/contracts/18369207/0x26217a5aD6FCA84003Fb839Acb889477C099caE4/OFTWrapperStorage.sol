// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

library OFTWrapperStorage {
    struct Layout {
        address feeCollector;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('interport.oft.wrapper.OFTWrapper');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
