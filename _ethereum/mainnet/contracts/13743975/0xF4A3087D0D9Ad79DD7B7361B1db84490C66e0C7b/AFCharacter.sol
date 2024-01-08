/// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.9;

import "./AFRoles.sol";
import "./ConstantsAF.sol";
import "./IAFCharacter.sol";

// import "./console.sol";

contract AFCharacter is AFRoles, IAFCharacter {
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    string public constant name = "AFCharacter";

    /// Setting attributes that are the same for all characters
    bytes32 private constant ARTIST = "Todd Wahnish";
    bytes32 private constant SERIES = "Season 1/Genesis";
    bytes32 private constant COLLECTION = "Adult Fantasy";

    /// The characters that currently have availability
    /// 25 characters are available at the start of minting
    uint256[] public availableCharacters = [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
        22,
        23,
        24,
        25
    ];

    /// Defines Character attributes
    struct Character {
        string name; /// The character name
        Rarities rarity; /// The rarity of the character
        uint256 scarcity; /// The total number tokens that can be minted of this character
        uint256 supply; /// The total number of times this character has been minted
        bytes32 artist; /// The name of the artist
        bytes32 series; // The name of the series
        bytes32 collection; // The name of the collection
    }

    /// Setting rarity levels
    enum Rarities {
        RARE1,
        RARE2,
        SUPERRARE1,
        SUPERRARE2,
        EPIC1,
        EPIC2,
        LEGENDARY1,
        LEGENDARY2,
        MYTHIC1,
        MYTHIC2
    }

    /// All characters registered in the contract
    mapping(uint256 => Character) public allCharactersEver;

    /// Create all the characters.  This is run once before the start of the sale.
    function makeCharacters(
        string[] memory names,
        int8[] memory rarities,
        uint256[] memory scarcities
    ) external onlyEditor {
        for (uint256 index = 0; index < names.length; index++) {
            Character storage char = allCharactersEver[index + 1];
            char.name = names[index];
            char.rarity = Rarities(rarities[index]);
            char.scarcity = scarcities[index];
            char.supply = 0;
            char.artist = ARTIST;
            char.collection = COLLECTION;
            char.series = SERIES;
        }
    }

    /// Picks a random character ID from the list of characters with availability for minting,
    /// increments character supply,
    /// and decrements available character count
    function takeRandomCharacter(uint256 randomNumber, uint256 totalRemaining)
        external
        onlyContract
        returns (uint256)
    {
        uint256 arrayCount = availableCharacters.length;
        /// Checking to make sure characters are available to mint
        require(arrayCount > 0, ConstantsAF.NO_CHARACTERS);

        uint256 shorterRandomNumber = randomNumber % totalRemaining;
        uint256 characterID = 0;
        for (uint256 index = 0; index < arrayCount; index++) {
            uint256 currentCharacterID = availableCharacters[index];
            uint256 numberOfMintsLeft = allCharactersEver[currentCharacterID]
                .scarcity - allCharactersEver[currentCharacterID].supply;
            if (shorterRandomNumber < numberOfMintsLeft) {
                characterID = currentCharacterID;
                break;
            } else {
                shorterRandomNumber -= numberOfMintsLeft;
            }
        }
        /// Checking to make sure the random character we picked exists
        require(
            bytes(allCharactersEver[characterID].name).length != 0,
            ConstantsAF.INVALID_CHARACTER
        );

        incrementCharacterSupply(characterID);
        delete arrayCount;
        delete shorterRandomNumber;
        return characterID;
    }

    /// Returns the character requested for viewing on marketplaces
    function getCharacter(uint256 characterID)
        external
        view
        returns (Character memory)
    {
        return allCharactersEver[characterID];
    }

    /// Returns character's current supply for use in setting card serial
    function getCharacterSupply(uint256 characterID)
        external
        view
        returns (uint256)
    {
        return allCharactersEver[characterID].supply;
    }

    /// Increments the character's supply during minting
    function incrementCharacterSupply(uint256 characterID) private {
        allCharactersEver[characterID].supply += 1;

        /// Making character unavailable if the character is sold out
        if (
            allCharactersEver[characterID].supply ==
            allCharactersEver[characterID].scarcity
        ) {
            removeCharacterFromAvailableCharacters(characterID);
        }
    }

    /// Removes the character from the available characters array when there are no more available
    function removeCharacterFromAvailableCharacters(uint256 characterID)
        private
    {
        uint256 arrayCount = availableCharacters.length;
        uint256 index = 0;
        /// find index of character to be removed
        for (index; index < arrayCount; index++) {
            if (availableCharacters[index] == characterID) {
                break;
            }
        }
        availableCharacters[index] = availableCharacters[
            availableCharacters.length - 1
        ];
        availableCharacters.pop();
        delete arrayCount;
        delete index;
    }
}
