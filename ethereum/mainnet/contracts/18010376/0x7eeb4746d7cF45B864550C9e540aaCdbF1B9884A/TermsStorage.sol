// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./Counters.sol";

library TermsStorage {
    using Counters for Counters.Counter;

    bytes32 internal constant STORAGE_SLOT = keccak256("keepers.contracts.storage.terms");

    struct Layout {
        mapping(uint256 => string) termsParts; // mapping of term part number to term part string
        Counters.Counter termsVersion;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
