// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Strings.sol";

library Colors {
    using Strings for uint256;

    struct HSL {
        uint256 hue;
        uint256 saturation;
        uint256 lightness;
    }

    struct Color {
        string start;
        string end;
    }

    struct MainframeColors {
        Color light;
        Color medium;
        Color dark;
        Color bg;
    }

    function generateHSLColor(
        string memory seed,
        uint256 hMin,
        uint256 hMax,
        uint256 sMin,
        uint256 sMax,
        uint256 lMin,
        uint256 lMax
    ) public pure returns (HSL memory) {
        return
            HSL(
                generatePseudoRandomValue(
                    string(abi.encodePacked("H", seed)),
                    hMin,
                    hMax
                ),
                generatePseudoRandomValue(
                    string(abi.encodePacked("S", seed)),
                    sMin,
                    sMax
                ),
                generatePseudoRandomValue(
                    string(abi.encodePacked("L", seed)),
                    lMin,
                    lMax
                )
            );
    }

    function toHSLString(HSL memory hsl) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "hsl(",
                    hsl.hue.toString(),
                    ",",
                    hsl.saturation.toString(),
                    "%,",
                    hsl.lightness.toString(),
                    "%)"
                )
            );
    }

    function generatePseudoRandomValue(
        string memory seed,
        uint256 from,
        uint256 to
    ) public pure returns (uint256) {
        if (to <= from) return from;
        return
            (uint256(keccak256(abi.encodePacked(seed))) % (to - from)) + from;
    }

    function generateComputerColors(string memory seed)
        public
        pure
        returns (MainframeColors memory)
    {
        HSL memory lightStart = generateHSLColor(
            string(abi.encodePacked(seed, "LIGHT_START")),
            0,
            359,
            50,
            70,
            55,
            75
        );
        HSL memory lightEnd = generateHSLColor(
            string(abi.encodePacked(seed, "LIGHT_END")),
            lightStart.hue + 359 - generatePseudoRandomValue(seed, 5, 60),
            lightStart.hue + 359 + generatePseudoRandomValue(seed, 5, 60),
            70,
            85,
            25,
            45
        );
        HSL memory mediumStart = generateHSLColor(
            string(abi.encodePacked(seed, "MEDIUM_START")),
            lightStart.hue,
            lightStart.hue,
            lightStart.saturation,
            lightStart.saturation,
            35,
            50
        );
        HSL memory mediumEnd = generateHSLColor(
            string(abi.encodePacked(seed, "MEDIUM_START")),
            lightEnd.hue,
            lightEnd.hue,
            lightEnd.saturation,
            lightEnd.saturation,
            35,
            10
        );

        HSL memory darkStart = generateHSLColor(
            string(abi.encodePacked(seed, "MEDIUM_START")),
            0,
            359,
            40,
            70,
            13,
            16
        );
        HSL memory darkEnd = generateHSLColor(
            string(abi.encodePacked(seed, "DARKEST_END")),
            darkStart.hue + 359 - generatePseudoRandomValue(seed, 5, 60),
            darkStart.hue + 359 + generatePseudoRandomValue(seed, 5, 60),
            darkStart.saturation,
            darkStart.saturation,
            3,
            13
        );

        HSL memory BGStart = generateHSLColor(
            string(abi.encodePacked(seed, "BG_START")),
            0,
            359,
            55,
            100,
            45,
            65
        );
        HSL memory BGEnd = generateHSLColor(
            string(abi.encodePacked(seed, "BG_END")),
            0,
            359,
            BGStart.saturation,
            BGStart.saturation,
            BGStart.lightness,
            BGStart.lightness
        );

        return
            MainframeColors(
                Color(toHSLString(lightStart), toHSLString(lightEnd)),
                Color(toHSLString(mediumStart), toHSLString(mediumEnd)),
                Color(toHSLString(darkStart), toHSLString(darkEnd)),
                Color(toHSLString(BGStart), toHSLString(BGEnd))
            );
    }
}
