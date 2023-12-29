// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

library LicenseStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("keepers.contracts.storage.license");

    struct Layout {
        mapping(uint256 => bool) licenseRevoked; // tracks whether a token has its license revoked
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
