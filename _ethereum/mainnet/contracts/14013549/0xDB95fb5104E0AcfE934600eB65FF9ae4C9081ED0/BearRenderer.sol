// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./DecimalStrings.sol";
import "./SVG.sol";
import "./BearRendererErrors.sol";
import "./IBearRenderer.sol";
import "./IBearRenderTech.sol";
import "./IBearRenderTechProvider.sol";

/// @title Base IBearRenderer
abstract contract BearRenderer is IBearRenderer {

    using Strings for uint256;

    /// @dev The IBearRenderTechProvider for this IBearRenderer
    IBearRenderTechProvider internal immutable _renderTech;

    /// @dev Constructs a new instance passing in the IBearRenderTechProvider
    constructor(address renderTech) {
        _renderTech = IBearRenderTechProvider(renderTech);
    }

    /// The ear ratio to apply based on the genes and token id
    /// @param geneBytes The Bear's genes as bytes22
    /// @param tokenId The Bear's Token Id
    /// @return ratio The ear ratio as a uint
    function earRatio(bytes22 geneBytes, uint256 tokenId) internal pure returns (uint ratio) {
        ratio = uint8(geneBytes[(tokenId + 21) % 22]);
    }

    /// The eye ratio to apply based on the genes and token id
    /// @param geneBytes The Bear's genes as bytes22
    /// @param tokenId The Bear's Token Id
    /// @return The eye ratio as a uint8
    function eyeRatio(bytes22 geneBytes, uint256 tokenId) internal pure returns (uint8) {
        return uint8(geneBytes[(tokenId + 20) % 22]);
    }

    /// The jowl ratio to apply based on the genes and token id
    /// @param geneBytes The Bear's genes as bytes22
    /// @param tokenId The Bear's Token Id
    /// @return The jowl ratio as a uint8
    function jowlRatio(bytes22 geneBytes, uint256 tokenId) internal pure returns (uint8) {
        return uint8(geneBytes[(tokenId + 19) % 22]);
    }

    /// Prevents a function from executing if not called by the IBearRenderTechProvider
    modifier onlyRenderTech() {
        if (msg.sender != address(_renderTech)) revert OnlyBearRenderTech();
        _;
    }

    function _assignScars(uint surfaceCount, IBear3Traits.ScarColor[] memory scars, bytes22 genes, uint256 tokenId) internal pure returns (IBear3Traits.ScarColor[] memory initializedScars) {
        initializedScars = new IBear3Traits.ScarColor[](surfaceCount);
        uint scarIndex = scars.length;
        for (uint i = 0; i < surfaceCount; i++) {
            if (scarIndex > 0 && scars[0] != IBear3Traits.ScarColor.None) {
                // The further we get, the more likely we assign the next scar (i.e. decrease the divisor)
                uint random = uint8(genes[(tokenId+i) % 18]);
                uint remaining = 1 + surfaceCount - i;
                if (random % remaining <= 1) { // Give our modulo a little push with <=
                    initializedScars[i] = scars[--scarIndex];
                    continue;
                }
            }
            initializedScars[i] = IBear3Traits.ScarColor.None;
        }
    }

    function _firstStop(ISVGTypes.Color memory color) internal pure returns (bytes memory) {
        return abi.encodePacked(" stop-color='", SVG.colorAttributeRGBValue(color) , "'");
    }

    function _firstStopPacked(uint24 packedColor) internal pure returns (bytes memory) {
        return _firstStop(SVG.fromPackedColor(packedColor));
    }

    function _lastStop(ISVGTypes.Color memory color) internal pure returns (bytes memory) {
        return abi.encodePacked(" offset='1' stop-color='", SVG.colorAttributeRGBValue(color) , "'");
    }

    function _lastStopPacked(uint24 packedColor) internal pure returns (bytes memory) {
        return _lastStop(SVG.fromPackedColor(packedColor));
    }

    function _scarColor(IBear3Traits.ScarColor scarColor) internal pure returns (ISVGTypes.Color memory, ISVGTypes.Color memory) {
        if (scarColor == IBear3Traits.ScarColor.Blue) {
            return (SVG.fromPackedColor(0x1795BA), SVG.fromPackedColor(0x9CF3FF));
        } else if (scarColor == IBear3Traits.ScarColor.Magenta) {
            return (SVG.fromPackedColor(0x9D143E), SVG.fromPackedColor(0xDB3F74));
        } else /* if (scarColor == IBear3Traits.ScarColor.Gold) */ {
            return (SVG.fromPackedColor(0xA06E01), SVG.fromPackedColor(0xFFC701));
        }
    }

    function _surfaceGradient(uint id, bytes memory points, uint24 firstStop, uint24 lastStop, IBear3Traits.ScarColor[] memory assignedScars) internal view returns (bytes memory) {
        bytes memory identifier = abi.encodePacked("paint", id.toString());
        if (assignedScars[id] == IBear3Traits.ScarColor.None) {
            return _renderTech.linearGradient(identifier, points, _firstStopPacked(firstStop), _lastStopPacked(lastStop));
        }
        (ISVGTypes.Color memory lower, ISVGTypes.Color memory higher) = _scarColor(assignedScars[id]);
        (ISVGTypes.Color memory first, ISVGTypes.Color memory last) = firstStop < lastStop ? (lower, higher) : (higher, lower);
        return _renderTech.linearGradient(identifier, points, _firstStop(first), _lastStop(last));
    }
}
