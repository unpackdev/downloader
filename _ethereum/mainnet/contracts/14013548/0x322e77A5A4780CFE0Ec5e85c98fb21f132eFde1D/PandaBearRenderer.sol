// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BearRenderer.sol";

/// @title PandaBearRenderer
contract PandaBearRenderer is BearRenderer {

    using DecimalStrings for uint256;

    // solhint-disable-next-line no-empty-blocks
    constructor(address renderTech) BearRenderer(renderTech) { }

    /// @inheritdoc IBearRenderer
    // solhint-disable-next-line no-unused-vars
    function customDefs(uint176 genes, ISVGTypes.Color memory eyeColor, IBear3Traits.ScarColor[] memory scars, uint256 tokenId) external view onlyRenderTech returns (bytes memory) {
        IBear3Traits.ScarColor[] memory assignedScars = _assignScars(12, scars, bytes22(genes), tokenId);
        bytes memory results = abi.encodePacked(
            _renderTech.linearGradient("chest", hex'3201f401f4000003e8', "", _lastStopPacked(0x565656)),
            _renderTech.linearGradient("neck", hex'3201f601f4013603e8', _firstStopPacked(0xA8A8A8), _lastStopPacked(0xF8F8F8)),
            _surfaceGradient(0, hex'32024b014400860386', 0x171819, 0x646464, assignedScars),
            _surfaceGradient(1, hex'32019d02a400860386', 0x171819, 0x646464, assignedScars),
            _surfaceGradient(2, hex'3200f600f6016503e8', 0xD9D9D7, 0xBFBFBE, assignedScars),
            _surfaceGradient(3, hex'3201b5008f012103d0', 0xFEFEFE, 0xAAAAAA, assignedScars),
            _surfaceGradient(4, hex'3a0285031303e88006', 0xD8D8D8, 0xFEFEFE, assignedScars),
            _renderTech.linearGradient("leftCheek", hex'3200ef02a50025037e', _firstStopPacked(0xC9C9C9), _lastStopPacked(0xFFFFFF))
        );
        results = abi.encodePacked(results,
            _surfaceGradient(5, hex'3a0361810c00590071', 0xB5B4B4, 0xFBFAFA, assignedScars),
            _surfaceGradient(6, hex'3a023480db81000186', 0xB5B4B4, 0xFBFAFA, assignedScars),
            _surfaceGradient(7, hex'3202f202f2016503e8', 0xD9D9D7, 0xBFBFBE, assignedScars),
            _surfaceGradient(8, hex'3202330359012103d0', 0xFEFEFE, 0xAAAAAA, assignedScars),
            _surfaceGradient(9, hex'3a016300d503e88006', 0xD8D8D8, 0xFEFEFE, assignedScars),
            _renderTech.linearGradient("rightCheek", hex'3202f901430025037e', _firstStopPacked(0xC9C9C9), _lastStopPacked(0xFFFFFF)),
            _surfaceGradient(10, hex'32008704f400590071', 0xB5B4B4, 0xFBFAFA, assignedScars),
            _surfaceGradient(11, hex'3a01b404c381000186', 0xB5B4B4, 0xFBFAFA, assignedScars)
        );
        results = abi.encodePacked(results,
            _renderTech.linearGradient("forehead", hex'3201a001630129035b', _firstStopPacked(0xEBEBEB), _lastStopPacked(0xA9A9A9)),
            _renderTech.linearGradient("snout", hex'3a014101bc03e88039', _firstStopPacked(0xFFFDFD), _lastStopPacked(0xC8C8C8)),
            _renderTech.linearGradient("mouth", hex'3a00fd00fd80a203e1', _firstStopPacked(0x949494), " offset='0.630208' stop-color='#E8E8E8'")
        );
        return results;
    }

    /// @inheritdoc IBearRenderer
    function customEyeColor(ICubTraits.TraitsV1 memory dominantParent) external view onlyRenderTech returns (ISVGTypes.Color memory) {
        return SVG.mixColors(SVG.fromPackedColor(0), dominantParent.topColor, 85, 100);
    }

    /// @inheritdoc IBearRenderer
    function customSurfaces(uint176 genes, ISVGTypes.Color memory eyeColor, uint256 tokenId) external view onlyRenderTech returns (bytes memory) {
        bytes22 geneBytes = bytes22(genes);
        IBearRenderTechProvider.Substitution[] memory jowlSubstitutions = _jowlSubstitutions(_jowlRange(geneBytes, tokenId));
        IBearRenderTechProvider.Substitution[] memory eyeSubstitutions = _eyeSubstitutions(_eyeRange(geneBytes, tokenId));
        bytes memory results = SVG.createElement("g",
            // Translation
            abi.encodePacked(" transform='translate(0,", earRatio(geneBytes, tokenId).toDecimalString(1, false), ")'"), abi.encodePacked(
            // Left ear
            _renderTech.polygonElement(hex'12067304780664038f05a7031b04300346053903b5', "#343739"),
            _renderTech.polygonElement(hex'1204310347053903b30636045204af05e504ac05f204a605ee04a605ee04a605ee03b40539039d0449039e044904300346', "url(#paint0)"),
            // Right ear
            _renderTech.polygonElement(hex'120b0d04780b1c038f0bd9031b0d5003460c4703b5', "#343739"),
            _renderTech.polygonElement(hex'120d4f03470c4703b30b4a04520cd105e50cd405f20cda05ee0cda05ee0cda05ee0dcc05390de304490de204490d500346', "url(#paint1)")
        ));
        results = abi.encodePacked(results,
            _renderTech.polygonElement(hex'1205fa0892086c071806c90a9c', "url(#paint2)"),
            _renderTech.polygonElement(hex'1205ea041c08c002ee08c00634080b065a072a062c06c506e805cf07b9', "url(#paint3)"),
            _renderTech.polygonElement(hex'12039307d7051404fc05ea041c05db0798', "url(#paint4)"),
            _renderTech.polygonElement(hex'1206f90c4e039307d7063307840625088e08c00bdd08c00c8b', "url(#leftCheek)"),
            _renderTech.polygonElement(hex'12041d0a2803ad07fa051a09d7', "url(#paint5)")
        );
        results = abi.encodePacked(results,
            _renderTech.dynamicPolygonElement(hex'1204ef0b5e041d0a28051a09d705b40aa006fb0c4d', "url(#paint6)", jowlSubstitutions),
            _renderTech.polygonElement(hex'120b860892091407180ab70a9c', "url(#paint7)"),
            _renderTech.polygonElement(hex'120b96041c08c002ee08c006340975065a0a56062c0abb06e80bb107b9', "url(#paint8)"),
            _renderTech.polygonElement(hex'120ded07d70c6c04fc0b96041c0ba50798', "url(#paint9)"),
            _renderTech.polygonElement(hex'120a870c4e0ded07d70b4d07840b5b088e08c00bdd08c00c8b', "url(#rightCheek)"),
            _renderTech.polygonElement(hex'120d630a280dd307fa0c6609d7', "url(#paint10)")
        );
        results = abi.encodePacked(results,
            _renderTech.dynamicPolygonElement(hex'120c910b5e0d630a280c6609d70bcc0aa00a850c4d', "url(#paint11)", jowlSubstitutions),
            _renderTech.polygonElement(hex'1207d106fa072a062c07e1034a08bf02e7099d034a0a5d062c09ac06fa08c00647', "url(#forehead)"),
            _renderTech.dynamicPolygonElement(hex'12072a062c07b6065b07d106fa07c009300625089205da079a069506e2072a062c0a56062c09ca065b09af06fa09c009300b5b08920ba6079a0aeb06e20a56062c', SVG.colorAttributeRGBValue(eyeColor), eyeSubstitutions),
            _renderTech.polygonElement(hex'1207cf06f908c1063509b306f90afc0a9d08c00a4906890a9d', "url(#snout)"),
            _renderTech.polygonElement(hex'1206870a9b07520c0708c10c340a300c070aff0a9b08c30a47', "url(#mouth)"),
            _renderTech.polygonElement(hex'1208c90a2807b90a3607a80a8708c90b2809eb0a8709d70a36', "black")
        );
        return results;
    }

    function _jowlRange(bytes22 geneBytes, uint256 tokenId) private pure returns (uint replacementY) {
        return 2710 + uint(jowlRatio(geneBytes, tokenId)) * 400 / 255; // Between 0 & 400
    }

    function _eyeRange(bytes22 geneBytes, uint256 tokenId) private pure returns (uint replacementY) {
        return 2352 - uint(eyeRatio(geneBytes, tokenId)) * 400 / 255; // Between 0 & 400
    }

    function _jowlSubstitutions(uint replacementY) private pure returns (IBearRenderTechProvider.Substitution[] memory substitutions) {
        substitutions = new IBearRenderTechProvider.Substitution[](2);
        // 126.3,291.0 & 321.7,291.0
        substitutions[0].matchingX = 1263;
        substitutions[0].matchingY = 2910;
        substitutions[0].replacementX = 1263;
        substitutions[0].replacementY = replacementY;
        substitutions[1].matchingX = 3217;
        substitutions[1].matchingY = 2910;
        substitutions[1].replacementX = 3217;
        substitutions[1].replacementY = replacementY;
    }

    function _eyeSubstitutions(uint replacementY) private pure returns (IBearRenderTechProvider.Substitution[] memory substitutions) {
        substitutions = new IBearRenderTechProvider.Substitution[](2);
        // 198.4,235.2 & 249.6,235.2
        substitutions[0].matchingX = 1984;
        substitutions[0].matchingY = 2352;
        substitutions[0].replacementX = 1984;
        substitutions[0].replacementY = replacementY;
        substitutions[1].matchingX = 2496;
        substitutions[1].matchingY = 2352;
        substitutions[1].replacementX = 2496;
        substitutions[1].replacementY = replacementY;
    }
}
