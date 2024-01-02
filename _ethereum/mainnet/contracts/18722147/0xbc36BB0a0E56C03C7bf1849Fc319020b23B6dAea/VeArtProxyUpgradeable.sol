// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Base64.sol";
import "./IVeArtProxy.sol";

import "./OwnableUpgradeable.sol";

contract VeArtProxyUpgradeable is IVeArtProxy, OwnableUpgradeable {


    constructor() {}

    function initialize() initializer public {
        __Ownable_init();
    }


    function toString(uint value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function decimalString(
        uint256 number,
        uint8 decimals,
        bool isPercent
    ) private pure returns (string memory) {
        uint8 percentBufferOffset = isPercent ? 1 : 0;
        uint256 tenPowDecimals = 10 ** decimals;

        uint256 temp = number;
        uint8 digits;
        uint8 numSigfigs;
        while (temp != 0) {
            if (numSigfigs > 0) {
                // count all digits preceding least significant figure
                numSigfigs++;
            } else if (temp % 10 != 0) {
                numSigfigs++;
            }
            digits++;
            temp /= 10;
        }

        DecimalStringParams memory params;
        params.isPercent = isPercent;
        if ((digits - numSigfigs) >= decimals) {
            // no decimals, ensure we preserve all trailing zeros
            params.sigfigs = number / tenPowDecimals;
            params.sigfigIndex = digits - decimals;
            params.bufferLength = params.sigfigIndex + percentBufferOffset;
        } else {
            // chop all trailing zeros for numbers with decimals
            params.sigfigs = number / (10 ** (digits - numSigfigs));
            if (tenPowDecimals > number) {
                // number is less tahn one
                // in this case, there may be leading zeros after the decimal place
                // that need to be added

                // offset leading zeros by two to account for leading '0.'
                params.zerosStartIndex = 2;
                params.zerosEndIndex = decimals - digits + 2;
                params.sigfigIndex = numSigfigs + params.zerosEndIndex;
                params.bufferLength = params.sigfigIndex + percentBufferOffset;
                params.isLessThanOne = true;
            } else {
                // In this case, there are digits before and
                // after the decimal place
                params.sigfigIndex = numSigfigs + 1;
                params.decimalIndex = digits - decimals + 1;
            }
        }
        params.bufferLength = params.sigfigIndex + percentBufferOffset;
        return generateDecimalString(params);
    }

    struct DecimalStringParams {
        // significant figures of decimal
        uint256 sigfigs;
        // length of decimal string
        uint8 bufferLength;
        // ending index for significant figures (funtion works backwards when copying sigfigs)
        uint8 sigfigIndex;
        // index of decimal place (0 if no decimal)
        uint8 decimalIndex;
        // start index for trailing/leading 0's for very small/large numbers
        uint8 zerosStartIndex;
        // end index for trailing/leading 0's for very small/large numbers
        uint8 zerosEndIndex;
        // true if decimal number is less than one
        bool isLessThanOne;
        // true if string should include "%"
        bool isPercent;
    }

    function generateDecimalString(
        DecimalStringParams memory params
    ) private pure returns (string memory) {
        bytes memory buffer = new bytes(params.bufferLength);
        if (params.isPercent) {
            buffer[buffer.length - 1] = "%";
        }
        if (params.isLessThanOne) {
            buffer[0] = "0";
            buffer[1] = ".";
        }

        // add leading/trailing 0's
        for (
            uint256 zerosCursor = params.zerosStartIndex;
            zerosCursor < params.zerosEndIndex;
            zerosCursor++
        ) {
            buffer[zerosCursor] = bytes1(uint8(48));
        }
        // add sigfigs
        while (params.sigfigs > 0) {
            if (
                params.decimalIndex > 0 &&
                params.sigfigIndex == params.decimalIndex
            ) {
                buffer[--params.sigfigIndex] = ".";
            }
            buffer[--params.sigfigIndex] = bytes1(
                uint8(uint256(48) + (params.sigfigs % 10))
            );
            params.sigfigs /= 10;
        }
        return string(buffer);
    }

    function _tokenURI(
        uint256 _tokenId,
        uint256 _balanceOf,
        uint256 _locked_end,
        uint256 _value
    ) external view returns (string memory output) {
        output = '<svg version="1.2" baseProfile="tiny" id="coin_1_" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 1920 1920" overflow="visible" xml:space="preserve"><linearGradient id="SVGID_1_" gradientUnits="userSpaceOnUse" x1="0" y1="960" x2="1920" y2="960"><stop  offset="4.848288e-07" style="stop-color:#383538"/><stop  offset="1" style="stop-color:#000000"/></linearGradient><rect fill="url(#SVGID_1_)" width="1920" height="1920"/><g id="orange_rectangles"><rect x="108.38" y="611.47" fill="#C97800" width="183.11" height="3.62"/><rect x="290.91" y="1164.54" fill="#C97800" width="225" height="3.62"/><rect x="1391.61" y="896.73" fill="#C97800" width="183.11" height="3.62"/><rect x="1034.49" y="108.98" fill="#C97800" width="300" height="3.62"/><rect x="115.83" y="148.57" fill="#C97800" width="300" height="3.62"/><rect x="1544.86" y="1287.68" fill="#C97800" width="175" height="3.62"/><rect x="273.27" y="634.42" fill="#FFFFFF" width="120" height="3.62"/><rect x="1502.43" y="210.72" fill="#FFFFFF" width="120" height="3.62"/><rect x="1255.74" y="1263.09" fill="#FFFFFF" width="300" height="3.62"/><rect x="199.81" y="1182.49" fill="#FFFFFF" width="120" height="3.62"/></g><g id="static_blocks"><rect x="110.43" y="968.15" fill="#625B63" width="64.91" height="13.89"/><rect x="183.64" y="968.15" fill="#625B63" width="19.17" height="13.89"/><rect x="216.7" y="968.15" fill="#625B63" width="37.31" height="13.89"/><rect x="277.6" y="968.15" fill="#625B63" width="13.89" height="13.89"/><rect x="79.34" y="982.04" fill="#625B63" width="64.91" height="13.89"/><rect x="236.51" y="982.04" fill="#625B63" width="46.6" height="13.89"/><rect x="298.04" y="982.04" fill="#625B63" width="26.38" height="13.89"/><rect x="202.81" y="982.04" fill="#625B63" width="13.89" height="13.89"/><rect x="144.25" y="518.94" fill="#625B63" width="147.24" height="21.89"/><rect x="313.96" y="518.94" fill="#625B63" width="41.74" height="21.89"/><rect x="391.91" y="518.94" fill="#625B63" width="51.99" height="21.89"/><rect x="467.6" y="518.94" fill="#625B63" width="21.89" height="21.89"/><rect x="183.64" y="540.83" fill="#625B63" width="70.37" height="21.89"/><rect x="443.9" y="540.83" fill="#625B63" width="23.7" height="21.89"/><rect x="488.4" y="540.83" fill="#625B63" width="91.37" height="21.89"/><rect x="291.49" y="540.83" fill="#625B63" width="83.56" height="21.89"/><rect x="1631.07" y="161.32" fill="#625B63" width="91.37" height="21.89"/><rect x="1434.16" y="161.32" fill="#625B63" width="83.56" height="21.89"/><rect x="1373.41" y="960.15" fill="#625B63" width="147.24" height="21.89"/><rect x="1543.12" y="960.15" fill="#625B63" width="41.74" height="21.89"/><rect x="1621.07" y="960.15" fill="#625B63" width="51.99" height="21.89"/><rect x="1696.76" y="960.15" fill="#625B63" width="21.89" height="21.89"/><rect x="1412.8" y="982.04" fill="#625B63" width="70.37" height="21.89"/><rect x="1673.06" y="982.04" fill="#625B63" width="23.7" height="21.89"/><rect x="1717.56" y="982.04" fill="#625B63" width="91.37" height="21.89"/><rect x="1520.65" y="982.04" fill="#625B63" width="83.56" height="21.89"/><rect x="1286.92" y="139.43" fill="#625B63" width="147.24" height="21.89"/><rect x="1456.63" y="139.43" fill="#625B63" width="41.74" height="21.89"/><rect x="1534.58" y="139.43" fill="#625B63" width="51.99" height="21.89"/><rect x="1610.27" y="139.43" fill="#625B63" width="21.89" height="21.89"/><rect x="1326.31" y="161.32" fill="#625B63" width="70.37" height="21.89"/><rect x="1586.57" y="161.32" fill="#625B63" width="23.7" height="21.89"/><rect x="1631" y="651.5" fill="#625B63" width="64.91" height="13.89"/><rect x="1704.2" y="651.5" fill="#625B63" width="19.17" height="13.89"/><rect x="1737.26" y="651.5" fill="#625B63" width="37.31" height="13.89"/><rect x="1798.17" y="651.5" fill="#625B63" width="13.89" height="13.89"/><rect x="1599.9" y="665.39" fill="#625B63" width="64.91" height="13.89"/><rect x="1757.08" y="665.39" fill="#625B63" width="46.6" height="13.89"/><rect x="1818.6" y="665.39" fill="#625B63" width="26.38" height="13.89"/><rect x="1723.37" y="665.39" fill="#625B63" width="13.89" height="13.89"/><rect x="290.91" y="169.32" fill="#625B63" width="64.91" height="13.89"/><rect x="364.12" y="169.32" fill="#625B63" width="19.17" height="13.89"/><rect x="397.17" y="169.32" fill="#625B63" width="37.31" height="13.89"/><rect x="458.08" y="169.32" fill="#625B63" width="13.89" height="13.89"/><rect x="259.81" y="183.21" fill="#625B63" width="64.91" height="13.89"/><rect x="416.99" y="183.21" fill="#625B63" width="46.6" height="13.89"/><rect x="478.51" y="183.21" fill="#625B63" width="26.38" height="13.89"/><rect x="383.28" y="183.21" fill="#625B63" width="13.89" height="13.89"/></g><g id="Layer_1_xA0_Image_1_"><polygon fill="#B74100" points="579.55,1248.43 579.55,1277.19 632.98,1334 630.02,1241.36 "/><linearGradient id="yellow_coin_1_" gradientUnits="userSpaceOnUse" x1="492.1509" y1="731" x2="1477" y2="731"><stop  offset="4.795011e-07" style="stop-color:#EF7D00"/><stop offset="0.5" style="stop-color:#F4C400"/><stop offset="1" style="stop-color:#EF7D00"/></linearGradient><polyline id="yellow_coin" fill="url(#yellow_coin_1_)" points="535.4,1255.85 629.81,1241.81 633,1334 1382.64,1204.45 1383.55,1129.51 1444.45,1120.45 1477,326.42 1412.08,319.85 1415.02,233.81 592.68,128 596.3,237.43 492.15,228.38"/><polyline fill="#B74100" points="443.9,267.67 443.9,267.67 492.1,228.3 535.6,1255.85 487.78,1206.52 443.9,267.67"/><polygon fill="#B74100" points="539.47,173.13 540.6,232.68 595.85,237.21 592.91,129.21"/></g><linearGradient id="inside_gradient_1_" gradientUnits="userSpaceOnUse" x1="701.7358" y1="743.9245" x2="1341.2075" y2="743.9245"><stop offset="0" style="stop-color:#993A00"/><stop offset="0.5" style="stop-color:#F4A700"/><stop offset="1" style="stop-color:#993A00"/></linearGradient><polygon id="inside_gradient" fill="url(#inside_gradient_1_)" points="1274.3,397.28 793.96,362.11 794.72,462.34 701.74,458.72 716.38,1044.83 804.83,1036.38 806.34,1125.74 1259.36,1070.3 1260.49,989.92 1327.28,983.92 1341.21,488.75 1272.49,485.92"/><path id="R_shadows_3_" fill="#B74216" d="M1223.55,784l-56.91-5.66c0,0-25.66,28.75-62.87,28.91s50.42,24.38,50.42,24.38l60.3-25.13L1223.55,784"/><path id="R_shadows_1_" fill="#B74216" d="M1062.04,641.66c0,0,32.15,15.85,32.15,45.89s-29.62,50.57-42.43,59.92c-12.81,9.36,57.53-1.21,57.53-1.21l34.87-42.72l-13.28-50.11l-30.79-17.21"/><polyline id="R_shadows" fill="#B74216" points="870,520 843.17,524.23 848,941.43 875.77,949.43 "/><path id="R_shadows_2_" fill="#B74216" d="M1005.77,815.58c0,0,45.96,121.13,120,110.04c74.04-11.09-18.91-29.32-18.91-29.32l-56.26-55.02l-27.96-63.62l-18.79,3.17L1005.77,815.58z"/><polygon id="inside_shadow" fill="#CB6A00" points="1237.4,1073.25 1237.4,984.83 1303.96,979 1314.15,491.36 1248.38,488.87 1249.17,395.92 1274.3,397.28 1272.49,485.92 1341.21,488.75 1327.28,983.92 1260.49,989.92 1259.36,1070.3 "/><path fill="#11100E" d="M1223.55,784c-80.6,71.55-141.89-6.34-141.89-6.34l7.25-11.77c82.11,8.75,143.7-24.75,143.4-119.25s-92.08-114.42-92.08-114.42L870,520l5.77,429.43l130.72-9.96L1008,784.6l10.26-1.21c71.25,226.42,215.25,131.62,215.25,131.62L1223.55,784z M1008,716.98v-71.85h86.64c40.75,16,29.28,51.32,29.28,51.32C1098.26,773.74,1008,716.98,1008,716.98z"/><g id="brackets"><polyline fill="none" stroke="#FFFFFF" stroke-miterlimit="10" points="211.47,51.95 46.08,51.95 46.08,1360 211.47,1360"/><polyline fill="none" stroke="#FFFFFF" stroke-miterlimit="10" points="1708.53,51.95 1873.92,51.95 1873.92,1360 1708.53,1360"/></g><text y="1440" x="50%" fill="white" dominant-baseline="middle" text-anchor="middle" class="vr" font-size="85px"> veBLUE #';

        uint256 duration = 0;
        if (_locked_end > block.timestamp) {
            duration = _locked_end - block.timestamp;
        }

        output = string(
            abi.encodePacked(
                output,
                decimalString(_tokenId, 0, false),
                '</text> <text font-size="80px" fill="white" y="1560" x="16" dominant-baseline="middle" class="label" > BLUE Locked: </text> <text font-size="80px" y="1560" fill="white" x="1870" dominant-baseline="middle" text-anchor="end" class="amount" >',
                decimalString(_value / 1e16, 2, false),
                '</text> <text font-size="80px" fill="white" y="1680" x="16" dominant-baseline="middle" class="label"> veBLUE Power: </text> <text font-size="80px" fill="white" y="1680" x="1870" dominant-baseline="middle" text-anchor="end" class="amount">',
                decimalString(_balanceOf / 1e16, 2, false),
                '</text> <text font-size="80px"  fill="white" y="1800" x="16" dominant-baseline="middle" class="label" > Expires: </text> <text font-size="80px" fill="white" y="1800" x="1870" dominant-baseline="middle" text-anchor="end" class="amount" >',
                decimalString(duration / 8640, 1, false),
                ' days </text> <text fill="white" y="1858" x="50%" font-size="45px" dominant-baseline="middle" text-anchor="middle" class="app" > Blue.Finance </text></svg>'
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "lock #',
                        decimalString(_tokenId, 0, false),
                        '", "description": "Blue locks, can be used to boost gauge yields, vote on token emissions, and receive bribes", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );

        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
    }
}

