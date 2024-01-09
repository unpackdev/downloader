// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BearRenderer.sol";

/// @title PolarBearRenderer
contract PolarBearRenderer is BearRenderer {

    using DecimalStrings for uint256;

    // solhint-disable-next-line no-empty-blocks
    constructor(address renderTech) BearRenderer(renderTech) { }

    /// @inheritdoc IBearRenderer
    // solhint-disable-next-line no-unused-vars
    function customDefs(uint176 genes, ISVGTypes.Color memory eyeColor, IBear3Traits.ScarColor[] memory scars, uint256 tokenId) external view onlyRenderTech returns (bytes memory) {
        IBear3Traits.ScarColor[] memory assignedScars = _assignScars(16, scars, bytes22(genes), tokenId);
        bytes memory results = abi.encodePacked(
            _renderTech.linearGradient("chest", hex'3201f401f400000354', _firstStopPacked(0xA1B0B7), _lastStopPacked(0xE7EEF1)),
            _renderTech.linearGradient("neck", hex'3201f101f1022f03d3', _firstStopPacked(0x8FA3AC), _lastStopPacked(0xC6D8E1)),
            _surfaceGradient(0, hex'3a025f00b380810327', 0x8BA6B4, 0xBBCCD5, assignedScars),
            _surfaceGradient(1, hex'3a0189033580810327', 0x8BA6B4, 0xBBCCD5, assignedScars),
            _surfaceGradient(2, hex'3a026001d580e301f2', 0x8BA6B4, 0xBBCCD5, assignedScars),
            _surfaceGradient(3, hex'3a0188021380e301f2', 0x8BA6B4, 0xBBCCD5, assignedScars),
            _renderTech.linearGradient("forehead", hex'32016e00ad00d903a8', _firstStopPacked(0xFEFEFE), _lastStopPacked(0xCCD7DE)),
            _surfaceGradient(4, hex'3200d5029000020263', 0x62747E, 0x152026, assignedScars)
        );
        results = abi.encodePacked(results,
            _surfaceGradient(5, hex'320313015800020263', 0x62747E, 0x152026, assignedScars),
            _surfaceGradient(6, hex'3a015f02b7803c034a', 0xF0F9FF, 0x9CAAB4, assignedScars),
            _surfaceGradient(7, hex'3a02890131803c034a', 0xF0F9FF, 0x9CAAB4, assignedScars),
            _surfaceGradient(8, hex'32012f02b2001902b9', 0xDEE7ED, 0x687C88, assignedScars),
            _surfaceGradient(9, hex'3202b90136001902b9', 0xDEE7ED, 0x687C88, assignedScars),
            _surfaceGradient(10, hex'3a018602ea03e68012', 0xD5DEE3, 0xEEF6FB, assignedScars),
            _surfaceGradient(11, hex'3a026200fe03e68012', 0xD5DEE3, 0xEEF6FB, assignedScars),
            _surfaceGradient(12, hex'3202ac019c00f003b8', 0xFFFFFF, 0xD0D3D9, assignedScars)
        );
        bytes memory eyeStartColor = _firstStop(eyeColor); //#DEE5EA
        results = abi.encodePacked(results,
            _surfaceGradient(13, hex'32013c024c00f003b8', 0xFFFFFF, 0xD0D3D9, assignedScars),
            _renderTech.linearGradient("eye18", hex'3a008103b9800f02a6', eyeStartColor, _lastStopPacked(0xCCD8E0)),
            _renderTech.linearGradient("eye19", hex'3a0367002f800f02a6', eyeStartColor, _lastStopPacked(0xCCD8E0)),
            _surfaceGradient(14, hex'32041a033c01ee042a', 0xC9D4DB, 0xD4D9DC, assignedScars),
            _surfaceGradient(15, hex'3a803200ac01ee042a', 0xC9D4DB, 0xD4D9DC, assignedScars),
            _renderTech.linearGradient("snout", hex'3200b700b7000f0419', _firstStopPacked(0xE1E6EE), _lastStopPacked(0xF4F6F9)),
            _renderTech.linearGradient("mouth", hex'3a00aa00aa801e03fe', _firstStopPacked(0xE2EEF5), _lastStopPacked(0xC5D5DF))
        );
        return results;
    }

    /// @inheritdoc IBearRenderer
    function customEyeColor(ICubTraits.TraitsV1 memory dominantParent) external view onlyRenderTech returns (ISVGTypes.Color memory) {
        return SVG.mixColors(SVG.fromPackedColor(0xDEE5EA), dominantParent.bottomColor, 50, 100);
    }

    /// @inheritdoc IBearRenderer
    // solhint-disable-next-line no-unused-vars
    function customSurfaces(uint176 genes, ISVGTypes.Color memory eyeColor, uint256 tokenId) external view onlyRenderTech returns (bytes memory) {
        bytes22 geneBytes = bytes22(genes);
        uint earTranslation = uint(earRatio(geneBytes, tokenId)) * 1600 / 255; // Between 0 & 1600
        IBearRenderTechProvider.Substitution[] memory jowlSubstitutions = _jowlSubstitutions(_jowlRange(geneBytes, tokenId));
        (uint eyeReplacementY, uint eyeShiftX) = _eyeRange(geneBytes, tokenId);
        IBearRenderTechProvider.Substitution[] memory eyeSubstitutions = _eyeSubstitutions(eyeReplacementY, eyeShiftX);
        bytes memory results = SVG.createElement("g",
            // Translation
            abi.encodePacked(" transform='translate(0,", earTranslation.toDecimalString(2, false), ")'"), abi.encodePacked(
            // Left ear
            _renderTech.polygonElement(hex'120437047f05bb04a0042c06c1039f0506', "url(#paint4)"),
            _renderTech.polygonElement(hex'120d44047f0bbf04a00d4f06c10ddb0506', "url(#paint5)"),
            _renderTech.polygonElement(hex'1204a003f905f304ca0437047f039f0506032704ca03850419', "url(#paint6)"),
            // Right ear
            _renderTech.polygonElement(hex'120cdb03f90b8804ca0d44047f0ddc05060e5404ca0df60419', "url(#paint7)"),
            _renderTech.polygonElement(hex'1203370584032704ca039f0506047e076a', "url(#paint8)"),
            _renderTech.polygonElement(hex'120e4405840e5404ca0ddc05060cfd076a', "url(#paint9)")
        ));
        results = abi.encodePacked(results,
            _renderTech.polygonElement(hex'1204d809fb03cd075d063e09b3', "url(#paint0)"),
            _renderTech.polygonElement(hex'120ca309fb0dae075d0b3d09b3', "url(#paint1)"),
            _renderTech.dynamicPolygonElement(hex'12058b0ab804d809fa063e09b307320ab8078c0c4e', "url(#paint2)", jowlSubstitutions),
            _renderTech.dynamicPolygonElement(hex'120bf00ab80ca309fa0b3d09b30a490ab809ef0c4e', "url(#paint3)", jowlSubstitutions),
            _renderTech.polygonElement(hex'1205d4070b0735034a08c002d40a4b034a0bad070b', "url(#forehead)")
        );
        results = abi.encodePacked(results,
            _renderTech.polygonElement(hex'1206dc08ff05d4070b084007b9', "url(#paint10)"),
            _renderTech.polygonElement(hex'120a9f08ff0ba7070b093b07b9', "url(#paint11)"),
            _renderTech.polygonElement(hex'1205d4070b0739034b0591042703a9073e', "url(#paint12)"),
            _renderTech.polygonElement(hex'120ba7070b0a42034b0bea04270dd2073e', "url(#paint13)")
        );
        results = abi.encodePacked(results,
            _renderTech.dynamicPolygonElement(hex'1205d4070b0832063907c1083e', "url(#eye18)", eyeSubstitutions),
            _renderTech.dynamicPolygonElement(hex'120ba7070b0949063909ba083e', "url(#eye19)", eyeSubstitutions),
            _renderTech.polygonElement(hex'1206dc08fe07da07b907330ab906dc08fe0a9f08fe09a107b90a480ab90a9f08fe', "#DFE9EC"),
            _renderTech.polygonElement(hex'1203a9073e05d4070b06dc08fe07330ab9', "url(#paint14)"),
            _renderTech.polygonElement(hex'120dd2073e0ba7070b0a9f08fe0a480ab9', "url(#paint15)"),
            _renderTech.polygonElement(hex'12082e063108c40600095a06310a580ab907320ab9', "url(#snout)"),
            _renderTech.polygonElement(hex'120a580ab809ff0c4d08c50c8f078a0c4d07320ab808c50a5d', "url(#mouth)"),
            _renderTech.polygonElement(hex'1207f60a6d07f60b5908c30b9709910b5909910a6d08c30a40', "black")
        );
        return results;
    }

    function _jowlRange(bytes22 geneBytes, uint256 tokenId) private pure returns (uint replacementY) {
        return 2744 + uint(jowlRatio(geneBytes, tokenId)) * 300 / 255; // Between 0 & 300
    }

    function _eyeRange(bytes22 geneBytes, uint256 tokenId) private pure returns (uint replacementY, uint shiftX) {
        uint ratio = uint(eyeRatio(geneBytes, tokenId));
        replacementY = 2380 - (ratio * 360 / 255); // Between 0 & 360
        shiftX = ratio * 30 / 255; // Between 0 & 30
    }

    function _jowlSubstitutions(uint replacementY) private pure returns (IBearRenderTechProvider.Substitution[] memory substitutions) {
        substitutions = new IBearRenderTechProvider.Substitution[](2);
        // 141.9,274.4 & 305.6,274.4
        substitutions[0].matchingX = 1419;
        substitutions[0].matchingY = 2744;
        substitutions[0].replacementX = 1419;
        substitutions[0].replacementY = replacementY;
        substitutions[1].matchingX = 3056;
        substitutions[1].matchingY = 2744;
        substitutions[1].replacementX = 3056;
        substitutions[1].replacementY = replacementY;
    }

    function _eyeSubstitutions(uint replacementY, uint shiftX) private pure returns (IBearRenderTechProvider.Substitution[] memory substitutions) {
        substitutions = new IBearRenderTechProvider.Substitution[](2);
        // 198.5,211.0 & 249.0,211.0 // 202.0,195.5
        substitutions[0].matchingX = 1985;
        substitutions[0].matchingY = 2110;
        substitutions[0].replacementX = 1985 + shiftX;
        substitutions[0].replacementY = replacementY;
        substitutions[1].matchingX = 2490;
        substitutions[1].matchingY = 2110;
        substitutions[1].replacementX = 2490 - shiftX;
        substitutions[1].replacementY = replacementY;
    }
}
