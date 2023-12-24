// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ConstantsLib.sol";
uint8 constant MAX_TRAITS_PER_AVATAR = 12;
uint8 constant TOTAL_ATTRIBITES = 7;

/**
 * @notice Enumeration of the Category options
 */
enum Category {
    Body,
    Head,
    Upper,
    Lower,
    Shoes,
    Suit,
    Accessory
}

/**
 * @notice Utility library to work with `Configs`
 * @dev A `Config` is a 256 bit integer which packs in bits that represent
 * the traits of an avatar. The traits are packed like so
 * 000[Category][TraitId][Category][TraitId]...[Category][TraitId]
 * Where each category uses 4 bits and each trait uses 8 bits
 */
library ConfigLib {
    function configToTraitBitmap(uint256 config) internal pure returns (uint256 traitBitmap) {
        while (config != ConstantsLib.EMPTY_BITMAP) {
            uint256 traitId = config & 0xff;
            traitBitmap |= (1 << (255 - traitId));
            config >>= 12;
        }
    }

    function getTraitIdsFromConfig(uint256 config) internal pure returns (uint256[] memory traitIds) {
        uint256 numTraits = numTraitsInConfig(config);
        traitIds = new uint256[](numTraits);
        uint256 i;
        while (config != ConstantsLib.EMPTY_BITMAP) {
            uint256 traitId = config & 0xFF;
            traitIds[i] = traitId;
            config = config >> 12;

            unchecked {
                i++;
            }
        }
    }

    function numTraitsInConfig(uint256 config) internal pure returns (uint256) {
        uint256 numTraits;
        while (config != ConstantsLib.EMPTY_BITMAP) {
            config = config >> 12;
            unchecked {
                numTraits++;
            }
        }
        return numTraits;
    }

    function getCategoryName(uint64 categoryId) internal pure returns (string memory) {
        if (categoryId == uint64(Category.Body)) return "Body";
        else if (categoryId == uint64(Category.Head)) return "Head";
        else if (categoryId == uint64(Category.Upper)) return "Upper";
        else if (categoryId == uint64(Category.Lower)) return "Lower";
        else if (categoryId == uint64(Category.Shoes)) return "Shoes";
        else if (categoryId == uint64(Category.Suit)) return "Suit";
        else return "Accessory";
    }

    function maxNumTraitsForCategory(uint256 category) internal pure returns (uint8) {
        if (category == uint256(Category.Upper)) return 2;
        else if (category == uint256(Category.Lower)) return 2;
        else if (category == uint256(Category.Suit)) return 3;
        else if (category == uint256(Category.Accessory)) return 4;
        else return 1;
    }

    /*//////////////////////////////////////////////////////////////
                    Bitwise helper functions
    //////////////////////////////////////////////////////////////*/

    // handles packing a trait into the config at the end
    function pushCategoryAndTraitToConfig(
        uint256 config,
        uint256 categoryId,
        uint256 traitId
    ) internal pure returns (uint256) {
        // pack in the category id first
        config <<= 4;
        config |= categoryId;

        // then pack in the trait id
        config <<= 8;
        config |= traitId;

        return config;
    }

    // handles removing the last trait from the config
    function popCategoryAndTraitFromConfig(
        uint256 config
    ) internal pure returns (uint256 categoryId, uint256 traitId, uint256) {
        traitId = config & 0xFF;
        config >>= 8;
        categoryId = config & 0xF;
        config >>= 4;
        return (categoryId, traitId, config);
    }

    /**
     * @param config The config to peek the trait id from
     * @return The trait id of the last trait in the config
     */
    function peekTraitIdFromConfig(uint256 config) internal pure returns (uint256) {
        return config & 0xFF;
    }

    /**
     * @param bitmap The bitmap to check
     * @param index The bit index to check if set (left to right)
     */
    function isBitSet(uint256 bitmap, uint256 index) internal pure returns (bool) {
        return ((bitmap >> (255 - index)) & 1) == 1;
    }

    function removeLastCategoryAndTraitFromConfig(uint256 config) internal pure returns (uint256) {
        return config >> 12;
    }
}
