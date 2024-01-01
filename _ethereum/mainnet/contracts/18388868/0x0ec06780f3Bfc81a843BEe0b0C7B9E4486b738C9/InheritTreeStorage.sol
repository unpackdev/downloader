// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library InheritTreeStorage {
    struct InheritTreeInfo {
        bytes32[] parents;
        bytes32[] children;
        bytes32[] familyDaos;
        bytes32 ancestor;
        bool isAncestorDao;
    }

    struct Layout {
        mapping(bytes32 daoId => InheritTreeInfo inheritTreeInfo) inheritTreeInfos;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.InheritTreeStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
