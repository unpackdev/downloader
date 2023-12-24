// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

library KeepersAvatarAssignmentStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("keepers.contracts.storage.avatar.assignment");

    struct Trait {
        // the following variables will be
        // tightly packed into 256 bits
        uint32 id; // 1 - 242 (the trait id)
        uint32 categoryId; // 0 - 6 (the category id)
        uint64 remainingSupply; // the supply of the given trait
        uint128 priceWei; // 0 default
        uint256 compatabilityBitmap; // bitmap with other trait indexes which can be used with this trait
        string name;
    }

    struct Layout {
        // mapping of trait id to trait
        mapping(uint256 => Trait) traits;
        // maps tokenId to its corresponding avatar config bitmap [category][traitId]
        mapping(uint256 => uint256) configForToken;
        // 0 for unconverted, 1 for user converted, and 2 for admin converted
        mapping(uint256 => uint8) tokenConvertedToAvatar;
        // maps trait bitmap to whether it has been taken
        // the bitmap marks 1s for each trait index that is taken
        mapping(uint256 => bool) avatarConfigTraitsTaken;
        // maps trait index to whether it has supply left
        uint256 traitHasSupplyBitmap;
        // final tokens to convert to avatar
        uint16[] finalTokensToConvert;
        // final tokens to convert counter
        uint16 finalTokensToConvertCounter;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
