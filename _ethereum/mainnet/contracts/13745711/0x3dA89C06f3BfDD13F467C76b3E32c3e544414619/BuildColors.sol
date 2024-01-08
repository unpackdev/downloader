//SPDX-License-Identifier: CC-BY-SA-4.0

import "./Strings.sol";
import "./Ownable.sol";

contract BuildColors is Ownable {
    using Strings for uint256;

    constructor() Ownable() {}

    function buildColorString(
        uint32 colorR,
        uint32 colorG,
        uint32 colorB
    ) pure internal returns (string memory) {
        return string(abi.encodePacked(
                'rgb(',
                Strings.toString(colorR),
                ',',
                Strings.toString(colorG),
                ',',
                Strings.toString(colorB),
                ')'
            ));
    }

    function buildSCColorString(
        uint32 colorR,
        uint32 colorG,
        uint32 colorB
    ) pure internal returns (string memory) {
        // TOO DARK, lighter
        if (
            colorR >= 127 &&
            colorG >= 127 &&
            colorB >= 127
        ) {
            colorR = colorR / 3;
            colorG = colorG / 3;
            colorB = colorB / 3;
        }

        // TOO light, darker
        if (
            colorR < 127 &&
            colorG < 127 &&
            colorB < 127
        ) {
            colorR = (255 - colorR) / 3;
            colorG = (255 - colorG) / 3;
            colorB = (255 - colorB) / 3;
        }

        return string(abi.encodePacked(
                'rgb(',
                Strings.toString(colorR),
                ',',
                Strings.toString(colorG),
                ',',
                Strings.toString(colorB),
                ')'
            ));
    }

    function buildXTextPosition(
        uint32 positionX,
        uint32 positionY
    ) pure internal returns (string memory) {
        return positionX > 65 && positionY > 70 ? Strings.toString(96) : Strings.toString(96);
    }

    function buildYTextPosition(
        uint32 positionX,
        uint32 positionY
    ) pure internal returns (string memory) {
        return positionX > 65 && positionY > 70 ? Strings.toString(8) : Strings.toString(94);
    }

    function buildSVG(
        uint32 colorR,
        uint32 colorG,
        uint32 colorB,
        uint32 positionX,
        uint32 positionY
    ) external onlyOwner returns (string memory) {

        return string(abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" x="0px" y="0px" preserveAspectRatio="xMinYMin meet" viewBox="0 0 100 100"><rect x="0" y="0" width="100" height="100" fill="',
                buildColorString(
                    colorR,
                    colorG,
                    colorB
                ),
                '"/><rect x="',
                Strings.toString(positionX),
                '" y="',
                Strings.toString(positionY),
                '" width="1" height="1" fill="',
                buildSCColorString(
                    colorG,
                    colorB,
                    colorR
                ),
                '"/><text id="coordsText" text-anchor="end" dominant-baseline="middle" transform="matrix(0.5 0 0 0.5 ',
                buildXTextPosition(positionX, positionY),
                ' ',
                buildYTextPosition(positionX, positionY),
                ')" fill="',
                buildSCColorString(
                    colorG,
                    colorB,
                    colorR
                ),
                '">',
                Strings.toString(positionX),
                ':',
                Strings.toString(positionY),
                '</text></svg>'
            ));
    }

}
