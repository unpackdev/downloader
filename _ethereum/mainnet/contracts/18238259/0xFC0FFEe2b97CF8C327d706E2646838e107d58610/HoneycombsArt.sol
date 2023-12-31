//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IHoneycombs.sol";
import "./Utilities.sol";
import "./GridArt.sol";
import "./GradientsArt.sol";

/**
@title  HoneycombsArt
@notice Renders the Honeycombs visuals.
*/
library HoneycombsArt {
    enum HEXAGON_TYPE { FLAT, POINTY } // prettier-ignore
    enum SHAPE { TRIANGLE, DIAMOND, HEXAGON, RANDOM } // prettier-ignore

    /// @dev Generate relevant rendering data by loading honeycomb from storage and filling its attribute settings.
    /// @param honeycombs The DB containing all honeycombs.
    /// @param tokenId The tokenId of the honeycomb to render.
    function generateHoneycombRenderData(
        IHoneycombs.Honeycombs storage honeycombs,
        uint256 tokenId
    ) public view returns (IHoneycombs.Honeycomb memory honeycomb) {
        IHoneycombs.StoredHoneycomb memory stored = honeycombs.all[tokenId];
        honeycomb.stored = stored;

        // Determine if the honeycomb is revealed via the epoch randomness.
        uint128 randomness = honeycombs.epochs[stored.epoch].randomness;
        honeycomb.isRevealed = randomness > 0;

        // Exit early if the honeycomb is not revealed.
        if (!honeycomb.isRevealed) {
            return honeycomb;
        }

        // Set the seed.
        honeycomb.seed = (uint256(keccak256(abi.encodePacked(randomness, stored.seed))) % type(uint128).max);

        // Set the canvas properties.
        honeycomb.canvas.color = Utilities.random(honeycomb.seed, "canvasColor", 2) == 0 ? "White" : "Black";
        honeycomb.canvas.size = 810;
        honeycomb.canvas.hexagonSize = 72;
        honeycomb.canvas.maxHexagonsPerLine = 8; // (810 (canvasSize) - 90 (padding) / 72 (hexagon size)) - 1 = 8

        // Get the base hexagon properties.
        honeycomb.baseHexagon.hexagonType = uint8(
            Utilities.random(honeycomb.seed, "hexagonType", 2) == 0 ? HEXAGON_TYPE.FLAT : HEXAGON_TYPE.POINTY
        );
        honeycomb.baseHexagon.path = GridArt.getHexagonPath(honeycomb.baseHexagon.hexagonType);
        honeycomb.baseHexagon.strokeWidth = uint8(Utilities.random(honeycomb.seed, "strokeWidth", 15) + 3);
        honeycomb.baseHexagon.fillColor = Utilities.random(honeycomb.seed, "hexagonFillColor", 2) == 0
            ? "White"
            : "Black";

        /**
         * Get the grid properties, including the actual svg.
         * Note: Random shapes must only have pointy top hexagon bases (artist design choice).
         * Note: Triangles have unique rotation options (artist design choice).
         */
        honeycomb.grid.shape = uint8(Utilities.random(honeycomb.seed, "gridShape", 4));
        if (honeycomb.grid.shape == uint8(SHAPE.RANDOM)) {
            honeycomb.baseHexagon.hexagonType = uint8(HEXAGON_TYPE.POINTY);
            honeycomb.baseHexagon.path = GridArt.getHexagonPath(honeycomb.baseHexagon.hexagonType);
        }

        honeycomb.grid.rotation = honeycomb.grid.shape == uint8(SHAPE.TRIANGLE)
            ? uint16(Utilities.random(honeycomb.seed, "rotation", 4) * 90)
            : uint16(Utilities.random(honeycomb.seed, "rotation", 12) * 30);

        (honeycomb.grid.svg, honeycomb.grid.totalGradients, honeycomb.grid.rows) = GridArt.generateGrid(honeycomb);

        // Get the gradients properties, including the actual svg.
        honeycomb.gradients.chrome = GradientsArt.getChrome(uint8(Utilities.random(honeycomb.seed, "chrome", 7)));
        honeycomb.gradients.duration = GradientsArt.getDuration(uint16(Utilities.random(honeycomb.seed, "duration", 4)));
        honeycomb.gradients.direction = uint8(Utilities.random(honeycomb.seed, "direction", 2));
        honeycomb.gradients.svg = GradientsArt.generateGradientsSvg(honeycomb);
    }

    /// @dev Generate the complete SVG and its associated data for a honeycomb.
    /// @param honeycombs The DB containing all honeycombs.
    /// @param tokenId The tokenId of the honeycomb to render.
    function generateHoneycomb(
        IHoneycombs.Honeycombs storage honeycombs,
        uint256 tokenId
    ) public view returns (IHoneycombs.Honeycomb memory) {
        IHoneycombs.Honeycomb memory honeycomb = generateHoneycombRenderData(honeycombs, tokenId);

        if (!honeycomb.isRevealed) {
            // prettier-ignore
            honeycomb.svg = abi.encodePacked(
                '<svg viewBox="0 0 810 810" fill="#ffffff" xmlns="http://www.w3.org/2000/svg" style="width:100%;background:black;">',
                    '<rect width="810" height="810" fill="black" transform="translate(-37.98, -37.98)" />',
                    '<g id="logo" transform="translate(220, 220)">',
                        '<g id="hexagon" transform="translate(17.089965000000007,17.089965000000007), scale(0.91)">',
                            '<path transform="translate(-37.98, -37.98), scale(28.48375)" fill="#181818" ',
                                'd="M9.166.33a2.25 2.25 0 00-2.332 0l-5.25 3.182A2.25 2.25 0 00.5 5.436v5.128a2.25 2.25 0 001.084 1.924l5.25 3.182a2.25 2.25 0 002.332 0l5.25-3.182a2.25 2.25 0 001.084-1.924V5.436a2.25 2.25 0 00-1.084-1.924L9.166.33z">',
                            '</path>',
                        '</g>'
                        '<g id="hummingbird" stroke-linecap="round" stroke-linejoin="round" stroke="#ffc107" stroke-width="6">',
                            '<path d="M366.314,97.749c-0.129-1.144-1.544-1.144-2.389-1.144c-6.758,0-37.499,4.942-62.82,13.081 c-1.638,0.527-2.923,0.783-3.928,0.783c-1.961,0-2.722-0.928-4.254-3.029c-1.848-2.533-4.379-6.001-11.174-8.914 c-2.804-1.202-6.057-1.812-9.667-1.812c-14.221,0-32.199,9.312-42.749,22.142c-0.066,0.08-0.103,0.096-0.107,0.096 c-0.913,0-4.089-3.564-9.577-17.062c-4.013-9.87-8.136-22.368-10.504-31.842c-3.553-14.212-13.878-34.195-20.71-47.417 c-2.915-5.642-5.218-10.098-5.797-11.836c-0.447-1.339-1.15-2.019-2.091-2.019c-0.604,0-1.184,0.3-1.773,0.917 c-6.658,6.983-20.269,65.253-19.417,83.132c0.699,14.682,12.291,24.61,17.861,29.381c0.659,0.564,1.363,1.167,1.911,1.67 c-2.964-1.06-9.171-6.137-17.406-12.873c-11.881-9.718-29.836-24.403-54.152-40.453c-34.064-22.484-55.885-44.77-68.922-58.084 C29.964,3.599,26.338,0,23.791,0c-0.605,0-1.707,0.227-2.278,1.75c-2.924,7.798,0.754,88.419,37.074,132.002 c20.279,24.335,46.136,36.829,63.246,45.097c9.859,4.764,17.647,8.527,18.851,12.058c0.273,0.803,0.203,1.573-0.223,2.425 c-1.619,3.238-4.439,7.193-8.011,12.202c-9.829,13.783-24.682,34.613-35.555,69.335c-4.886,15.601-55.963,70.253-69.247,83.537 c-0.648,0.648-15.847,15.917-14.06,20.229c0.142,0.344,0.613,1.143,1.908,1.143c3.176,0,11.554-5.442,24.902-16.195 c17.47-14.073,29.399-25.848,38.11-34.452c8.477-8.374,13.784-13.596,17.427-14.161c-0.333,1.784-1.385,6.367-4.576,17.926 c-0.077,0.279-0.238,0.938,0.127,1.418l0.355,0.576h0.495c0.001,0,0.002,0,0.003,0c0.773,0,1.172-0.618,4.53-4.786 c10.244-12.714,41.417-51.561,84.722-60.067c25.376-4.985,56.886-28.519,68.008-63.854c16.822-53.439,30.902-87.056,105.176-104.081 C366.502,99.413,366.428,98.751,366.314,97.749z" />'
                        '</g>',
                    '</g>',
                '</svg>'
            );
        } else {
            // prettier-ignore
            honeycomb.svg = abi.encodePacked(
                // Note: Use 810 as hardcoded size to avoid stack too deep error.
                '<svg viewBox="0 0 810 810" fill="none" xmlns="http://www.w3.org/2000/svg" ', 
                        'style="width:100%;background:', honeycomb.canvas.color, ';">',
                    '<defs>',
                        '<path id="hexagon" fill="', honeycomb.baseHexagon.fillColor,
                            '" stroke-width="', Utilities.uint2str(honeycomb.baseHexagon.strokeWidth),
                            '" d="', honeycomb.baseHexagon.path ,'" />',
                        honeycomb.gradients.svg,
                    '</defs>',
                    '<rect width="810" height="810" fill="', honeycomb.canvas.color, '"/>',
                    honeycomb.grid.svg,
                    '<rect width="810" height="810" fill="transparent">',
                        '<animate attributeName="width" from="810" to="0" dur="0.2s" fill="freeze" ',
                            'begin="click" id="animation"/>',
                    '</rect>',
                '</svg>'
            );
        }

        return honeycomb;
    }
}