// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library LibCloner {

    struct ClonerStorage {
        mapping(address => bool) isWhitelisted;
        // key is a hash of ROLE and REFERENCE_CONTRACT_ADDRESS
        mapping(bytes32 => bool) isRoleBasedWhitelisted;
    }

    error ClonerStorage__ReferenceContractAlreadyWhitelisted();
    error ClonerStorage__ReferenceContractMustContainCode();
    error ClonerStorage__ReferenceContractNotWhitelisted();

    /// @dev Storage slot to use for Cloner Facet specific storage
    bytes32 internal constant STORAGE_SLOT = keccak256("adventurehub.storage.Cloner");

    /// @dev Returns if a reference contract is whitelisted
    function _isWhitelisted(address referenceContract) internal view returns (bool) {
        ClonerStorage storage cs = clonerStorage();

        return cs.isWhitelisted[referenceContract];
    }

    /// @dev Returns if a role & reference contract combination is whitelisted
    /// @param hash Hash of the ROLE and REFERENCE_CONTRACT_ADDRESS
    function _isRoleBasedWhitelisted(bytes32 hash) internal view returns (bool) {
        ClonerStorage storage cs = clonerStorage();

        return cs.isRoleBasedWhitelisted[hash];
    }

    /// @dev Whitelists a provided reference contract
    function _whitelistReferenceContract(address referenceContract) internal {
        ClonerStorage storage cs = clonerStorage();

        if(cs.isWhitelisted[referenceContract]) {
            revert ClonerStorage__ReferenceContractAlreadyWhitelisted();
        }

        cs.isWhitelisted[referenceContract] = true;
    }

    /// @dev Whitelists a provided role & reference contract combination
    /// @param hash Hash of the ROLE and REFERENCE_CONTRACT_ADDRESS
    function _whitelistRoleBasedReferenceContract(bytes32 hash) internal {
        ClonerStorage storage cs = clonerStorage();

        if(cs.isRoleBasedWhitelisted[hash]) {
            revert ClonerStorage__ReferenceContractAlreadyWhitelisted();
        }

        cs.isRoleBasedWhitelisted[hash] = true;
    }

    /// @dev Deprecates a whitelisted reference contract
    function _unwhitelistReferenceContract(address referenceContract) internal {
        ClonerStorage storage cs = clonerStorage();

        if(!cs.isWhitelisted[referenceContract]) {
            revert ClonerStorage__ReferenceContractNotWhitelisted();
        }

        cs.isWhitelisted[referenceContract] = false;
    }

    /// @dev Deprecates a whitelisted role & reference contract combination
    /// @param hash Hash of the ROLE and REFERENCE_CONTRACT_ADDRESS
    function _unwhitelistRoleBasedReferenceContract(bytes32 hash) internal {
        ClonerStorage storage cs = clonerStorage();

        if(!cs.isRoleBasedWhitelisted[hash]) {
            revert ClonerStorage__ReferenceContractNotWhitelisted();
        }

        cs.isRoleBasedWhitelisted[hash] = false;
    }

    /// @dev Enforces a reference contract is whitelisted
    function _requireIsWhitelisted(address referenceContract) internal view {
        ClonerStorage storage cs = clonerStorage();

        if (!cs.isWhitelisted[referenceContract]) {
            revert ClonerStorage__ReferenceContractNotWhitelisted();
        }
    }

    /// @dev Enforces a role & reference contract combination is whitelisted
    /// @param hash Hash of the ROLE and REFERENCE_CONTRACT_ADDRESS
    function _requireIsRoleBasedWhitelisted(bytes32 hash) internal view {
        ClonerStorage storage cs = clonerStorage();

        if (!cs.isRoleBasedWhitelisted[hash]) {
            revert ClonerStorage__ReferenceContractNotWhitelisted();
        }
    }

    /// @dev Returns the storage data stored at the `STORAGE_SLOT`
    function clonerStorage() internal pure returns (ClonerStorage storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
