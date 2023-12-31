// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

//import "./Strings.sol";
//import "./BitMath.sol";
import "./Strings.sol";
import "./HexStrings.sol";

/// @title NFTSVG
/// @notice Provides a function for generating an SVG associated with a Uniswap NFT
library NFTSVG {
    struct SVGParams {
        uint256 rotation;

        string angel1;
        string angel2;
        string angel3;
        string angel4;
        string angel5;
        string angel6;
        string colorPolygon1;
        string colorPolygon2;
        string colorPolygon3;
        string colorPolygon4;
        string colorPolygon5;
        string colorPolygon6;

        string colorOBCircle1;
        string colorOBCircle2;
        string colorOBCircle3;

        string colorOBDynamic;
    }

    function parseParams(string[20] memory hexArray) internal pure returns (SVGParams memory params) {
        params.rotation = HexStrings.fromHex2(hexArray[0]);

        params.angel1 = "0";
        params.angel2 = "60";
        params.angel3 = "120";
        params.angel4 = "180";
        params.angel5 = "240";
        params.angel6 = "300";

        params.colorPolygon1 = string(abi.encodePacked(hexArray[1], hexArray[2], hexArray[3]));
        params.colorPolygon2 = string(abi.encodePacked(hexArray[4], hexArray[5], hexArray[6]));
        params.colorPolygon3 = string(abi.encodePacked(hexArray[7], hexArray[8], hexArray[9]));
        params.colorPolygon4 = string(abi.encodePacked(hexArray[10], hexArray[11], hexArray[12]));
        params.colorPolygon5 = string(abi.encodePacked(hexArray[13], hexArray[14], hexArray[15]));
        params.colorPolygon6 = string(abi.encodePacked(hexArray[16], hexArray[17], hexArray[18]));

        params.colorOBCircle1 = string(abi.encodePacked(hexArray[0], hexArray[7], hexArray[9]));
        params.colorOBCircle2 = string(abi.encodePacked(hexArray[11], hexArray[15], hexArray[19]));
        params.colorOBCircle3 = string(abi.encodePacked(hexArray[0], hexArray[2], hexArray[10], hexArray[18]));

        params.colorOBDynamic = string(abi.encodePacked(hexArray[17], hexArray[18], hexArray[19]));
    }

    function gengrateMainGroup(SVGParams memory params) internal pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<g transform="rotate(', Strings.toString(params.rotation), ',160,160) translate(160 160)">',
                '<use href="#polygon_60deg_75_ethereum" fill="#', params.colorPolygon1, '" transform="rotate(', params.angel1, ',0,0)"></use>',
                '<use href="#polygon_60deg_75_ethereum" fill="#', params.colorPolygon2, '" transform="rotate(', params.angel2, ',0,0)"></use>',
                '<use href="#polygon_60deg_75_ethereum" fill="#', params.colorPolygon3, '" transform="rotate(', params.angel3, ',0,0)"></use>',
                '<use href="#polygon_60deg_75_ethereum" fill="#', params.colorPolygon4, '" transform="rotate(', params.angel4, ',0,0)"></use>',
                '<use href="#polygon_60deg_75_ethereum" fill="#', params.colorPolygon5, '" transform="rotate(', params.angel5, ',0,0)"></use>',
                '<use href="#polygon_60deg_75_ethereum" fill="#', params.colorPolygon6, '" transform="rotate(', params.angel6, ',0,0)"></use>',
                '</g>'
            )
        );
    }

    function gengrateSVG(string[20] memory hexArray) internal pure returns (string memory svg) {
        SVGParams memory params = parseParams(hexArray);

        svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" fill="none" viewBox="0 0 320 320">',
                '<defs>',
                '<path id="circleOutbounding_ethereum" d="M 0 0 m 129.9038105676658, 0 a 129.9038105676658,129.9038105676658 0 1,0 -259.8076211353316,0 a 129.9038105676658,129.9038105676658 0 1,0 259.8076211353316,0"></path>',
                '<path id="polygon_60deg_75_ethereum" d="M0,0 -37.5,-64.9519052838329 0,-129.9038105676658 37.5,-64.9519052838329z"></path>',
                '</defs><g transform="translate(160 160)"><g>',
                '<circle cx="0" cy="-129.9038105676658" r="3" fill="#', params.colorOBCircle1, '"><animate attributeName="opacity" attributeType="XML" begin="1s" dur="7s" keyTimes="0;0.5;1" repeatCount="indefinite" type="rotate" values="1;0;1" calcMode="linear"></animate></circle>',
                '<circle cx="112.50000000000001" cy="64.95190528383287" r="9" stroke="#', params.colorOBCircle2, '" stroke-width="2"><animate attributeName="opacity" attributeType="XML" begin="0s" dur="12s" keyTimes="0;0.5;1" repeatCount="indefinite" type="rotate" values="1;0;1" calcMode="linear"></animate></circle>',
                '<circle cx="-112.49999999999997" cy="64.95190528383296" r="6" fill="#', params.colorOBCircle3, '"><animate attributeName="opacity" attributeType="XML" begin="2s" dur="5s" keyTimes="0;0.5;1" repeatCount="indefinite" type="rotate" values="1;0;1" calcMode="linear"></animate></circle>',
                '<animateTransform attributeName="transform" attributeType="XML" dur="7s" keyTimes="0;0.25;0.5;0.75;1" repeatCount="indefinite" type="rotate" values="0;90;180;270;360" calcMode="linear"></animateTransform>',
                '</g></g>',
                '<use href="#circleOutbounding_ethereum" transform="translate(160 160) scale(1.3 1.3)" stroke="#', params.colorOBDynamic, '49" stroke-width="1">',
                '<animateTransform attributeName="transform" type="scale" additive="sum" from="0 0" to="1 1" beg="0s" dur="1.2s" repeatCount="indefinite"></animateTransform>',
                '</use>',
                gengrateMainGroup(params),
                '</svg>'
            )
        );
    }

}