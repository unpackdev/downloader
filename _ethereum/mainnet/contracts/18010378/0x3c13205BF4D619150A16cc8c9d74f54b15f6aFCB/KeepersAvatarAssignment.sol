// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./OwnableInternal.sol";
import "./MintOperatorModifiers.sol";
import "./KeepersAvatarAssignmentStorage.sol";
import "./RoomNamingStorage.sol";
import "./PseudoRandomLib.sol";
import "./KeepersMintWindowModifiers.sol";
import "./ERC721BaseInternal.sol";
import "./ConstantsLib.sol";
import "./ERC721EnumerableInternal.sol";

import "./ConfigLib.sol";

contract KeepersAvatarAssignment is
    OwnableInternal,
    KeepersMintWindowModifiers,
    ERC721BaseInternal,
    ERC721EnumerableInternal,
    MintOperatorModifiers
{
    /**
     * @notice Thrown if the trait Id does not exist
     */
    error InvalidTraitId(uint256);

    /**
     * @notice Thrown if the ticket has already been converted to an avatar
     */
    error TicketAlreadyConverted(uint256);

    /**
     * @notice Thrown if the config is invalid
     */
    error ConfigInvalid(ConfigValidity reason, uint256 config);

    /**
     * @notice Thrown if ether amount is invalid
     */
    error InvalidEtherAmount(uint256);

    /**
     * @notice Thrown if message sender is not approved to convert the ticket
     */
    error NoConversionRights(address sender, uint256 tokenId);

    /**
     * @notice Thrown if there is a mismatched length
     */
    error MismatchedLengthsForPriceUpdate();

    /**
     * @notice Fired after a user succesfully converts a ticket to an avatar
     */
    event KeeperConfigured(address indexed owner, uint256 indexed tokenId, uint256 config);

    /**
     * @notice Fired when a keeper configuration is skipped
     */
    event KeeperConfigurationSkipped(uint256 indexed tokenId);

    /**
     * @notice emit the number of assignments
     */
    event BulkAssignmentNumAttempts(uint256 indexed numAttempts);

    enum ConfigValidity {
        Valid,
        MismatchedCategoryId,
        IncompatibleOrUnavailable,
        ExceedsMaxNumTraits,
        MissingBody,
        MissingSpecialBody,
        AlreadyTaken,
        InvalidTraitId,
        InvalidSpecialBody
    }

    enum RandomConfigurationResult {
        Success,
        AlreadyTaken,
        InvalidTokenId
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function createTraitsBulk(KeepersAvatarAssignmentStorage.Trait[] memory traits) external onlyOwner {
        KeepersAvatarAssignmentStorage.Layout storage l = KeepersAvatarAssignmentStorage.layout();
        uint256 traitsLength = traits.length;
        for (uint256 i; i < traitsLength; ) {
            uint256 traitId = traits[i].id;
            if (traitId < ConstantsLib.MIN_TRAIT_ID || traitId > ConstantsLib.MAX_TRAIT_ID)
                revert InvalidTraitId(traitId);
            l.traits[traitId] = traits[i];

            // mark the trait supply bitmap
            if (traits[i].remainingSupply > 0) {
                l.traitHasSupplyBitmap |= (1 << (255 - traitId));
            } else {
                l.traitHasSupplyBitmap &= ~(1 << (255 - traitId));
            }

            unchecked {
                i++;
            }
        }
    }

    function setPricesBulk(uint256[] calldata traitIds, uint128[] calldata pricesWei) external onlyOwner {
        if (traitIds.length != pricesWei.length) revert MismatchedLengthsForPriceUpdate();

        KeepersAvatarAssignmentStorage.Layout storage l = KeepersAvatarAssignmentStorage.layout();
        for (uint256 i; i < traitIds.length; ) {
            uint256 traitId = traitIds[i];

            l.traits[traitId].priceWei = pricesWei[i];

            unchecked {
                i++;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        USER FACING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function trait(uint256 traitId) external view returns (KeepersAvatarAssignmentStorage.Trait memory) {
        if (traitId < ConstantsLib.MIN_TRAIT_ID || traitId > ConstantsLib.MAX_TRAIT_ID) revert InvalidTraitId(traitId);
        KeepersAvatarAssignmentStorage.Layout storage l = KeepersAvatarAssignmentStorage.layout();
        return l.traits[traitId];
    }

    function traitHasSupplyBitmap() external view returns (uint256) {
        KeepersAvatarAssignmentStorage.Layout storage l = KeepersAvatarAssignmentStorage.layout();
        return l.traitHasSupplyBitmap;
    }

    // Take a ticket token and convert it to an avatar
    function convertTicketToAvatar(uint256 tokenId, uint256 config) external payable whenMintWindowOpen {
        KeepersAvatarAssignmentStorage.Layout storage l = KeepersAvatarAssignmentStorage.layout();
        RoomNamingStorage.Layout storage r = RoomNamingStorage.layout();
        bool isSpecial = r.tokenIdToRoomRights[tokenId] != 0;

        // validate the price is correct
        if (getPriceForConfig(config) != msg.value) revert InvalidEtherAmount(msg.value);

        // validate the ticket is not already converted
        if (l.tokenConvertedToAvatar[tokenId] != 0) revert TicketAlreadyConverted(tokenId);

        // validate the sender owns the ticket or is approved to act on it
        address owner = _ownerOf(tokenId);
        bool allowed = (owner == msg.sender) ||
            ((_getApproved(tokenId) == msg.sender) || (_isApprovedForAll(owner, msg.sender)));

        if (!allowed) revert NoConversionRights(msg.sender, tokenId);

        // validate the config is not already taken
        uint256 takenTraitsBitmap = ConfigLib.configToTraitBitmap(config);

        if (l.avatarConfigTraitsTaken[takenTraitsBitmap]) {
            revert ConfigInvalid(ConfigValidity.AlreadyTaken, config);
        }

        // validate the config is valid
        ConfigValidity v = getConfigValidity(config, isSpecial);
        if (v != ConfigValidity.Valid) {
            revert ConfigInvalid(v, config);
        }

        // update the availabilities
        decrementTraitAvailabilities(config);

        l.avatarConfigTraitsTaken[takenTraitsBitmap] = true;
        l.configForToken[tokenId] = config;
        l.tokenConvertedToAvatar[tokenId] = 1;

        emit KeeperConfigured(msg.sender, tokenId, config);
    }

    function getPriceForConfig(uint256 config) public view returns (uint256 totalPrice) {
        KeepersAvatarAssignmentStorage.Layout storage l = KeepersAvatarAssignmentStorage.layout();
        while (config != ConstantsLib.EMPTY_BITMAP) {
            uint256 traitId = ConfigLib.peekTraitIdFromConfig(config);
            totalPrice += l.traits[traitId].priceWei;
            config = ConfigLib.removeLastCategoryAndTraitFromConfig(config);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        UTILITY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // gets config validity and availablity
    function getConfigValidityAndAvailability(uint256 config, bool isSpecial) public view returns (ConfigValidity) {
        // validate if already taken
        KeepersAvatarAssignmentStorage.Layout storage l = KeepersAvatarAssignmentStorage.layout();
        uint256 takenTraitsBitmap = ConfigLib.configToTraitBitmap(config);
        if (l.avatarConfigTraitsTaken[takenTraitsBitmap]) {
            return ConfigValidity.AlreadyTaken;
        }

        // validate the config is valid
        ConfigValidity v = getConfigValidity(config, isSpecial);
        if (v != ConfigValidity.Valid) {
            return v;
        }

        // valid config
        return ConfigValidity.Valid;
    }

    // gets config validity but does not check if already taken (for gas savings)
    function getConfigValidity(uint256 config, bool isSpecialTicket) public view returns (ConfigValidity) {
        KeepersAvatarAssignmentStorage.Layout storage l = KeepersAvatarAssignmentStorage.layout();
        uint256 cumulativeValidTraitsBitmap = l.traitHasSupplyBitmap;
        uint256[7] memory categoryCounts;
        uint256 bodyId;

        while (config != ConstantsLib.EMPTY_BITMAP) {
            (uint256 categoryId, uint256 traitId, uint256 nextConfig) = ConfigLib.popCategoryAndTraitFromConfig(config);

            if (traitId < ConstantsLib.MIN_TRAIT_ID || traitId > ConstantsLib.MAX_TRAIT_ID) {
                return ConfigValidity.InvalidTraitId;
            }

            // validate the trait is available and compatible
            if (!ConfigLib.isBitSet(cumulativeValidTraitsBitmap, traitId)) {
                return ConfigValidity.IncompatibleOrUnavailable;
            }

            KeepersAvatarAssignmentStorage.Trait storage traitToCheck = l.traits[traitId];

            // validate the category id matches with the trait
            if (traitToCheck.categoryId != categoryId) {
                return ConfigValidity.MismatchedCategoryId;
            }

            // validate the number of traits for this category is not exceeded
            unchecked {
                categoryCounts[traitToCheck.categoryId]++;
            }
            if (categoryCounts[traitToCheck.categoryId] > ConfigLib.maxNumTraitsForCategory(traitToCheck.categoryId)) {
                return ConfigValidity.ExceedsMaxNumTraits;
            }

            if (traitToCheck.categoryId == uint16(Category.Body)) {
                bodyId = traitId;
            }

            // combine the trait's compatability bitmap with the cumulative bitmap
            cumulativeValidTraitsBitmap &= traitToCheck.compatabilityBitmap;
            config = nextConfig;
        }

        // must have a body
        if (bodyId == 0) {
            return ConfigValidity.MissingBody;
        }

        // special ticket must have glass body
        if (isSpecialTicket && bodyId != ConstantsLib.GLASS_BODY_ID) {
            return ConfigValidity.MissingSpecialBody;
        }

        if (!isSpecialTicket && bodyId == ConstantsLib.GLASS_BODY_ID) {
            return ConfigValidity.InvalidSpecialBody;
        }

        return ConfigValidity.Valid;
    }

    // Get data on which tickets are converted to avatar vs not
    // 0 for unconverted, 1 for user converted, and 2 for admin converted
    // These values were originally necessary as the plan was for the configurator to call in to
    // the contract to determine remaining configs to render assets for.
    // Now it's a fallback in case the queueing system doesn't work or has lapses
    function getTicketStatus(uint256 tokenId) public view returns (uint8) {
        return KeepersAvatarAssignmentStorage.layout().tokenConvertedToAvatar[tokenId];
    }

    function traitNameForId(uint256 traitId) external view returns (string memory) {
        return KeepersAvatarAssignmentStorage.layout().traits[traitId].name;
    }

    function decrementTraitAvailabilities(uint256 config) internal {
        KeepersAvatarAssignmentStorage.Layout storage l = KeepersAvatarAssignmentStorage.layout();
        while (config != ConstantsLib.EMPTY_BITMAP) {
            uint256 traitId = ConfigLib.peekTraitIdFromConfig(config);
            uint256 remaining = --l.traits[traitId].remainingSupply;
            config >>= 12;

            // update the traitsupply bitmap to 0 at the traitId index
            if (remaining == 0) {
                l.traitHasSupplyBitmap &= ~(1 << (255 - traitId));
            }
        }
    }

    function configForToken(uint256 tokenId) external view returns (uint256) {
        return KeepersAvatarAssignmentStorage.layout().configForToken[tokenId];
    }

    function traitsForToken(uint256 tokenId) external view returns (KeepersAvatarAssignmentStorage.Trait[] memory) {
        KeepersAvatarAssignmentStorage.Layout storage l = KeepersAvatarAssignmentStorage.layout();
        uint256 config = l.configForToken[tokenId];

        return traitsForConfig(config);
    }

    function traitsForConfig(uint256 config) public view returns (KeepersAvatarAssignmentStorage.Trait[] memory) {
        KeepersAvatarAssignmentStorage.Layout storage l = KeepersAvatarAssignmentStorage.layout();
        uint256 numTraits = ConfigLib.numTraitsInConfig(config);
        KeepersAvatarAssignmentStorage.Trait[] memory traits = new KeepersAvatarAssignmentStorage.Trait[](numTraits);

        uint256 i;
        while (config != ConstantsLib.EMPTY_BITMAP) {
            uint256 traitId = ConfigLib.peekTraitIdFromConfig(config);
            traits[i] = l.traits[traitId];
            config = ConfigLib.removeLastCategoryAndTraitFromConfig(config);
            unchecked {
                i++;
            }
        }

        return traits;
    }

    /*//////////////////////////////////////////////////////////////
                    FINAL RANDOM ASSIGNMENT BELOW
    //////////////////////////////////////////////////////////////*/

    // appends tokens to an array for random final assignment
    function calculateFinalTokensToConvert(
        uint16 count
    ) external onlyOwnerOrMintOperator whenMintWindowClosed returns (uint256) {
        KeepersAvatarAssignmentStorage.Layout storage l = KeepersAvatarAssignmentStorage.layout();

        uint16 start = l.finalTokensToConvertCounter;

        uint16 end = start + count;
        uint256 totalSupply = _totalSupply();
        if (end > totalSupply) end = uint16(totalSupply);

        for (uint256 i = start; i < end; ) {
            uint16 tokenId = uint16(_tokenByIndex(i));
            uint256 status = getTicketStatus(tokenId);
            if (status == 0) {
                l.finalTokensToConvert.push(tokenId);
            }

            unchecked {
                i++;
            }
        }

        l.finalTokensToConvertCounter = end;

        return end;
    }

    function getFinalTokensToConvert() external view returns (uint16[] memory) {
        KeepersAvatarAssignmentStorage.Layout storage l = KeepersAvatarAssignmentStorage.layout();
        return l.finalTokensToConvert;
    }

    // gets the random token id to convert
    // also removes the token id from the list
    function getRandomTokenIdToConvert(uint256 largeRandNum) internal returns (uint256) {
        KeepersAvatarAssignmentStorage.Layout storage l = KeepersAvatarAssignmentStorage.layout();
        uint256 index = largeRandNum % l.finalTokensToConvert.length;
        uint256 tokenId = l.finalTokensToConvert[index];

        // remove this token from the list by swapping it with
        // the last element, then popping the last element
        l.finalTokensToConvert[index] = l.finalTokensToConvert[l.finalTokensToConvert.length - 1];
        l.finalTokensToConvert.pop();

        return tokenId;
    }

    function getFinalTokensToConvertCount() external view returns (uint256) {
        KeepersAvatarAssignmentStorage.Layout storage l = KeepersAvatarAssignmentStorage.layout();
        return l.finalTokensToConvert.length;
    }

    function bulkAssignRandomAvatarConfigs(uint256 count) external onlyOwnerOrMintOperator whenMintWindowClosed {
        uint256 rand = PseudoRandomLib.getPseudoRandomNumber(count);
        uint256 numAttempts;
        for (uint256 i = 0; i < count; ) {
            uint256 tokenId = getRandomTokenIdToConvert(rand);

            bool finished;
            while (!finished) {
                RandomConfigurationResult result = assignRandomAvatarConfig(rand, tokenId);

                finished = result != RandomConfigurationResult.AlreadyTaken;
                if (result == RandomConfigurationResult.InvalidTokenId) emit KeeperConfigurationSkipped(tokenId);

                rand = PseudoRandomLib.deriveNewRandomNumber(rand);
                numAttempts++;
            }

            unchecked {
                i++;
            }
        }

        emit BulkAssignmentNumAttempts(numAttempts);
    }

    function assignRandomAvatarConfig(uint256 randNum, uint256 tokenId) internal returns (RandomConfigurationResult) {
        KeepersAvatarAssignmentStorage.Layout storage l = KeepersAvatarAssignmentStorage.layout();
        if (!_exists(tokenId) || l.tokenConvertedToAvatar[tokenId] != 0) {
            return RandomConfigurationResult.InvalidTokenId;
        }

        RoomNamingStorage.Layout storage r = RoomNamingStorage.layout();
        bool isSpecial = r.tokenIdToRoomRights[tokenId] != 0;

        uint8 targetNumTraits = getRandomTraitCount(randNum);
        uint256 config = findWeightedRandomAvatarConfig(randNum, isSpecial, targetNumTraits);

        uint256 takenTraitsBitmap = ConfigLib.configToTraitBitmap(config);
        if (l.avatarConfigTraitsTaken[takenTraitsBitmap]) {
            // this config is already taken
            return RandomConfigurationResult.AlreadyTaken;
        }

        // set the config for the token
        l.configForToken[tokenId] = config;

        // mark this unique trait combination as taken
        l.avatarConfigTraitsTaken[takenTraitsBitmap] = true;

        // mark this token as admin converted
        l.tokenConvertedToAvatar[tokenId] = 2;

        // reduce the availabilities
        decrementTraitAvailabilities(config);

        emit KeeperConfigured(msg.sender, tokenId, config);

        return RandomConfigurationResult.Success;
    }

    function findWeightedRandomAvatarConfig(
        uint256 randNum,
        bool isSpecialTicket,
        uint8 targetNumTraits
    ) internal view returns (uint256 config) {
        KeepersAvatarAssignmentStorage.Layout storage l = KeepersAvatarAssignmentStorage.layout();

        // bitmap used to determine which remaining traits are compatible
        uint256 cumulativeValidTraitsBitmap = l.traitHasSupplyBitmap;

        uint256 bodyTraitId = findWeightedRandomBodyTrait(cumulativeValidTraitsBitmap, randNum);
        if (isSpecialTicket) bodyTraitId = ConstantsLib.GLASS_BODY_ID;

        // update the bitmaps and config
        KeepersAvatarAssignmentStorage.Trait storage body = KeepersAvatarAssignmentStorage.layout().traits[bodyTraitId];

        // combine the trait's compatability bitmap with the cumulative bitmap
        cumulativeValidTraitsBitmap &= body.compatabilityBitmap;

        // pack in the attributes
        config = ConfigLib.pushCategoryAndTraitToConfig(config, body.categoryId, bodyTraitId);

        randNum = PseudoRandomLib.deriveNewRandomNumber(randNum);

        // find non-body traits
        for (uint256 i; i < targetNumTraits - 1; ) {
            // use previous rand num to get trait rarity
            uint256 rarityBitmap = getRandomWeightedRarityBitmap(randNum);

            // get a fresh random number
            randNum = PseudoRandomLib.deriveNewRandomNumber(randNum);

            // bitmap which takes into account the remaining compatible traits
            // as well as the weighted random rarity for this trait
            uint256 bitmapToSearch = cumulativeValidTraitsBitmap & rarityBitmap;

            // get a trait id from the bitmap
            uint256 traitId = PseudoRandomLib.findRandomSetBitIndex(bitmapToSearch, randNum, ConstantsLib.MAX_TRAIT_ID);

            // no compatible traits left for given rarity, break
            if (traitId == PseudoRandomLib.SET_BIT_NOT_FOUND) break;

            KeepersAvatarAssignmentStorage.Trait storage nonBodyTrait = KeepersAvatarAssignmentStorage.layout().traits[
                traitId
            ];

            cumulativeValidTraitsBitmap &= nonBodyTrait.compatabilityBitmap;

            // pack in the attributes
            config = ConfigLib.pushCategoryAndTraitToConfig(config, nonBodyTrait.categoryId, traitId);

            unchecked {
                i++;
            }
        }
    }

    function findWeightedRandomBodyTrait(
        uint256 cumulativeValidTraitsBitmap,
        uint256 randSeed
    ) internal pure returns (uint256) {
        uint256 randNum = PseudoRandomLib.deriveNewRandomNumber(randSeed);
        uint256 rarityBitmap = getRandomWeightedRarityBitmap(randNum);
        uint256 bitmapToSearch = PseudoRandomLib.keepBitsLeftOfIndex(
            cumulativeValidTraitsBitmap & rarityBitmap,
            ConstantsLib.MAX_NON_SPECIAL_BODY_ID + 1
        );

        // no traits are available, return the basic black body
        if (bitmapToSearch == ConstantsLib.EMPTY_BITMAP) return ConstantsLib.BLACK_BODY_ID;

        // get a trait id from the bitmap (the first 9 traits are non special bodies)
        return PseudoRandomLib.findRandomSetBitIndex(bitmapToSearch, randNum, ConstantsLib.MAX_NON_SPECIAL_BODY_ID);
    }

    // assigns the number of traits based off the desired distribution
    // the number of traits is determined by a random number between 1 and 1000
    // this should receive a random number with a range >> 1000
    // 0.1% 1 trait
    // 2.4% 2 traits
    // 27% 3 traits
    // 41% 4 traits
    // 27% 5 traits
    // 2.4% 6 traits
    // 0.1% 7 traits
    function getRandomTraitCount(uint256 largeRandNum) internal pure returns (uint8) {
        uint256 randVal = largeRandNum % 1000;

        if (randVal < 1) {
            return 1;
        } else if (randVal < 25) {
            return 2;
        } else if (randVal < 295) {
            return 3;
        } else if (randVal < 705) {
            return 4;
        } else if (randVal < 975) {
            return 5;
        } else if (randVal < 999) {
            return 6;
        } else {
            return 7;
        }
    }

    // bitmaps have 1 for every trait index that is of that rarity
    // the weighted random breakdown is
    // 0.5% ultra rare
    // 1.5% rare
    // 8% uncommon
    // 90% common
    function getRandomWeightedRarityBitmap(uint256 randNum) internal pure returns (uint256) {
        uint256 rand = randNum % 1000;
        if (rand < 5) {
            return ConstantsLib.RARITY_ULTRARARE;
        } else if (rand < 20) {
            return ConstantsLib.RARITY_RARE;
        } else if (rand < 100) {
            return ConstantsLib.RARITY_UNCOMMON;
        } else {
            return ConstantsLib.RARITY_COMMON;
        }
    }

    function getRarityForTrait(uint256 traitId) external pure returns (string memory) {
        if (ConfigLib.isBitSet(ConstantsLib.RARITY_ULTRARARE, traitId)) {
            return "ultrarare";
        } else if (ConfigLib.isBitSet(ConstantsLib.RARITY_RARE, traitId)) {
            return "rare";
        } else if (ConfigLib.isBitSet(ConstantsLib.RARITY_UNCOMMON, traitId)) {
            return "uncommon";
        } else {
            return "common";
        }
    }

    // should be called from off chain
    function getAllTraitsAndAvailabilities() external view returns (KeepersAvatarAssignmentStorage.Trait[] memory) {
        KeepersAvatarAssignmentStorage.Trait[] memory traits = new KeepersAvatarAssignmentStorage.Trait[](
            ConstantsLib.MAX_TRAIT_ID
        );

        for (uint256 i; i < ConstantsLib.MAX_TRAIT_ID; i++) {
            KeepersAvatarAssignmentStorage.Trait memory nextTrait = KeepersAvatarAssignmentStorage.layout().traits[
                i + 1
            ];
            traits[i] = nextTrait;
        }

        return traits;
    }
}
