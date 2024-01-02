pragma solidity ^0.8.17;

import "./Strings.sol";
import "./Ownable.sol";
import "./Base64.sol";
import "./ChoreoLibraryConfig.sol";

contract ChoreoLibrary is Ownable, ChoreoLibraryConfig {
    using Strings for uint16;

    mapping(uint8 => MovementStruct) public movements;
    mapping(AttributesEnum => TextOverlay) public attributes;
    mapping(AttributeValuesEnum => mapping(uint8 => TextOverlay))
        public attributeValues;

    function setMovementWidth(uint8 movement, uint16 width) external onlyOwner {
        movements[movement].width = width;
    }

    function loadMovement(
        uint8 movement,
        uint16 width,
        bytes calldata svg
    ) external onlyOwner {
        movements[movement].svg = svg;
        movements[movement].width = width;
    }

    function setAttributeSize(
        AttributesEnum attr,
        uint16 width,
        uint16 height
    ) external onlyOwner {
        attributes[attr].width = width;
        attributes[attr].height = height;
    }

    function loadattributes(
        AttributesEnum attr,
        uint16 height,
        uint16 width,
        bytes calldata svg
    ) external onlyOwner {
        attributes[attr] = TextOverlay({
            svg: svg,
            width: width,
            height: height
        });
    }

    function setAttributeValueSize(
        AttributeValuesEnum attr,
        uint8 valueId,
        uint16 width,
        uint16 height
    ) external onlyOwner {
        attributeValues[attr][valueId].width = width;
        attributeValues[attr][valueId].height = height;
    }

    function loadattributeValues(
        AttributeValuesEnum attr,
        uint16 height,
        uint16 width,
        uint8[] calldata valueIds,
        bytes[] calldata svgs
    ) external onlyOwner {
        // require arrays are same length
        require(valueIds.length == svgs.length, "Arrays must be same length");
        uint16 svgsLength = uint16(svgs.length);
        for (uint16 i = 0; i < svgsLength; i++) {
            attributeValues[attr][valueIds[i]] = TextOverlay({
                svg: svgs[i],
                width: width,
                height: height
            });
        }
    }
}
