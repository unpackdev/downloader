// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SafeMath.sol";
import "./Strings.sol";
import "./base64.sol";
import "./Ownable.sol";

/// @title Graveyard NFT Project's data contract
/// @author @0xyamyam
/// @notice This contract is intended for use only with the main Graveyard contract
contract CryptData is Ownable(5, true, true) {
    using SafeMath for uint256;
    using Strings for uint256;

    struct Attribute {
        string label;
        string value;
        string svgPaths;
    }

    /// Token attribute storage, generated post mint by the developer
    mapping(uint256 => uint256) public _seeds;

    /// Image layers for token attributes
    string[20] public _svgPaths;

    /// dApp url for tokens
    string public _tokenUrl = "https://graveyardnft.com/#/crypts/";

    /// Generate seed data for all tokens.
    /// The burden to generate randomness is on the developer, not the minter.
    /// This performs 2 functions:
    /// 1. As its sudo randomness, during a normal mint it could be gamed, however being done post mint prevents a
    /// miners incentive to replay the transaction until it has a favourable outcome.
    /// 2. The gas usage burden is taken off the minter and given to the developer,
    /// which reduces mint costs while maintaining on-chain attributes.
    constructor() {
        for (uint256 i = 0;i <= 96;i++) {
            _seeds[i] = uint256(keccak256(abi.encodePacked(block.difficulty, blockhash(block.number -1), block.timestamp, i, msg.sender)));
        }
    }

    /// Upload image paths for each attribute.
    /// @dev remember index 10-14 is used twice as reflected paths for east/west
    /// @param index The attribute index the layers are for
    /// @param paths The paths per attribute
    function uploadSvgPaths(uint256 index, string calldata paths) external onlyOwner {
        _svgPaths[index] = paths;
    }

    /// Update token url.
    /// @param tokenUrl The token url, must end in a slash which will be followed by the tokenId
    function setTokenUrl(string calldata tokenUrl) external onlyOwner {
        _tokenUrl = tokenUrl;
    }

    /// Returns an ERC721 tokenURI.
    /// @param tokenId The tokenId to return metadata for
    /// @return The token metadata as a base64 encoded dataURI according to the ERC721 specification
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        Attribute[5] memory attributes = tokenAttributes(tokenId);
        return encode("application/json", abi.encodePacked('{',
            '"name": "CRYPT #', tokenId.toString(), '",',
            '"description": "The last resting place of failed NFT\'s.",',
            '"attributes": ', attributesToJson(tokenId, attributes),',',
            '"image": "', attributesToImageURI(tokenId, attributes), '",',
            '"external_link": "', _tokenUrl, tokenId.toString(), '",',
            '"external_url": "', _tokenUrl, tokenId.toString(), '"',
        '}'));
    }

    /// Returns the reward rate with a base of 10 + multiplier of spookyNess.
    /// @param tokenId The token id to calculate rewards for
    function getRewardRate(uint256 tokenId) external view returns (uint256) {
        return 10 * 1e18 + (getSpookiness(tokenId) * 1e18 / 10);
    }

    /// Returns the attribute data for a given tokenId using the generated seeds
    /// @param tokenId The tokenId to query attributes for
    /// @return attributes Attribute[5]
    /// @notice Attributes will always be filled with 0 index if seeds have yet to be generated, you should not rely
    /// on this method to distinguish pre/post seed generation.
    function tokenAttributes(uint256 tokenId) internal view returns (Attribute[5] memory attributes) {
        string[5] memory attributeLabels = ["Sky", "Crypt", "West", "East", "Item"];
        string[5][5] memory attributeValues = [
            ["Foggy", "Crescent Moon", "Full Moon", "Lightning", "Rainbow"],
            ["Mithraeum", "Roman", "Medieval", "Gothic", "Pyramid"],
            ["Headstone", "Tombstone", "Cross", "Skull Tombstone", "Tomb"],
            ["Headstone", "Tombstone", "Cross", "Skull Tombstone", "Tomb"],
            ["None", "Candle", "Lantern", "Skull", "Scythe"]
        ];

        tokenId--;
        uint256 seedIndex = tokenId / 70;
        uint256 seed = _seeds[seedIndex];
        uint256 offset = tokenId - (seedIndex * 70);
        uint8[19] memory weights = [0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 4];
        for (uint256 i = 0;i < attributes.length;i++) {
            /// `((seed / 10 ** offset) % 10);` gives us the integer at offset from the seed.
            /// `offset + 1` gives us the next in sequence so we have a number between 0-18,
            /// which is used to pick an attribute index from a weighted list.
            uint256 weight = ((seed / 10 ** offset) % 10) + ((seed / 10 ** (offset + 1)) % 10);
            uint256 index = weights[weight];
            /// West and East are the same just reflected, so we dont store the paths twice, just apply a reflect
            /// transform in the svg.
            uint256 svgIndex = i > 2 ? (i * 5 + index) - 5 : i * 5 + index;
            string memory svgPath = string(abi.encodePacked('<g id="attribute-', i.toString(), '"', i == 2 ? ' transform="translate(1000, 0) scale(-1,1)"' : "", ">", _svgPaths[svgIndex], "</g>"));
            attributes[i] = Attribute(attributeLabels[i], attributeValues[i][index], svgPath);
            offset++;
        }

        return attributes;
    }

    /// Return the collective spookiness values for a token.
    /// @param tokenId The token to get the spookyNess for
    function getSpookiness(uint256 tokenId) internal view returns (uint256) {
        uint256 id = tokenId - 1;
        uint256 seedIndex = id / 70;
        uint256 seed = _seeds[seedIndex];
        uint256 offset = id - (seedIndex * 70);
        uint256 spookiness = 0;
        for (uint256 i = 0;i < 5;i++) {
            spookiness += ((seed / 10 ** offset) % 10) + ((seed / 10 ** (offset + 1)) % 10) + 1;
            offset++;
        }
        return spookiness;
    }

    /// Simple wrapper to abstract any data URI encoding
    /// @param mimeType The mime type for the content
    /// @param source The original source content
    /// @return The complete data uri
    function encode(string memory mimeType, bytes memory source) internal pure returns (string memory) {
        return string(abi.encodePacked("data:", mimeType, ";base64,", Base64.encode(source)));
    }

    /// @param attributes Attribute[5] Token attributes
    /// @return Json string of array attributes, or empty array when seeds aren't generated
    function attributesToJson(uint256 tokenId, Attribute[5] memory attributes) internal view returns (string memory) {
        bytes memory json;
        for (uint256 i = 0;i < attributes.length;i++) {
            json = bytes.concat(json, '{"trait_type": "', bytes(attributes[i].label), '", "value": "', bytes(attributes[i].value), '"},');
        }
        return string(bytes.concat("[", json, '{"trait_type": "Spookiness", "value": ', bytes(getSpookiness(tokenId).toString()), '}', "]"));
    }

    /// @param attributes Attribute[5] Token attributes
    /// @return the image generated from token attributes, or unrevealed image when seeds aren't generated
    function attributesToImageURI(uint256 tokenId, Attribute[5] memory attributes) internal view returns (string memory) {
        uint256 spookiness = getSpookiness(tokenId);
        (bool success, uint256 hue) = SafeMath.trySub(spookiness, 5);
        hue = hue * 4;
        bytes memory paths = "";
        for (uint256 i = 0;i < attributes.length;i++) {
            paths = bytes.concat(paths, bytes(attributes[i].svgPaths));
            if (i == 0) { /// Add foreground after sky attribute
                paths = bytes.concat(paths, bytes('<g id="ground" style="filter: hue-rotate('), bytes(hue.toString()), bytes('deg)"><path fill="#0091d4" d="M9 472c-2 3-4 14-9 24v386h1000V526l-7-1 7-12-12 5-7-19 4 18-12-7 3 10-19-2a940 940 0 0 1-2 0h-2l4-18-6 18-5-1-14-9v-5l-22 9-14-25 12 26-9 3 5-8-7 5-23-11v6l-9-10 2 7-16 3 3-14-4 3 2-12-3 13-6 4-2-3-6-14 2 9-7-9 7 16-10-4 3 10-22 3 3-19-6 19-4 1-14-6v-6l-22 14-16-21 14 23-9 5 4-9-6 6-23-5v5l-20-7 8 12-7 3-4-2c1-8-2-20-2-20l-2 21-18-19 7 12-7 6-9-2c-3-3-4-8-5-9a11 11 0 0 0 2 9l-3-1 3 10-18 5a649 649 0 0 1-2 0l-2 1 3-20-5 21-4 1-7-2-2-8-4 5c-3-7-6-17-8-19l5 15v1l-7-12 6 12-5 5h-1l2-12-12 9-1-5-17 10-26-13 2 5-9 7-21 1v-10l-9 7-6-3 1-13-12 23 1 2-5-1 2-12-11 12-2-5-13 11-6-3 5 6-27-9 2 5-8 9-20 5v-10l-6 6 1-15-5 18-11-7 8 14-11 1-1-6-3 11-2-5-12 15h-2l1-6-6 9-3-17c0 3-3 4-2 13l-2 4-8-1 2-4-12 6v-4l-14 5-1 2-5-3 8-14-9 13h-1l3-16-5 15-10-6v4l-9 9-12 2 4-6-11 6 2-6h-6l1-14-3 13-16 2-1-1-4-7 10-13-11 11-1-1 14-28-16 25-11-19-2 7-14 2-3-2 1-23-3 22-18-10 5-10-11 1 9-17-12 17-4-7 9-13-23 19v-23l-1 22-4-2v3l-8-11 3-7-10 8 2-7-22 3-5-6 1 10-5-7a1277 1277 0 0 1-2-2l-15-19-2 7-14 4-4-1v-22l-2 22-1-1-5-19 3 19-16-5 6-11-10 3 10-17-9 9 5-9-10 15-2 2-8-9v15l-8-2 8-11-14 7 4-7-21 10 1-6-23 9-2-3 5-5-11 8-1-1Zm-15 12"/><path fill="#003a71" d="m211 636-46-5 6-56s3-23 26-21 21 26 21 26Zm789 10h-31v-59s0-24 25-24a31 31 0 0 1 6 0Zm-240 6-1-10-18 2-1-16-10 1 1 16-18 1 1 10 18-1 4 43 10-1-4-43 18-2z"/><path fill="#0d1856" d="m843 668-33 6-7-40s-3-16 13-19 20 13 20 13ZM120 564l-2-15-28 3-3-23-15 1 3 24-27 4 2 15 27-4 9 67 15-2-9-67 28-3zm799 22-2-10-18 3-2-16-9 1 2 16-18 2 1 10 18-2 5 43 10-1-5-44 18-2zM30 610l-12-1 2-10-7-1-1 10-12-1-1 6 12 2-3 28 6 1 4-29 11 2 1-7z"/><path fill="#005d9d" d="m15 635 4-18-7 19-12-5 7 12-7 1v356h1000V614l-17-18 16 27-11-7 5 5-2 3-23-9 1 6-21-10 4 7-13-7 8 11-9 2v-15l-8 9-2-2-10-15 5 9-9-9 10 17-9-3 5 11-16 5 3-19-5 19-1 1-2-22v22l-4 1-14-4-2-7-12 16-15-27 13 29-8 10 1-10-4 6-22-3 1 7-10-8 4 7-10-4 7 12-6 3v-3l-4 2-1-22v23l-5-27 3 26-21-18 9 13-4 7-12-17 9 17h-5l-10-8 7 7h-3l6 10-18 10-4-22 2 23-4 2-13-2-3-7-13 23-20-19 18 21-4 7-1 1-5-2h-10l-4-13 1 14h-6l2 6-11-6 4 6-12-2-8-9v-4l-14 7-8-13 7 14-5 3 3-5-4 3-14-5v4l-5-6 1 4-8-4 2 4h-3l2-8-3 8-4 1-6-8-1 8-7-2-12-16-2 5-9-15v11l-6-2 6-11-9 4-4-19v16l-5-6-1 10-20-5-7-9 1-5-27 9 5-6-5 3-14-11-1 5-11-12 1 12-5 1 2-3h-4l-9-22 1 13-6 3-9-7v9h-21l-8-7 1-5-26 13h-1l-16-10-1 5-5-8v6l-7-7 2 11-7-5-3 4-3-5-3 8-7 1-8-2-9-17 7 17-18-6 3-9-3 1 6-7c-2 0-5 4-9 7l-6 1 5-15c-2 1-5 9-8 16l-7-6 7-13-19 19-2-23 1 24-7-2 1 2-6-2 7-12-13 6 3-7-10 8v-5l-23 5-6-5 4 8-9-5 14-23-16 21h-1l7-27-9 25-19-12v6l-14 6-4-1c-2-7-4-17-6-19l3 19h-1l-10-16 8 15-19-2 3-10-10 4 7-16-7 9 3-9-7 14-2 3-6-4-2-13 1 12-4-3 4 14-10-1 6-11-13 9 2-7-9 10v-6l-25 12-9-1 13-26c-3 3-12 19-15 25l-1-1 5-28-8 27-18-7v5l-14 9-5 1-6-18 4 18h-1l-11-14 8 14-18 2 2-10Zm991-33"/></g>'));
            }
        }
        string memory invert = spookiness >= 85 ? "1" : "0";
        return encode("image/svg+xml", abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="100%" height="100%" version="1.1" viewBox="0 0 1000 1000" style="filter: invert(', invert, ')">',
            '<rect id="background" width="100%" height="100%" fill="#011628"/>',
            paths,
            '<g id="front"><path fill="#0e0543" d="m0 923 12-2 21-17h110l12 13 33 9 11 12 131 30 8 15 31 17H0v-77z"/><path fill="#001b55" d="m369 1000-32-17s-42 10-115 12l22 5Z"/><path fill="#00486d" d="M202 994s-7 11-72 2c0 0 32-17 72-2ZM157 977s-10 15-99 4c0 0 44-24 99-4Z"/><path fill="#001b55" d="m61 1000-37-5-4 5h41zM0 962v27l23 2 3-32-26 3z"/><path fill="#00486d" d="m219 970 111-2s-76-29-131-30l-39 16ZM153 954l-75 8-18-8-52-5s111-14 145 5ZM188 926l-24 3-19 9-82-3s74-4 92-18ZM143 904s-74 22-110 0c0 0 79-19 110 0ZM0 931l53 2s-43-4-41-12l-12 2Z"/><path fill="#0e0543" d="M1000 1000H873v-23l38-5 18-16h71v44z"/><path fill="#00486d" d="M1000 1000h-47l-46-4s53-7 93-4ZM1000 962c-22 4-52 6-71-6 0 0 40-9 71-7ZM947 982s-37-3-36-10l-38 5v9h23Z"/></g>',
            '</svg>'
        ));
    }
}
