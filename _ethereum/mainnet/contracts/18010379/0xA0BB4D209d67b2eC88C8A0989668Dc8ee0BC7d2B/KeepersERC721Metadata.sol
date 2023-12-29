// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
import "./Strings.sol";

import "./ERC721Metadata.sol";
import "./ERC721MetadataStorage.sol";
import "./KeepersAvatarAssignmentStorage.sol";
import "./RoomNamingStorage.sol";
import "./ConstantsLib.sol";
import "./ConfigLib.sol";

contract KeepersERC721Metadata is ERC721Metadata {
    string public constant STANDARD_TICKET_PATH = "standardTicket"; // Need the right URI
    string public constant SPECIAL_TICKET_PATH = "specialTicket"; // Need the right URI

    string constant jsonPart1 = '{ "name": "Keeper #';
    string constant jsonPart2 = '", "image": "';
    string constant jsonPart3 = '.png", "animation_url": "';
    string constant jsonPart4 = '.mp4", "attributes": ';
    string constant jsonPart5 = "]}";
    string constant slash = "/";
    string constant closingBracket = '"}';
    string constant dotPng = ".png";

    function _tokenURI(uint256 tokenId) internal view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert("ERC721Metadata: URI query for nonexistent token");
        }

        KeepersAvatarAssignmentStorage.Layout storage l = KeepersAvatarAssignmentStorage.layout();
        uint8 convertedState = l.tokenConvertedToAvatar[tokenId];

        RoomNamingStorage.Layout storage r = RoomNamingStorage.layout();

        ERC721MetadataStorage.Layout storage k = ERC721MetadataStorage.layout();

        if (convertedState == ConstantsLib.TOKEN_STATE_UNCONVERTED) {
            if (r.tokenIdToRoomRights[tokenId] != 0) {
                bytes memory specialTicketData = abi.encodePacked(
                    jsonPart1,
                    Strings.toString(tokenId),
                    jsonPart2,
                    k.baseURI,
                    SPECIAL_TICKET_PATH,
                    dotPng,
                    closingBracket
                );
                return string(abi.encodePacked("data:application/json,", specialTicketData));
            } else {
                bytes memory standardTicketData = abi.encodePacked(
                    jsonPart1,
                    Strings.toString(tokenId),
                    jsonPart2,
                    k.baseURI,
                    STANDARD_TICKET_PATH,
                    dotPng,
                    closingBracket
                );
                return string(abi.encodePacked("data:application/json,", standardTicketData));
            }
        }

        uint256 bitmapConfig = l.configForToken[tokenId];
        uint256[] memory traitIds = ConfigLib.getTraitIdsFromConfig(bitmapConfig);
        bytes memory attributesJson = _renderAttributeJson(traitIds);
        string memory tokenIdStr = Strings.toString(tokenId);
        bytes memory attributesJsonStr = abi.encodePacked(attributesJson);

        // have to split into two parts to avoid stack too deep error
        bytes memory firstPart = abi.encodePacked(
            jsonPart1,
            tokenIdStr,
            jsonPart2,
            k.baseURI,
            tokenIdStr,
            slash,
            tokenIdStr,
            jsonPart3
        );

        bytes memory secondPart = abi.encodePacked(
            k.baseURI,
            tokenIdStr,
            slash,
            tokenIdStr,
            jsonPart4,
            attributesJsonStr,
            jsonPart5
        );

        bytes memory avatarData = abi.encodePacked(firstPart, secondPart);
        return string(abi.encodePacked("data:application/json,", avatarData));
    }

    function _renderAttributeJson(uint256[] memory traitIds) internal view returns (bytes memory attributesJson) {
        KeepersAvatarAssignmentStorage.Layout storage l = KeepersAvatarAssignmentStorage.layout();
        attributesJson = "[";
        uint256 traitIdsLength = traitIds.length;
        for (uint256 i; i < traitIdsLength; ) {
            KeepersAvatarAssignmentStorage.Trait memory trait = l.traits[traitIds[i]];
            attributesJson = abi.encodePacked(
                attributesJson,
                i != 0 ? "," : "",
                "{",
                '"trait_type": "',
                ConfigLib.getCategoryName(trait.categoryId),
                '", "value": "',
                trait.name,
                '"}'
            );
            unchecked {
                ++i;
            }
        }
        return attributesJson;
    }

    function baseURI() external view returns (string memory) {
        return ERC721MetadataStorage.layout().baseURI;
    }
}
