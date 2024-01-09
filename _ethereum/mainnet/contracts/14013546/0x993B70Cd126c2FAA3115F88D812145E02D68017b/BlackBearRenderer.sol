// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BearRenderer.sol";

/// @title BlackBearRenderer
contract BlackBearRenderer is BearRenderer {

    using DecimalStrings for uint256;

    // solhint-disable-next-line no-empty-blocks
    constructor(address renderTech) BearRenderer(renderTech) { }

    /// @inheritdoc IBearRenderer
    // solhint-disable-next-line no-unused-vars
    function customDefs(uint176 genes, ISVGTypes.Color memory eyeColor, IBear3Traits.ScarColor[] memory scars, uint256 tokenId) external view onlyRenderTech returns (bytes memory) {
        IBear3Traits.ScarColor[] memory assignedScars = _assignScars(16, scars, bytes22(genes), tokenId);
        bytes memory results = abi.encodePacked(
            _renderTech.linearGradient("chest", hex'3201f401f400e3033e', "", _lastStopPacked(0x323439)),
            _renderTech.linearGradient("neck", hex'3201f401f401f103e8', _firstStopPacked(0x171920), _lastStopPacked(0x393B42)),
            _surfaceGradient(0, hex'32031500f9007602b0', 0x171A22, 0x2E323A, assignedScars),
            _renderTech.linearGradient("leftCheek", hex'3a01f301f3800203e8', _firstStopPacked(0x24262E), _lastStopPacked(0x06080B)),
            _surfaceGradient(1, hex'3a800303d5813503ed', 0x404448, 0x212426, assignedScars),
            _surfaceGradient(2, hex'3201e001e0000003e8', 0x41444E, 0x13151C, assignedScars),
            _surfaceGradient(3, hex'3201f801f8000403e8', 0x3D4048, 0x1E2129, assignedScars),
            _surfaceGradient(4, hex'3201f401f4000003e8', 0x545757, 0x414444, assignedScars)
        );
        results = abi.encodePacked(results,
            _surfaceGradient(5, hex'32010c0284008303e9', 0x171A22, 0x2E323A, assignedScars),
            _surfaceGradient(6, hex'3201d602eb000a0395', 0x2D3134, 0x3D4043, assignedScars),
            _surfaceGradient(7, hex'3200d302ef007602b0', 0x171A22, 0x2E323A, assignedScars),
            _renderTech.linearGradient("rightCheek", hex'3a01f501f5800203e8', _firstStopPacked(0x24262E), _lastStopPacked(0x06080B)),
            _surfaceGradient(8, hex'3a03eb000c813703f6', 0x404448, 0x212426, assignedScars),
            _surfaceGradient(9, hex'3202080208000003e8', 0x41444E, 0x13151C, assignedScars),
            _surfaceGradient(10, hex'3201f001f0000403e8', 0x3D4048, 0x1E2129, assignedScars),
            _surfaceGradient(11, hex'3201f401f4000003e8', 0x545757, 0x414444, assignedScars)
        );
        results = abi.encodePacked(results,
            _surfaceGradient(12, hex'3202dc0164008303e9', 0x171A22, 0x2E323A, assignedScars),
            _surfaceGradient(13, hex'32021200fd000a0395', 0x2D3134, 0x3D4043, assignedScars),
            _surfaceGradient(14, hex'3201e001e0001103de', 0x655C4D, 0x6E6555, assignedScars),
            _renderTech.linearGradient("snout", hex'3a01010101800203e0', _firstStopPacked(0x7D6E5A), _lastStopPacked(0x8D7D67)),
            _renderTech.linearGradient("mouth", hex'3201010101000003be', _firstStopPacked(0x5E503E), _lastStopPacked(0x615341)),
            _surfaceGradient(15, hex'3202080208001103de', 0x655C4D, 0x6E6555, assignedScars)
        );
        return results;
    }

    /// @inheritdoc IBearRenderer
    function customEyeColor(ICubTraits.TraitsV1 memory dominantParent) external view onlyRenderTech returns (ISVGTypes.Color memory) {
        return SVG.mixColors(SVG.fromPackedColor(0), dominantParent.bottomColor, 85, 100);
    }

    /// @inheritdoc IBearRenderer
    function customSurfaces(uint176 genes, ISVGTypes.Color memory eyeColor, uint256 tokenId) external view onlyRenderTech returns (bytes memory) {
        bytes22 geneBytes = bytes22(genes);
        IBearRenderTechProvider.Substitution[] memory jowlSubstitutions = _jowlSubstitutions(_jowlRange(geneBytes, tokenId));
        IBearRenderTechProvider.Substitution[] memory eyeSubstitutions = _eyeSubstitutions(_eyeRange(geneBytes, tokenId));
        bytes memory eyeAttributes = SVG.colorAttributeRGBValue(eyeColor);
        bytes memory results = SVG.createElement("g",
            // Translation
            abi.encodePacked(" transform='translate(0,", earRatio(geneBytes, tokenId).toDecimalString(1, false), ")'"), abi.encodePacked(
            // Left ear
            _renderTech.polygonElement(hex'12068f037505f00305041f02ab0579044b', "#0F1216"),
            _renderTech.polygonElement(hex'12041f02ab0583044104af0588', "black"),
            _renderTech.polygonElement(hex'12041f02ac04c2025805f50308', "url(#paint1)"),
            _renderTech.polygonElement(hex'12041f02ab04b9058803c00450', "url(#paint2)"),
            // Right ear
            _renderTech.polygonElement(hex'120af203750b9103050d6202ab0c08044b', "#0F1216"),
            _renderTech.polygonElement(hex'120d6202ab0bfe04410cd20588', "black"),
            _renderTech.polygonElement(hex'120d6202ac0cbf02580b8f0306', "url(#paint8)"),
            _renderTech.polygonElement(hex'120d6202ab0cc805880dc10450', "url(#paint9)")
        ));
        results = abi.encodePacked(results,
            _renderTech.dynamicPolygonElement(hex'12055d0b7a04b10a54061409f607590bf4', "url(#paint0)", jowlSubstitutions),
            _renderTech.polygonElement(hex'1207da05be05d3064507120a730776094d', "url(#leftCheek)"),
            _renderTech.dynamicPolygonElement(hex'1205cd063f07db0701061a0849', eyeAttributes, eyeSubstitutions),
            _renderTech.polygonElement(hex'1208c1030c0633037b05c9064a08c10582', "url(#paint3)"),
            _renderTech.polygonElement(hex'120637037a05d2064503c1076204ba04d9', "url(#paint4)"),
            _renderTech.polygonElement(hex'1204b10a6403fd0794063b09f6', "url(#paint5)"),
            _renderTech.polygonElement(hex'1205d2063b078a0bcc07590bf4060409fb03ca075d', "url(#paint6)")
        );
        results = abi.encodePacked(results,
            _renderTech.dynamicPolygonElement(hex'120c240b7a0cd00a540b6d09f60a280bf4', "url(#paint7)", jowlSubstitutions),
            _renderTech.polygonElement(hex'1209a705be0bae06450a6f0a730a0b094d', "url(#rightCheek)"),
            _renderTech.dynamicPolygonElement(hex'120bb5063f09a607010b670849', eyeAttributes, eyeSubstitutions),
            _renderTech.polygonElement(hex'1208c0030c0b4e037b0bb8064a08c00582', "url(#paint10)"),
            _renderTech.polygonElement(hex'120b4a037a0baf06450dc007620cc704d9', "url(#paint11)"),
            _renderTech.polygonElement(hex'120cd00a640d8407940b4609f6', "url(#paint12)"),
            _renderTech.polygonElement(hex'120baf063b09f70bcc0a280bf40b7d09fb0db7075d', "url(#paint13)")
        );
        results = abi.encodePacked(results,
            _renderTech.polygonElement(hex'1207bd04ba08c1030c09c504ba09b205be07d305be', "#26292B"),
            _renderTech.polygonElement(hex'1207d105ae08cb056e076d094c', "url(#paint14)"),
            _renderTech.polygonElement(hex'1209b005ae08b6056e0a14094c', "url(#paint15)"),
            _renderTech.polygonElement(hex'1208c105820a1809330a700a6407120a64076a0933', "url(#snout)"),
            _renderTech.polygonElement(hex'120a720a5c0a320c0c08c30c5c07550c0c07130a5c08c30a07', "url(#mouth)"),
            _renderTech.polygonElement(hex'1208c109e207c70a0f07c80ad108c10b3609ba0ad209ba0a0f', "black")
        );
        return results;
    }

    function _jowlRange(bytes22 geneBytes, uint256 tokenId) private pure returns (uint replacementY) {
        return 2738 + uint(jowlRatio(geneBytes, tokenId)) * 300 / 255; // Between 0 & 300
    }

    function _eyeRange(bytes22 geneBytes, uint256 tokenId) private pure returns (uint replacementY) {
        return 1826 + uint(eyeRatio(geneBytes, tokenId)) * 765 / 255; // Between 0 & 765
    }

    function _jowlSubstitutions(uint replacementY) private pure returns (IBearRenderTechProvider.Substitution[] memory substitutions) {
        substitutions = new IBearRenderTechProvider.Substitution[](2);
        // 137.3,293.8 & 310.8,293.8
        substitutions[0].matchingX = 1373;
        substitutions[0].matchingY = 2938;
        substitutions[0].replacementX = 1373;
        substitutions[0].replacementY = replacementY;
        substitutions[1].matchingX = 3108;
        substitutions[1].matchingY = 2938;
        substitutions[1].replacementX = 3108;
        substitutions[1].replacementY = replacementY;
    }

    function _eyeSubstitutions(uint replacementY) private pure returns (IBearRenderTechProvider.Substitution[] memory substitutions) {
        substitutions = new IBearRenderTechProvider.Substitution[](2);
        // 156.2,212.1 & 291.9,212.1
        substitutions[0].matchingX = 1562;
        substitutions[0].matchingY = 2121;
        substitutions[0].replacementX = 1562;
        substitutions[0].replacementY = replacementY;
        substitutions[1].matchingX = 2919;
        substitutions[1].matchingY = 2121;
        substitutions[1].replacementX = 2919;
        substitutions[1].replacementY = replacementY;
    }
}
