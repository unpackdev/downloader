pragma solidity >=0.6.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./Ownable.sol";

pragma experimental ABIEncoderV2;

abstract contract CustomMintRename is Ownable, ERC721 {
    event Rename(uint256 indexed tokenID);

    mapping(uint256 => string) private tokenNames;
    mapping(uint256 => bool) private usedFreeRename;
    mapping(string => bool) private nameDictionary;

    // For each J type we have an epoch, incrememnted with every paid rename
    // Token Address => totalEpoch
    mapping(address => uint256) internal J_TYPE_EPOCH;
    // For J ID we have a last claimed epoch, incrememnted with fee claim
    // A j can claim a fee when J_TYPE_EPOCH-J_LAST_CLAIMED_EPOCH > 0
    // TokenID => lastClaimedEpoch
    mapping(uint256 => uint256) internal J_LAST_CLAIMED_EPOCH;
    uint256 internal constant PRECISION_MULTIPLIER = 1e18;

    // sum of ‘n’ natural numbers to 99.
    // 99*(100)/2 = 4950
    //
    uint256 _totalShares = 4950;

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function nameOf(uint256 tokenId) public view returns (string memory) {
        return tokenNames[tokenId];
    }

    function freeRenameAvailable(uint256 tokenId) public view returns (bool) {
        return !usedFreeRename[tokenId];
    }

    function nameAvailable(string memory newName) public view returns (bool) {
        return !nameDictionary[toLower(newName)];
    }

    function _rename(uint256 tokenID, string memory newName) internal {
        // Free up old name
        string storage oldName = tokenNames[tokenID];
        nameDictionary[toLower(oldName)] = false;


        // Add the name to the unique dictionary
        nameDictionary[toLower(newName)] = true;
        // Set the new name
        tokenNames[tokenID] = newName;
        // Used the free rename - can set everytime no state change
        usedFreeRename[tokenID] = true;
        emit Rename(tokenID);
    }

    /**
     * @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
     */
    function validateName(string memory str) public pure returns (bool) {
        uint256 MAX_LENTH = 10;
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > MAX_LENTH) return false; // Cannot be longer than 25 characters
        if (b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            ) return false;

            lastChar = char;
        }

        return true;
    }

    /**
     * @dev Converts the string to lowercase
     */
    function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}
