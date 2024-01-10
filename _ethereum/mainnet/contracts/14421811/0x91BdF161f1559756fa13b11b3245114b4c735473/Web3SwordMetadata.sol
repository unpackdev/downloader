// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// [
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0],
// [0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
// [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
// [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
// [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0],
// [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
// [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
// [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
// [0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0],
// [0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0]]
import "./ABDKMath64x64.sol";
import "./Base64.sol";
import "./Strings.sol";

interface IMetadata {
    function tokenMetadata(
        uint256 tokenId,
        uint256 tokenNumber,
        string memory imgURI
    ) external view returns (string memory);

    function name() external view returns (string memory);
}

contract SwordMetadata is IMetadata {
    struct MetadataStructure {
        string name;
        string description;
        string createdBy;
        string image;
        MetadataAttribute[] attributes;
    }

    struct MetadataAttribute {
        bool includeDisplayType;
        bool includeTraitType;
        bool isValueAString;
        string displayType;
        string traitType;
        string value;
    }

    using Base64 for string;
    using Strings for uint256;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function tokenMetadata(
        uint256 tokenId,
        uint256 tokenNumber,
        string memory imgURI
    ) external pure override returns (string memory) {
        string memory base64Json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        _getJson(
                            tokenId,
                            tokenNumber,
                            imgURI
                        )
                    )
                )
            )
        );
        return
            string(
                abi.encodePacked("data:application/json;base64,", base64Json)
            );
    }


    function name() public pure returns (string memory) {
        return "Web3Sword Block";
    }

    function description(uint256 tokenId, uint256 tokenNumber) public pure returns (string memory) {
        return string(abi.encodePacked("ID:", tokenId.toString(), " \\n\\nNo:", tokenNumber.toString(), " \\n\\nweb3sword.com"));
    }

    function _getJson(
        uint256 tokenId,
        uint256 tokenNumber,
        string memory imgURI
    ) private pure returns (string memory) {
        MetadataStructure memory metadata = MetadataStructure({
            name: string(
                abi.encodePacked(
                    name(),
                    "(",
                    tokenNumber.toString(),
                    ") #",
                    tokenId.toString()
                )
            ),
            description: description(tokenId, tokenNumber),
            createdBy: "Web3Art",
            image: imgURI,
            attributes: _getJsonAttributes(
                tokenId,
                tokenNumber
            )
        });

        return _generateMetadata(metadata);
    }

    function _getJsonAttributes(
        uint256,
        uint256 tokenNumber
    ) private pure returns (MetadataAttribute[] memory) {
        MetadataAttribute[]
            memory metadataAttributes = new MetadataAttribute[](1);
        metadataAttributes[0] = _getMetadataAttribute(
            false,
            true,
            false,
            "number",
            "NO.",
            tokenNumber.toString()
        );
        return metadataAttributes;
    }

    function _getMetadataAttribute(
        bool includeDisplayType,
        bool includeTraitType,
        bool isValueAString,
        string memory displayType,
        string memory traitType,
        string memory value
    ) private pure returns (MetadataAttribute memory) {
        MetadataAttribute memory attribute = MetadataAttribute({
            includeDisplayType: includeDisplayType,
            includeTraitType: includeTraitType,
            isValueAString: isValueAString,
            displayType: displayType,
            traitType: traitType,
            value: value
        });

        return attribute;
    }

    function _generateMetadata(MetadataStructure memory metadata)
        private
        pure
        returns (string memory)
    {
        bytes memory byteString;

        byteString = abi.encodePacked(byteString, _openJsonObject());

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("name", metadata.name, true)
        );

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute(
                "description",
                metadata.description,
                true
            )
        );

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute(
                "created_by",
                metadata.createdBy,
                true
            )
        );

        byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute("image", metadata.image, true)
        );

        byteString = abi.encodePacked(
            byteString,
            _pushJsonComplexAttribute(
                "attributes",
                _getAttributes(metadata.attributes),
                false
            )
        );

        byteString = abi.encodePacked(byteString, _closeJsonObject());

        return string(byteString);
    }

    function _getAttributes(MetadataAttribute[] memory attributes)
        private
        pure
        returns (string memory)
    {
        bytes memory byteString;

        byteString = abi.encodePacked(byteString, _openJsonArray());

        for (uint256 i = 0; i < attributes.length; i++) {
            MetadataAttribute memory attribute = attributes[i];
            byteString = abi.encodePacked(
                byteString,
                _pushJsonArrayElement(
                    _getAttribute(attribute),
                    i < (attributes.length - 1)
                )
            );
        }

        byteString = abi.encodePacked(byteString, _closeJsonArray());

        return string(byteString);
    }

    function _getAttribute(MetadataAttribute memory attribute)
        private
        pure
        returns (string memory)
    {
        bytes memory byteString;

        byteString = abi.encodePacked(byteString, _openJsonObject());

        if (attribute.includeDisplayType) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute(
                    "display_type",
                    attribute.displayType,
                    true
                )
            );
        }

        if (attribute.includeTraitType) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute(
                    "trait_type",
                    attribute.traitType,
                    true
                )
            );
        }

        if (attribute.isValueAString) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute(
                    "value",
                    attribute.value,
                    false
                )
            );
        } else {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveNonStringAttribute(
                    "value",
                    attribute.value,
                    false
                )
            );
        }

        byteString = abi.encodePacked(byteString, _closeJsonObject());

        return string(byteString);
    }


    function _checkTag(string storage a, string memory b)
        private
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function _requireOnlyOwner() private view {
        require(msg.sender == owner, "You are not the owner");
    }

    function _openJsonObject() private pure returns (string memory) {
        return string(abi.encodePacked("{"));
    }

    function _closeJsonObject() private pure returns (string memory) {
        return string(abi.encodePacked("}"));
    }

    function _openJsonArray() private pure returns (string memory) {
        return string(abi.encodePacked("["));
    }

    function _closeJsonArray() private pure returns (string memory) {
        return string(abi.encodePacked("]"));
    }

    function _pushJsonPrimitiveStringAttribute(
        string memory key,
        string memory value,
        bool insertComma
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '"',
                    key,
                    '": "',
                    value,
                    '"',
                    insertComma ? "," : ""
                )
            );
    }

    function _pushJsonPrimitiveNonStringAttribute(
        string memory key,
        string memory value,
        bool insertComma
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked('"', key, '": ', value, insertComma ? "," : "")
            );
    }

    function _pushJsonComplexAttribute(
        string memory key,
        string memory value,
        bool insertComma
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked('"', key, '": ', value, insertComma ? "," : "")
            );
    }

    function _pushJsonArrayElement(string memory value, bool insertComma)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(value, insertComma ? "," : ""));
    }
}
