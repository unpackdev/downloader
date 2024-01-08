// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SVG.sol";
import "./ICloudTraits.sol";

/// @title CloudFormation
library CloudFormation {

    using Strings for uint256;

    /// @dev Length of the image side -- used as a constant throughout to eliminate parameters and reduce contract size
    uint private constant SIDE = 1000;

    /// Creates the SVG for a CloudCollective Cloud based on its ICloudTraits.Forecast and Token Id
    function createSvg(ICloudTraits.Forecast memory forecast, uint256 tokenId) internal pure returns (bytes memory) {
        return SVG.createElement("svg", abi.encodePacked(" width='1000' height='1000'", SVG.svgAttributes(SIDE, SIDE), " xlink='http://www.w3.org/1999/xlink'"), abi.encodePacked(
            _defElement(forecast),
            SVG.createElement("g", " clip-path='url(#clip)'", abi.encodePacked(
                _rectElement(100, 100, " fill='url(#backgroundGradient)'"),
                _groupForClouds(forecast, tokenId),
                SVG.createElement("g", abi.encodePacked(" style='mix-blend-mode: overlay'"), _rectElement(100, 100, " filter='url(#noise)'"))
            ))
        ));
    }

    /// Returns the start color gradient of a Cloud
    function conditionColor(ICloudTraits.Condition condition, uint200 chaos, uint256 tokenId) internal pure returns (ISVGTypes.Color memory) {
        bytes25 source = bytes25(chaos);
        uint256 increment = tokenId % 23; // We use 3 bytes at a time
        return SVG.randomizeColors(
            _colorStart(condition),
            _colorStop(condition),
            ISVGTypes.Color(uint8(source[increment]), uint8(source[increment+1]), uint8(source[increment+2]), 0xFF)
        );
    }

    function _cloudPuff(uint256 cx, uint256 cy, uint256 r, bytes1 source) private pure returns (bytes memory) {
        uint256 wR = r * (98 + (uint8(source) % 5)) / 100;
        return abi.encodePacked(
            "<circle cx='", cx.toString(), "' cy='", cy.toString(), "' r='", wR.toString(), "' fill='url(#circleGradient)'/>"
        );
    }

    function _cloudPuffs(ICloudTraits.Forecast memory forecast, uint256 tokenId) private pure returns (bytes memory) {
        bytes18 source = bytes18(uint144(forecast.chaos >> (tokenId % 50)));
        if (forecast.formation == ICloudTraits.Formation.A) {
            return abi.encodePacked(
                _cloudPuff(500, 471, 105, source[17]),
                _cloudPuff(405, 516, 80, source[16]),
                _cloudPuff(595, 516, 80, source[15]),
                _cloudPuff(500, 566, 67, source[14])
            );
        } else if (forecast.formation == ICloudTraits.Formation.B) {
            return abi.encodePacked(
                _cloudPuff(296, 500, 42, source[17]),
                _cloudPuff(651, 448, 66, source[16]),
                _cloudPuff(555, 451, 80, source[15]),
                _cloudPuff(475, 505, 57, source[14]),
                _cloudPuff(669, 522, 77, source[13]),
                _cloudPuff(563, 557, 72, source[12])
            );
        } else if (forecast.formation == ICloudTraits.Formation.C) {
            return abi.encodePacked(
                _cloudPuff(445, 435, 60, source[17]),
                _cloudPuff(534, 442, 76, source[16]),
                _cloudPuff(407, 509, 82, source[15]),
                _cloudPuff(598, 514, 77, source[14]),
                _cloudPuff(501, 551, 82, source[13])
            );
        } if (forecast.formation == ICloudTraits.Formation.D) {
            return abi.encodePacked(
                _cloudPuff(688, 509, 46, source[17]),
                _cloudPuff(444, 469, 98, source[16]),
                _cloudPuff(345, 510, 79, source[15]),
                _cloudPuff(535, 510, 63, source[14]),
                _cloudPuff(444, 554, 62, source[13])
            );
        } else /* if (forecast.formation == ICloudTraits.Formation.E) */ {
            return abi.encodePacked(
                _cloudPuff(475, 463, 94, source[17]),
                _cloudPuff(583, 504, 92, source[16]),
                _cloudPuff(389, 504, 63, source[15]),
                _cloudPuff(482, 558, 74, source[14])
            );
        }
    }

    function _colorStart(ICloudTraits.Condition condition) private pure returns (ISVGTypes.Color memory) {
        if (condition == ICloudTraits.Condition.Luminous) {
            return SVG.fromPackedColor(0xC2DDF8);
        } else if (condition == ICloudTraits.Condition.Overcast) {
            return SVG.fromPackedColor(0x666666);
        } else if (condition == ICloudTraits.Condition.Stormy) {
            return SVG.fromPackedColor(0x0E4178);
        } else if (condition == ICloudTraits.Condition.Golden) {
            return SVG.fromPackedColor(0xFFDA7A);
        } // Magic
        return SVG.fromPackedColor(0x8D00B0);
    }

    function _colorStop(ICloudTraits.Condition condition) private pure returns (ISVGTypes.Color memory) {
        if (condition == ICloudTraits.Condition.Luminous) {
            return SVG.fromPackedColor(0x89C0F7);
        } else if (condition == ICloudTraits.Condition.Overcast) {
            return SVG.fromPackedColor(0x333333);
        } else if (condition == ICloudTraits.Condition.Stormy) {
            return SVG.fromPackedColor(0x060F2D);
        } else if (condition == ICloudTraits.Condition.Golden) {
            return SVG.fromPackedColor(0xFFB905);
        } // Magic
        return SVG.fromPackedColor(0x8D00B0);
    }

    function _colorMatrix(ICloudTraits.Condition condition) private pure returns (bytes memory) {
        (bytes12 first3, bytes11 last) = condition == ICloudTraits.Condition.Golden ||
                                         condition == ICloudTraits.Condition.Luminous ?
                                         (bytes12("0.8 0 0 0 0 "), bytes11("0 0 0 1.0 0")) :
                                         (bytes12("0.4 0 0 0 0 "), bytes11("0 0 0 2.0 0"));
        return abi.encodePacked("<feColorMatrix values='", first3, first3, first3, last, "' type='matrix'/>");
    }

    function _defElement(ICloudTraits.Forecast memory forecast) private pure returns (bytes memory) {
        return SVG.createElement("defs", "", abi.encodePacked(
            _gradientElements(forecast),
            SVG.createElement("filter", " id='noise'", abi.encodePacked(
                "<feImage x='0' y='0' href='", OnChain.svgImageURI(_noiseSVG(forecast.condition)), "' width='1350' height='1350'/>"
            )),
            SVG.createElement("clipPath", " id='clip'", _rectElement(100, 100, ""))
        ));
    }

    function _gradientElements(ICloudTraits.Forecast memory forecast) private pure returns (bytes memory) {
        string memory linearGradient = "linearGradient";
        bytes memory stopColorElements = _stopColorElements(forecast);
        return abi.encodePacked(
            SVG.createElement(linearGradient, _linearGradientAttributes("backgroundGradient"), stopColorElements),
            SVG.createElement(linearGradient, _puffGradientAttributes("circleGradient", forecast.mirrored), stopColorElements)
        );
    }

    function _groupForClouds(ICloudTraits.Forecast memory forecast, uint256 tokenId) private pure returns (bytes memory) {
        return SVG.createElement("g", _transformAttributes(forecast), _cloudPuffs(forecast, tokenId));
    }

    function _linearGradientAttributes(string memory name) private pure returns (bytes memory) {
        return abi.encodePacked(" id='", name, "' x1='0' y1='1' x2='1' y2='0'");
    }

    function _noiseSVG(ICloudTraits.Condition condition) private pure returns (bytes memory) {
        return SVG.createElement(
            "svg", abi.encodePacked(" width='", (2*SIDE).toString(), "' height='", (2*SIDE).toString(), "' xmlns='http://www.w3.org/2000/svg'"),
                abi.encodePacked(
                    SVG.createElement("defs", "", SVG.createElement(
                        "filter", " id='noise'", abi.encodePacked("<feTurbulence type='fractalNoise' numOctaves='1' baseFrequency='0.75' stitchTiles='stitch'/>", _colorMatrix(condition))
                    )),
                    _rectElement(100, 100, " filter='url(#noise)'")
                )
        );
    }

    function _puffGradientAttributes(string memory name, bool mirrored) private pure returns (bytes memory) {
        return abi.encodePacked(" y1='0.63' y2='0.115' id='", name, mirrored ? "' x1='0.59' x2='0.153'" : "' x1='0.41' x2='0.847'");
    }

    function _rectElement(uint256 widthPercentage, uint256 heightPercentage, bytes memory attributes) private pure returns (bytes memory) {
        return abi.encodePacked("<rect width='", widthPercentage.toString(), "%' height='", heightPercentage.toString(), "%'", attributes, "/>");
    }

    function _stopColorElement(ISVGTypes.Color memory color, uint256 offset) private pure returns (bytes memory) {
        bytes memory attributes = abi.encodePacked(SVG.colorAttribute(ISVGTypes.ColorAttribute.Stop, SVG.colorAttributeRGBValue(color)), " offset='", offset.toString(), "%'");
        return SVG.createElement("stop", attributes, "");
    }

    function _stopColorElements(ICloudTraits.Forecast memory forecast) private pure returns (bytes memory) {
        return abi.encodePacked(
            _stopColorElement(forecast.color, 0),
            forecast.condition == ICloudTraits.Condition.Magic ? _stopColorElement(SVG.fromPackedColor(0xFF54C3), 50) : bytes(""),
            _stopColorElement(SVG.fromPackedColor(0xFFFFFF), 95)
        );
    }

    function _transformAttributes(ICloudTraits.Forecast memory forecast) private pure returns (bytes memory) {
        (bytes memory scale, bytes memory translation) = _transforms(forecast);
        return abi.encodePacked(" transform='translate(", translation, "),scale(", scale, ")'");
    }

    function _transforms(ICloudTraits.Forecast memory forecast) private pure returns (bytes memory scale, bytes memory translation) {

        bytes3[7] memory scales = [bytes3("0.5"), "0.6", "0.7", "0.8", "0.9", "1.0", "4.3"];
        bytes3 themeScale = bytes3(scales[uint256(forecast.scale)]);
        scale = forecast.mirrored ? abi.encodePacked("-", themeScale, ",", themeScale) : abi.encodePacked(themeScale);

        if (forecast.scale == ICloudTraits.Scale.Monstre) {
            uint16[5] memory xTranslations = [1650, 773, 1645, 1290, 1651];
            uint256 xTranslationValue = xTranslations[uint256(forecast.formation)];
            if (forecast.mirrored) {
                xTranslationValue += SIDE;
            }
            uint16[5] memory yTranslations = [1400, 1650, 1325, 1395, 1395];
            translation = abi.encodePacked(forecast.mirrored ? "" : "-", xTranslationValue.toString(), ",-", uint256(yTranslations[uint256(forecast.formation)]).toString());
        } else { // non-Monstre non-mirrored translation = (1 - scale) * 500
            uint8[6] memory translations = [250, 200, 150, 100, 50, 0];
            uint256 translationValue = translations[uint256(forecast.scale)];
            translation = abi.encodePacked(translationValue.toString());
            if (forecast.mirrored) {
                translationValue = SIDE - translationValue;
            }
            translation = abi.encodePacked(translationValue.toString(), ",", translation);
        }
    }
}
