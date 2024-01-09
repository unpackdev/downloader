
// SPDX-License-Identifier: MIT

// Initial structure and some code copied from Loot - MIT license
// https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7#code#L1

pragma solidity 0.8.11;

contract MimicMeta {

    address aMimic;
    address aShield;

    string constant COLOR = "COLORS";
    string constant EYE = "EYE";
    string constant MOUTH = "MOUTH";
    string constant TOOTH = "TOOTH";

    string[] private colors = [
        "#abffbc", // forest
        "#abffbc",
        "#abffbc",
        "#abffbc",
        "#abffbc",
        "#abfff5", // sky
        "#abfff5",
        "#abfff5",
        "#abfff5",
        "#abfff5",
        "#aaddff", // sea
        "#aaddff",
        "#aaddff",
        "#aaddff",
        "#aaddff",
        "#abb2ff", // lavender
        "#abb2ff",
        "#abb2ff",
        "#abb2ff",
        "#abb2ff",
        "#ffa8a8", // clay
        "#ffa8a8",
        "#ffa8a8",
        "#ffa8a8",
        "#ffa8a8",
        "#ffd2aa", // wheat
        "#ffd2aa",
        "#ffd2aa",
        "#ffd2aa",
        "#ffd2aa",
        "#ffaafa", // pink
        "#ffaafa",
        "#ffaafa",
        "#ffaafa",
        "#ffaafa",
        "#f72585", // cyber pink
        "#f72585",
        "#a025f7", // cyber purple
        "#a025f7",
        "#2538f7", // cyber blue
        "#2538f7",
        "#f5f725", // cyber yellow
        "#f5f725",
        "#27fb6b", // cyber green
        "#27fb6b",
        "#f51000", // cyber red
        "#f51000",
        "#edc531", // gold
        "#dee2e6", // silver
        "#33333a"  // shadow
    ];

    string[] private eyes = [
        "0", // 0
        "0",
        "0",
        "0",
        "0",
        "0",
        "O", // O
        "O",
        "O",
        "O",
        "O",
        "O",
        "^", // ^
        "^",
        "^",
        "^",
        "^",
        "^",
        "'", // '
        "'",
        "'",
        "'",
        "'",
        "'",
        "~", // ~
        "~",
        "~",
        "~",
        "~",
        "~",
        "-", // -
        "-",
        "-",
        "-",
        "-",
        "-",
        "o", // o
        "o",
        "o",
        "o",
        "o",
        "o",
        "#", // #
        "@", // @
        "$"  // $
    ];

    string[] private left_mouths = [
        "[",  // [
        "[",
        "(",  // (
        "(",
        "{",  // {
        "{",
        "\\", // \
        ":"   // :
    ];

    string[] private right_mouths = [
        "]", // ]
        "]",
        ")", // }
        ")",
        "}", // }
        "}",
        "/", // /
        ":"  // :
    ];

    string[] private teeth = [
        "=",
        "_",
        "."
    ];

    function init(address _mimic, address _shield) external {
        require(aMimic == address(0x0));
        aMimic = _mimic;
        aShield = _shield;
    }

    function randomUS(uint256 input, string memory input2) internal pure returns (uint) {
        return uint256(keccak256(abi.encodePacked(input, input2)));
    }

    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns (string memory) {
        uint256 rand = randomUS(tokenId, keyPrefix);
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }

    ////
    // Mimic

    function mimicNative(uint256 _tokenId, string calldata _eye) external view returns (string memory output) {
        require(msg.sender == aMimic);
        string memory tidString = uintToString(_tokenId);
        string memory json = Base64.encodeNew(bytes(string(abi.encodePacked(
            '{',
                '"name": "Mimic #',
                    tidString,
                '",'
                '"description": "Mimic #',
                    tidString,
                    '\\n\\n'
                    'Mimics are mischeivous but honorable digital creatures that live deep within the ethereum blockchain.'
                    '\\n\\n'
                    'They are known to interact in interesting ways with other NFTs from throughout the ethereum ecosystem.'
                '",'
                '"image": "data:image/svg+xml;base64,',
                    Base64.encodeNew(bytes(imageFace(_tokenId, _eye))),
                '"'
            '}'
        ))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
    }

    function imageFace(uint256 _mimicId, string memory _eye) internal view returns (string memory) {
        string memory color = pluck(_mimicId, COLOR, colors);
        if (bytes(_eye).length == 0) {
            _eye = pluck(_mimicId, EYE, eyes);
        }
        string memory tooth = pluck(_mimicId, TOOTH, teeth);
        uint256 rand_mouth = randomUS(_mimicId, MOUTH) % left_mouths.length;

        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">'
                '<style>'
                    '.base { fill: ', color, '; font-family: monospace; text-anchor: middle; font-size: 80px; } '
                    '@keyframes glow { 0% { opacity: 0.2; } 3% { opacity: 0.9; } 30% { opacity: 0.2 } 70% {opacity: 0.9} } '
                    '.face { animation: glow 3s linear infinite alternate } '
                    '.f1 { animation-delay: 0.5s } '
                    '.f2 { animation-delay: 1.5s } '
                    '.f3 { animation-delay: 0.7s } '
                    '.f4 { animation-delay: 2.5s } '
                    '.f5 { animation-delay: 0.3s } '
                    '.f6 { animation-delay: 2.2s } '
                    '.d1 { animation-duration: 2.7s } '
                    '.d2 { animation-duration: 2.8s } '
                    '.d3 { animation-duration: 2.9s } '
                    '.d4 { animation-duration: 3.0s } '
                    '.d5 { animation-duration: 3.1s } '
                    '.d6 { animation-duration: 3.2s } '
                    '.d7 { animation-duration: 3.3s } '
                '</style>'
                '<rect width="100%" height="100%" fill="black" />'
                '<text x="100" y="130" class="base face f1 d1">',
                _eye,
                '</text>'
                '<text x="250" y="130" class="base face f2 d2">',
                _eye,
                '</text>'
                '<text x="100" y="260" class="base face f3 d3">',
                left_mouths[rand_mouth],
                '</text>'
                '<text x="150" y="260" class="base face f4 d4">',
                tooth,
                '</text>'
                '<text x="200" y="260" class="base face f5 d5">',
                tooth,
                '</text>'
                '<text x="250" y="260" class="base face f6 d6">',
                right_mouths[rand_mouth],
                '</text>'
                '<rect class="face d7" width="100%" height="100%" fill="#000000ee" />'
            '</svg>'
        ));
    }

    ////
    // Shield

    function shieldNative(uint256 _tokenId, bool _active) external view returns (string memory output) {
        require(msg.sender == aShield);
        string memory tidString = uintToString(_tokenId);
        string memory aura;
        if (_active) {
            aura = "Active";
        } else {
            aura = "Inactive";
        }
        string memory json = Base64.encodeNew(bytes(string(abi.encodePacked(
            '{',
                '"name": "Mimic Shield #',
                    tidString,
                '",'
                '"description": "Mimic Shield #',
                    tidString,
                    '\\n\\n'
                    'A Mimic Shield is the reified character of a mimic that has undertaken a sacred rite to become an adult.'
                    '\\n\\n'
                    "The aura of a shield is of great significance to mimics and their ritual practice."
                '",'
                '"attributes": [{ "trait_type": "Aura", "value": "',
                    aura,
                '"}],'
                '"image": "data:image/svg+xml;base64,',
                    Base64.encodeNew(bytes(imageShield(_tokenId, _active))),
                '"'
            '}'
        ))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
    }

    function imageShield(uint256 _mimicId, bool _active) internal view returns (string memory) {
        string memory color = pluck(_mimicId, COLOR, colors);
        string memory aura = shieldAura(_active);

        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">'
                '<style>'
                    '.base { fill: ', color, '; font-family: monospace; text-anchor: middle; font-size: 30px; }'
                    '@keyframes glow { 0% { opacity: 0.4; } 3% { opacity: 0.9; } 30% { opacity: 0.4 } 70% {opacity: 0.9} }'
                    '@keyframes rx {0% { transform: translateX(11px) } 2% { transform: translateX(83px) } 3% { transform: translateX(227px) } 4% { transform: translateX(19px) } 5% { transform: translateX(160px) } 6% { transform: translateX(252px) } 7% { transform: translateX(177px) } 8% { transform: translateX(64px) } 9% { transform: translateX(317px) } 10% { transform: translateX(192px) } 11% { transform: translateX(310px) } 12% { transform: translateX(92px) } 13% { transform: translateX(184px) } 14% { transform: translateX(248px) } 15% { transform: translateX(64px) } 16% { transform: translateX(205px) } 17% { transform: translateX(243px) } 18% { transform: translateX(11px) } 19% { transform: translateX(348px) } 20% { transform: translateX(232px) } 21% { transform: translateX(191px) } 22% { transform: translateX(313px) } 23% { transform: translateX(154px) } 24% { transform: translateX(4px) } 25% { transform: translateX(105px) } 26% { transform: translateX(140px) } 27% { transform: translateX(229px) } 28% { transform: translateX(262px) } 29% { transform: translateX(200px) } 30% { transform: translateX(107px) } 31% { transform: translateX(30px) } 32% { transform: translateX(193px) } 33% { transform: translateX(105px) } 34% { transform: translateX(222px) } 35% { transform: translateX(64px) } 36% { transform: translateX(285px) } 37% { transform: translateX(224px) } 38% { transform: translateX(96px) } 39% { transform: translateX(284px) } 40% { transform: translateX(32px) } 41% { transform: translateX(216px) } 42% { transform: translateX(273px) } 43% { transform: translateX(28px) } 44% { transform: translateX(6px) } 45% { transform: translateX(303px) } 46% { transform: translateX(177px) } 47% { transform: translateX(145px) } 48% { transform: translateX(103px) } 49% { transform: translateX(85px) } 50% { transform: translateX(342px) } 51% { transform: translateX(201px) } 52% { transform: translateX(321px) } 53% { transform: translateX(152px) } 54% { transform: translateX(204px) } 55% { transform: translateX(267px) } 56% { transform: translateX(19px) } 57% { transform: translateX(137px) } 58% { transform: translateX(1px) } 59% { transform: translateX(314px) } 60% { transform: translateX(174px) } 61% { transform: translateX(143px) } 62% { transform: translateX(132px) } 63% { transform: translateX(130px) } 64% { transform: translateX(219px) } 65% { transform: translateX(281px) } 66% { transform: translateX(272px) } 67% { transform: translateX(244px) } 68% { transform: translateX(311px) } 69% { transform: translateX(110px) } 70% { transform: translateX(59px) } 71% { transform: translateX(72px) } 72% { transform: translateX(285px) } 73% { transform: translateX(296px) } 74% { transform: translateX(319px) } 75% { transform: translateX(96px) } 76% { transform: translateX(192px) } 77% { transform: translateX(293px) } 78% { transform: translateX(26px) } 79% { transform: translateX(174px) } 80% { transform: translateX(246px) } 81% { transform: translateX(276px) } 82% { transform: translateX(255px) } 83% { transform: translateX(298px) } 84% { transform: translateX(137px) } 85% { transform: translateX(296px) } 86% { transform: translateX(112px) } 87% { transform: translateX(32px) } 88% { transform: translateX(66px) } 89% { transform: translateX(288px) } 90% { transform: translateX(76px) } 91% { transform: translateX(116px) } 92% { transform: translateX(158px) } 93% { transform: translateX(280px) } 94% { transform: translateX(161px) } 95% { transform: translateX(81px) } 96% { transform: translateX(260px) } 97% { transform: translateX(185px) } 98% { transform: translateX(213px) } 99% { transform: translateX(102px) } 100% { transform: translateX(160px) }}'
                    '@keyframes ry {0% { transform: translateY(41px) } 1% { transform: translateY(320px) } 2% { transform: translateY(239px) } 3% { transform: translateY(220px) } 4% { transform: translateY(158px) } 5% { transform: translateY(301px) } 6% { transform: translateY(335px) } 8% { transform: translateY(39px) } 9% { transform: translateY(171px) } 10% { transform: translateY(305px) } 11% { transform: translateY(148px) } 12% { transform: translateY(152px) } 13% { transform: translateY(168px) } 14% { transform: translateY(178px) } 15% { transform: translateY(57px) } 16% { transform: translateY(94px) } 17% { transform: translateY(307px) } 18% { transform: translateY(19px) } 19% { transform: translateY(249px) } 20% { transform: translateY(48px) } 21% { transform: translateY(332px) } 22% { transform: translateY(234px) } 23% { transform: translateY(302px) } 24% { transform: translateY(139px) } 25% { transform: translateY(255px) } 26% { transform: translateY(80px) } 27% { transform: translateY(184px) } 28% { transform: translateY(87px) } 29% { transform: translateY(337px) } 30% { transform: translateY(83px) } 31% { transform: translateY(204px) } 32% { transform: translateY(182px) } 33% { transform: translateY(348px) } 34% { transform: translateY(285px) } 35% { transform: translateY(273px) } 36% { transform: translateY(273px) } 37% { transform: translateY(99px) } 38% { transform: translateY(206px) } 39% { transform: translateY(217px) } 40% { transform: translateY(345px) } 41% { transform: translateY(329px) } 42% { transform: translateY(128px) } 43% { transform: translateY(61px) } 44% { transform: translateY(79px) } 45% { transform: translateY(302px) } 46% { transform: translateY(153px) } 47% { transform: translateY(98px) } 48% { transform: translateY(294px) } 49% { transform: translateY(189px) } 50% { transform: translateY(347px) } 51% { transform: translateY(20px) } 52% { transform: translateY(300px) } 53% { transform: translateY(216px) } 54% { transform: translateY(285px) } 55% { transform: translateY(72px) } 56% { transform: translateY(53px) } 57% { transform: translateY(178px) } 58% { transform: translateY(292px) } 59% { transform: translateY(340px) } 60% { transform: translateY(273px) } 61% { transform: translateY(197px) } 62% { transform: translateY(71px) } 63% { transform: translateY(279px) } 64% { transform: translateY(247px) } 65% { transform: translateY(120px) } 66% { transform: translateY(22px) } 67% { transform: translateY(20px) } 68% { transform: translateY(217px) } 69% { transform: translateY(12px) } 70% { transform: translateY(246px) } 71% { transform: translateY(219px) } 72% { transform: translateY(347px) } 73% { transform: translateY(252px) } 74% { transform: translateY(155px) } 75% { transform: translateY(290px) } 76% { transform: translateY(163px) } 77% { transform: translateY(132px) } 78% { transform: translateY(146px) } 79% { transform: translateY(121px) } 80% { transform: translateY(227px) } 81% { transform: translateY(189px) } 82% { transform: translateY(311px) } 83% { transform: translateY(243px) } 84% { transform: translateY(83px) } 85% { transform: translateY(59px) } 86% { transform: translateY(44px) } 87% { transform: translateY(75px) } 88% { transform: translateY(312px) } 89% { transform: translateY(161px) } 90% { transform: translateY(31px) } 91% { transform: translateY(310px) } 92% { transform: translateY(119px) } 93% { transform: translateY(292px) } 94% { transform: translateY(187px) } 95% { transform: translateY(176px) } 96% { transform: translateY(20px) } 97% { transform: translateY(312px) } 98% { transform: translateY(342px) } 99% { transform: translateY(47px) } 100% { transform: translateY(336px) }}'
                    '.aura { animation: glow 5s ease infinite alternate-reverse }'
                    '.shield { opacity: 0.6 }'
                    '.xv { animation-name: rx; animation-timing-function: step-end; animation-iteration-count: infinite; }'
                    '.yv { animation: ry 87s step-end infinite }'
                    '.t { transform: rotateY(260deg) }'
                    '.f1 { animation-delay: -0.5s }'
                    '.f2 { animation-delay: -10.5s }'
                    '.f3 { animation-delay: -15.7s }'
                    '.f4 { animation-delay: -32.5s }'
                    '.f5 { animation-delay: -37.3s }'
                    '.f6 { animation-delay: -32.2s }'
                    '.a1 { animation-duration: 31.11s }'
                    '.a2 { animation-duration: 37.91s }'
                    '.a3 { animation-duration: 42.31s }'
                    '.a4 { animation-duration: 47.71s }'
                    '.a5 { animation-duration: 131.11s }'
                    '.a6 { animation-duration: 141.01s }'
                '</style>'
                '<defs>'
                    '<radialGradient id="rgaura">'
                        '<stop offset="30%" stop-color="transparent" />'
                        '<stop offset="70%" stop-color="',
                        color,
                        '" stop-opacity="0.30" />'
                    '</radialGradient>'
                '</defs>'
                '<rect width="100%" height="100%" fill="111111" />',
                shieldFeatures(_mimicId),
                '<rect class="aura a4" x="0%" y="0" width="100%" height="100%" fill="#aaddff11" />',
                aura,
                '<g transform="translate(175, 175)">', shield(_mimicId, color), '</g>'
            '</svg>'
        ));
    }

    function shieldFeatures(uint256 _mimicId) internal view returns (string memory) {
        string memory eye = pluck(_mimicId, EYE, eyes);
        string memory tooth = pluck(_mimicId, TOOTH, teeth);
        uint256 rand_mouth = randomUS(_mimicId, MOUTH) % left_mouths.length;

        return string(abi.encodePacked(
            '<g class="xv f2 a1"><g class="yv f1 a3"><text class="base aura f1">', eye, '</text></g></g>'
            '<g class="xv f4 a2"><g class="yv f3 a4"><text class="base aura f3">', eye, '</text></g></g>'
            '<g class="xv f3 a3"><g class="yv f4 a5"><text class="base aura f2">', left_mouths[rand_mouth], '</text></g></g>'
            '<g class="xv f1 a4"><g class="yv f2 a6"><text class="base aura f4">', tooth, '</text></g></g>'
            '<g class="xv f5 a5"><g class="yv f2 a1"><text class="base aura f2">', tooth, '</text></g></g>'
            '<g class="xv f2 a6"><g class="yv f5 a2"><text class="base aura f5">', right_mouths[rand_mouth], '</text></g></g>'
        ));
    }

    function shieldAura(bool _active) internal pure returns (string memory) {
        if (_active) {
            return '<rect width="200%" height="200%" x="-175" y="-175" fill="url(#rgaura)" />';
        }
        return "";
    }

    function shield(uint256 _mimicId, string memory _color) internal pure returns (string memory) {
        string memory vdx = uintToString((randomUS(_mimicId, "VDX") % 100)+25);
        string memory vdy = uintToString((randomUS(_mimicId, "VDY") % 100)+25);
        string memory vvx = uintToString((randomUS(_mimicId, "VVX") % 100)+25);
        string memory hdx = uintToString((randomUS(_mimicId, "HDX") % 100)+25);
        string memory hdy = uintToString((randomUS(_mimicId, "HDY") % 100)+25);
        string memory hhy = uintToString((randomUS(_mimicId, "HHY") % 100)+25);

        return string(abi.encodePacked(
            poly1(_color, vdx, vdy, vvx),
            poly2(_color, vdx, vdy, vvx),
            poly3(_color, hdx, hdy, hhy),
            poly4(_color, hdx, hdy, hhy)
        ));
    }

    function poly1(string memory _color, string memory _x, string memory _y, string memory _z) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<polygon fill="', _color, '" class="shield aura f2 a1" points="0,0 ', _x, ',-', _y, ' 0,-', _z, ' -', _x, ',-', _y, '" />'
        ));
    }

    function poly2(string memory _color, string memory _x, string memory _y, string memory _z) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<polygon fill="', _color, '" class="shield aura f3 a2" points="0,0 ', _x, ',', _y, ' 0,', _z, ' -', _x, ',', _y, '" />'
        ));
    }

    function poly3(string memory _color, string memory _x, string memory _y, string memory _z) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<polygon fill="', _color, '" class="shield aura f4 a3" points="0,0 ', _x, ',', _y, ' ', _z, ',0 ', _x, ',-', _y, '" />'
        ));
    }

    function poly4(string memory _color, string memory _x, string memory _y, string memory _z) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<polygon fill="', _color, '" class="shield aura f5 a4" points="0,0 -', _x, ',', _y, ' -', _z, ',0 -', _x, ',-', _y, '" />'
        ));
    }

    function uintToString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encodeNew(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}

