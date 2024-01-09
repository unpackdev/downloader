// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BearRenderer.sol";

/// @title BrownBearRenderer
contract BrownBearRenderer is BearRenderer {

    using DecimalStrings for uint256;

    // solhint-disable-next-line no-empty-blocks
    constructor(address renderTech) BearRenderer(renderTech) { }

    /// @inheritdoc IBearRenderer
    // solhint-disable-next-line no-unused-vars
    function customDefs(uint176 genes, ISVGTypes.Color memory eyeColor, IBear3Traits.ScarColor[] memory scars, uint256 tokenId) external view onlyRenderTech returns (bytes memory) {
        IBear3Traits.ScarColor[] memory assignedScars = _assignScars(17, scars, bytes22(genes), tokenId);
        bytes memory eyeStartColor = abi.encodePacked(" stop-color='", SVG.colorAttributeRGBValue(eyeColor), "'"); //#6B4D34
        bytes memory results = abi.encodePacked(
            _renderTech.linearGradient("chest", hex'3201f401f4000003e8', _firstStopPacked(0x23160D), _lastStopPacked(0x86644A)),
            _renderTech.linearGradient("neck", hex'3201f401f401f103e8', _firstStopPacked(0x624730), _lastStopPacked(0x816146)),
            _surfaceGradient(0, hex'3201e6033201ed02d6', 0x64462C, 0x362313, assignedScars),
            _surfaceGradient(1, hex'32008d024500d802df', 0x79583C, 0x583C23, assignedScars),
            _surfaceGradient(2, hex'32016a016a001003e8', 0xA67F5E, 0x8D6C4F, assignedScars),
            _surfaceGradient(3, hex'3a03190019800303e3', 0x9F7A5A, 0x866244, assignedScars),
            _surfaceGradient(4, hex'3201f801f8000503e8', 0xA67F5E, 0x8D6C4F, assignedScars),
            _renderTech.linearGradient("eye7", hex'3201ed01ed001704e0', eyeStartColor, _lastStopPacked(0x593D26))
        );
        results = abi.encodePacked(results,
            _surfaceGradient(5, hex'3202e4020000ac04dc', 0x493219, 0x7D5F47, assignedScars),
            _surfaceGradient(6, hex'3202e900ae00b6045e', 0x493219, 0x7D5F47, assignedScars),
            _surfaceGradient(7, hex'3201ef01ef000003e8', 0x785A3B, 0x74573A, assignedScars),
            _surfaceGradient(8, hex'32020200b601ed02d6', 0x64462C, 0x362313, assignedScars),
            _surfaceGradient(9, hex'32035b01a300d802df', 0x79583C, 0x583C23, assignedScars),
            _surfaceGradient(10, hex'32027e027e001003e8', 0xA67F5E, 0x8D6C4F, assignedScars),
            _surfaceGradient(11, hex'3a00cf03cf800303e3', 0x9F7A5A, 0x866244, assignedScars),
            _surfaceGradient(12, hex'3201f001f0000503e8', 0xA67F5E, 0x8D6C4F, assignedScars)
        );
        results = abi.encodePacked(results,
            _renderTech.linearGradient("eye16", hex'3201fb01fb001704e0', eyeStartColor, _lastStopPacked(0x593D26)),
            _surfaceGradient(13, hex'32010401e800ac04dc', 0x493219, 0x7D5F47, assignedScars),
            _surfaceGradient(14, hex'3200ff033a00b6045e', 0x493219, 0x7D5F47, assignedScars),
            _surfaceGradient(15, hex'3201f901f9000003e8', 0x785A3B, 0x74573A, assignedScars),
            _renderTech.linearGradient("snout", hex'3200f400f4000003e8', _firstStopPacked(0x987B55), _lastStopPacked(0xC2A37B)),
            _renderTech.linearGradient("mouth", hex'3a02f402f4800603e8', _firstStopPacked(0x977752), _lastStopPacked(0x7B6143)),
            _surfaceGradient(16, hex'32020502f3005903d9', 0xB48B68, 0x947052, assignedScars)
        );
        return results;
    }

    /// @inheritdoc IBearRenderer
    function customEyeColor(ICubTraits.TraitsV1 memory dominantParent) external view onlyRenderTech returns (ISVGTypes.Color memory) {
        return SVG.mixColors(SVG.fromPackedColor(0x6B4D34), dominantParent.bottomColor, 50, 100);
    }

    /// @inheritdoc IBearRenderer
    // solhint-disable-next-line no-unused-vars
    function customSurfaces(uint176 genes, ISVGTypes.Color memory eyeColor, uint256 tokenId) external view onlyRenderTech returns (bytes memory) {
        bytes22 geneBytes = bytes22(genes);
        IBearRenderTechProvider.Substitution[] memory jowlSubstitutions = _jowlSubstitutions(_jowlRange(geneBytes, tokenId));
        IBearRenderTechProvider.Substitution[] memory eyeSubstitutions = _eyeSubstitutions(_eyeRange(geneBytes, tokenId));
        bytes memory results = SVG.createElement("g",
            // Translation
            abi.encodePacked(" transform='translate(0,", earRatio(geneBytes, tokenId).toDecimalString(1, false), ")'"), abi.encodePacked(
            // Left ear
            _renderTech.polygonElement(hex'1204e9056e0456047104fe02ee058c0469', "url(#paint0)"),
            _renderTech.polygonElement(hex'12064e03160500030c05880474074e039b', "url(#paint1)"),
            _renderTech.polygonElement(hex'1204560474041a03160500030c', "#A67F5E"),
            _renderTech.polygonElement(hex'12041a031604dc0258064a0316', "#805C3F"),
            // Right ear
            _renderTech.polygonElement(hex'120cab056e0d3e04710c9602ee0c080469', "url(#paint8)"),
            _renderTech.polygonElement(hex'120b4603160c94030c0c0c04740a46039b', "url(#paint9)"),
            _renderTech.polygonElement(hex'120d3e04740d7a03160c94030c', "#A67F5E"),
            _renderTech.polygonElement(hex'120d7a03160cb802580b4a0316', "#805C3F")
        ));
        results = abi.encodePacked(results,
            _renderTech.polygonElement(hex'1208ac073705be070806b2084306de0974', "url(#paint2)"),
            _renderTech.polygonElement(hex'1208ca0320083f05fd05be071c062303cf', "url(#paint3)"),
            _renderTech.polygonElement(hex'1203c007bc05c80719062703cf04bb052d', "url(#paint4)"),
            _renderTech.dynamicPolygonElement(hex'12083e05fa089805f00845079e05c80712', "url(#eye7)", eyeSubstitutions),
            _renderTech.polygonElement(hex'1207da081607120aaa06e0096e', "#D8B88F"),
            _renderTech.dynamicPolygonElement(hex'1205a20bd4049c0a7006110a28074e0c1c', "url(#paint5)", jowlSubstitutions)
        );
        results = abi.encodePacked(results,
            _renderTech.polygonElement(hex'1204950a8c03f207d006180a45', "url(#paint6)"),
            _renderTech.polygonElement(hex'1205c9071206b2083f07580c3a06110a4503c007b6', "url(#paint7)"),
            _renderTech.polygonElement(hex'1208ca0a3209ce0a6809ce0b2d08ca0ba407c70b2d07c60a68', "#301E10"),
            _renderTech.polygonElement(hex'1208e807370bd607080ae208430ab50974', "url(#paint10)"),
            _renderTech.polygonElement(hex'1208ca0320095405fd0bd6071c0b7103cf', "url(#paint11)"),
            _renderTech.polygonElement(hex'120dd407bc0bcc07190b6d03cf0cd9052d', "url(#paint12)"),
            _renderTech.dynamicPolygonElement(hex'12095605fa08fc05f0094e079e0bcc0712', "url(#eye16)", eyeSubstitutions)
        );
        results = abi.encodePacked(results,
            _renderTech.polygonElement(hex'1209ba08160a820aaa0ab4096e', "#D8B88F"),
            _renderTech.dynamicPolygonElement(hex'120bf20bd40cf80a700b830a280a460c1c', "url(#paint13)", jowlSubstitutions),
            _renderTech.polygonElement(hex'120cff0a8c0da207d00b7c0a45', "url(#paint14)"),
            _renderTech.polygonElement(hex'120bca07120ae2083f0a3c0c3a0b830a450dd407b6', "url(#paint15)"),
            _renderTech.polygonElement(hex'1208ca056409be08120a830aa907120aaa07d50812', "url(#snout)"),
            _renderTech.polygonElement(hex'1208ca0a4007110aa107580c3b08ca0c620a430c3b0a820aa1', "url(#mouth)"),
            _renderTech.polygonElement(hex'1209d804ee08ca032007be04ee083805fa08c90610095905fa', "url(#paint16)"),
            _renderTech.polygonElement(hex'1208ca0a3207c60a6807c60b2d08ca0ba409cd0b2d09ce0a68', "#301E10")
        );
        return results;
    }

    function _jowlRange(bytes22 geneBytes, uint256 tokenId) private pure returns (uint replacementY) {
        return 2728 + uint(jowlRatio(geneBytes, tokenId)) * 400 / 255; // Between 0 & 400
    }

    function _eyeRange(bytes22 geneBytes, uint256 tokenId) private pure returns (uint replacementY) {
        return 2400 - uint(eyeRatio(geneBytes, tokenId)) * 550 / 255; // Between 0 & 550
    }

    function _jowlSubstitutions(uint replacementY) private pure returns (IBearRenderTechProvider.Substitution[] memory substitutions) {
        substitutions = new IBearRenderTechProvider.Substitution[](2);
        // 144.2,302.8 & 305.8,302.8
        substitutions[0].matchingX = 1442;
        substitutions[0].matchingY = 3028;
        substitutions[0].replacementX = 1442;
        substitutions[0].replacementY = replacementY;
        substitutions[1].matchingX = 3058;
        substitutions[1].matchingY = 3028;
        substitutions[1].replacementX = 3058;
        substitutions[1].replacementY = replacementY;
    }

    function _eyeSubstitutions(uint replacementY) private pure returns (IBearRenderTechProvider.Substitution[] memory substitutions) {
        substitutions = new IBearRenderTechProvider.Substitution[](2);
        // 211.7,195.0 & 238.2,195.0
        substitutions[0].matchingX = 2117;
        substitutions[0].matchingY = 1950;
        substitutions[0].replacementX = 2117;
        substitutions[0].replacementY = replacementY;
        substitutions[1].matchingX = 2382;
        substitutions[1].matchingY = 1950;
        substitutions[1].replacementX = 2382;
        substitutions[1].replacementY = replacementY;
    }
}
