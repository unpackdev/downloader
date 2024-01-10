// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ScumbugsValues.sol";
import "./DateTime.sol";

/**
 * @title Scumbugs Metadata storage
 * @notice Stores the metadata on-chain.
 */
contract ScumbugsMetadata {

    // ---------------------- Structs ----------------------
    struct Attributes {
        uint8 hand;
        uint8 body;
        uint8 eyes;
        uint8 head;
        uint8 mouth;
        uint8 background_color;
        uint8 bug_type;
        uint32 birthday;
    }

    struct MetadataInput {
        uint256 tokenId;
        bytes32 txHash;
        bytes32 mediaId1;
        bytes32 mediaId2;
        bytes32 mediaBdayId1;
        bytes32 mediaBdayId2;
        // 11 bytes
        uint8 hand;
        uint8 body;
        uint8 eyes;
        uint8 head;
        uint8 mouth;
        uint8 background_color;
        uint8 bug_type;
        uint32 birthday;
    }

    mapping (uint256 => Attributes) internal attributesMap;
    mapping (uint256 => bytes32) public txhashes;
    mapping (uint256 => bytes32) internal mediaIds1;
    mapping (uint256 => bytes32) internal mediaIds2;
    mapping (uint256 => bytes32) internal mediaBdayIds1;
    mapping (uint256 => bytes32) internal mediaBdayIds2;
    bytes32 private defaultImagePart1 = bytes32("U95dUPeExh0CVYAH0ga8jOuifsPD6FsF");
    bytes32 private defaultImagePart2 = bytes32("6aGK2oGauo8");
    
    bytes32 internal siteUrl;
    address public ScumbugsValuesAddress;
    address private DateTimeAddress;
    

    // ---------------------- Constructor ----------------------

    /**
     * @notice Constructor. Sets networkPath and siteUrl.
     * @param _siteUrl The value given to siteUrl
     * @param _ScumbugsValuesAddress The address of the Scumbug Values
     */
    constructor(bytes32 _siteUrl, address _ScumbugsValuesAddress, address _DateTimeAddress) {
        siteUrl = _siteUrl;
        ScumbugsValuesAddress = _ScumbugsValuesAddress;
        DateTimeAddress = _DateTimeAddress;
    }

    /**
     * @notice Renders json as a string containing metadata for token with tokenId
     */
    function _render(uint256 tokenId) internal view virtual returns (string memory) {
        bool isBirthday = false;
        DateTime dateTimeInstance = DateTime(DateTimeAddress);
        uint8 nowDay = dateTimeInstance.getDay(block.timestamp);
        uint8 nowMonth = dateTimeInstance.getMonth(block.timestamp);
        uint8 bdDay = dateTimeInstance.getDay(attributesMap[tokenId].birthday);
        uint8 bdMonth = dateTimeInstance.getMonth(attributesMap[tokenId].birthday);
        if (nowDay == bdDay && nowMonth == bdMonth) {
            isBirthday = true;
        }
        delete dateTimeInstance;
        delete nowDay;
        delete nowMonth;
        delete bdDay;
        delete bdMonth;
        bool generated = isGenerated(tokenId);
        bytes memory tokenIdBytes = uintToStrBytes(tokenId);
        bytes memory buffer = bytes.concat(bytes28("data:application/json;utf8,{"), bytes8('"name":"'));
        // Name
        buffer = bytes.concat(buffer, bytes9("Scumbug #"), tokenIdBytes, bytes2('",'));
        // Image
        if (!generated) {
            buffer = bytes.concat(buffer, bytes9('"image":"'), bytes5("ar://"), defaultImagePart1);
            buffer = bytes.concat(buffer, defaultImagePart2, bytes2('",'));
        } else if (isBirthday) {
            buffer = bytes.concat(buffer, bytes9('"image":"'), bytes5("ar://"), mediaBdayIds1[tokenId]);
            buffer = bytes.concat(buffer, mediaBdayIds2[tokenId], bytes2('",'));
        } else {
            buffer = bytes.concat(buffer, bytes9('"image":"'), bytes5("ar://"), mediaIds1[tokenId]);
            buffer = bytes.concat(buffer, mediaIds2[tokenId], bytes2('",'));
        }
        // Token Id
        buffer = bytes.concat(buffer, bytes10('"tokenId":'), tokenIdBytes, bytes1(","));
        if (generated) {
            // External URL
            buffer = bytes.concat(buffer, bytes16('"external_url":"'), siteUrl, tokenIdBytes, bytes2('",'));
            // Clean up
            delete tokenIdBytes;
            Attributes memory attributes = attributesMap[tokenId];
            ScumbugsValues scumbugsValuesInstance = ScumbugsValues(ScumbugsValuesAddress);
            // Open attributes
            buffer = bytes.concat(buffer, bytes14('"attributes":['));
            // hand
            if (attributes.hand != 0) {
                bytes32 data = scumbugsValuesInstance.handMap(attributes.hand);
                buffer = bytes.concat(buffer, bytes30('{"trait_type":"hand","value":"'), data, bytes3('"},'));
            }
            // body
            if (attributes.body != 0) {
                bytes32 data = scumbugsValuesInstance.bodyMap(attributes.body);
                buffer = bytes.concat(buffer, bytes30('{"trait_type":"body","value":"'), data, bytes3('"},'));
            }
            // eyes
            if (attributes.eyes != 0) {
                bytes32 data = scumbugsValuesInstance.eyesMap(attributes.eyes);
                buffer = bytes.concat(buffer, bytes30('{"trait_type":"eyes","value":"'), data, bytes3('"},'));
            }
            // head
            if (attributes.head != 0) {
                bytes32 data = scumbugsValuesInstance.headMap(attributes.head);
                buffer = bytes.concat(buffer, bytes30('{"trait_type":"head","value":"'), data, bytes3('"},'));
            }
            // mouth
            if (attributes.mouth != 0) {
                bytes32 data = scumbugsValuesInstance.mouthMap(attributes.mouth);
                buffer = bytes.concat(buffer, bytes31('{"trait_type":"mouth","value":"'), data, bytes3('"},'));
            }
            // Background color
            if (isBirthday) {
                buffer = bytes.concat(buffer, bytes32('{"trait_type":"background_color"'), bytes22(',"value":"Birthday!"},'));
            } else {
                bytes32 backgroundData = scumbugsValuesInstance.backgroundMap(attributes.background_color);
                buffer = bytes.concat(buffer, bytes32('{"trait_type":"background_color"'), bytes10(',"value":"'), backgroundData, bytes3('"},'));
                delete backgroundData;
            }
            // Bug type
            bytes32 bugTypeData = scumbugsValuesInstance.bugTypeMap(attributes.bug_type);
            buffer = bytes.concat(buffer, bytes24('{"trait_type":"bug_type"'), bytes10(',"value":"'), bugTypeData, bytes3('"},'));
            delete bugTypeData;
            delete scumbugsValuesInstance;
            // Birthday
            buffer = bytes.concat(buffer, bytes25('{"trait_type":"birthday",'), bytes22('"display_type":"date",'), bytes8('"value":'), 
                uintToStrBytes(attributes.birthday), bytes1('}'));
            // Close attributes
            delete attributes;
            buffer = bytes.concat(buffer, bytes1("]"));
        } else {
            buffer = bytes.concat(buffer, bytes15('"attributes":[]'));
        }
        // Close json
        buffer = bytes.concat(buffer, bytes1("}"));
        return string(buffer);
    }

    function isGenerated(uint256 tokenId) public view returns (bool) {
        return mediaIds1[tokenId] != 0;
    }

    /**
     * @notice Transforms uint to string bytes. Based on toString(uint256 value) from @openzeppelin/contracts/utils/Strings.sol
     */
    function uintToStrBytes(uint256 value) pure private returns (bytes memory) {
        if (value == 0) {
            return bytes("0");
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return buffer;
    }

}