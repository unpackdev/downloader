// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Context.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";
        uint256 encodedLen = 4 * ((len + 2) / 3);
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;
        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {
            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}

library Buffer {
    function hasCapacityFor(bytes memory buffer, uint256 needed) internal pure returns (bool) {
        uint256 size;
        uint256 used;
        assembly {
            size := mload(buffer)
            used := mload(add(buffer, 32))
        }
        return size >= 32 && used <= size - 32 && used + needed <= size - 32;
    }

    function toString(bytes memory buffer) internal pure returns (string memory) {
        require(hasCapacityFor(buffer, 0), "Buffer.toString: invalid buffer");
        string memory ret;
        assembly {
            ret := add(buffer, 32)
        }
        return ret;
    }

    function append(bytes memory buffer, string memory str) internal view {
        require(hasCapacityFor(buffer, bytes(str).length), "Buffer.append: no capacity");
        assembly {
            let len := mload(add(buffer, 32))
            pop(staticcall(gas(), 0x4, add(str, 32), mload(str), add(len, add(buffer, 64)), mload(str)))
            mstore(add(buffer, 32), add(len, mload(str)))
        }
    }
}

interface Cryptomancy
{
    function balanceOf (address account, uint256 id) external view returns (uint256);
}

interface CDROM
{
    function ownerOf (uint256 tokenId) external view returns (address);
}

contract Sigils is ERC721, ReentrancyGuard {
    address public _owner;
    uint256 public maxSupply = 9393;
    uint256 private _count = 0;
    uint256 private _price = 10000000 gwei;

    address private cryptomancyAddress = 0x7c7fC6d9F2c2e45f12657DAB3581EAd2BD53bDF1;
    address private cdAddress = 0xad78E15a5465C09F6E6522b0d98b1F3b6B67Ee7e;
    Cryptomancy cryptomancyContract = Cryptomancy(cryptomancyAddress);
    CDROM cdContract = CDROM(cdAddress);
    mapping(uint256 => bool) private _cryptomancyMints;
    mapping(uint256 => bool) private _cdMints;

    struct sigilValues {
        uint8[] sigil;
        uint8 gradient;
        uint8 color;
        uint8 planetHour;
        uint8 planetDay;
        uint8 darkBG;
        uint16 rareNumber;
        bytes intent;
        string texture;
    }
    mapping (uint256 => sigilValues) public idSigils;

    // array of uint array that is used to map letters to coordinates
    // these coordinates are equidistanct points around the circumphrence of a circle
    uint[2][22] private _coords = [[uint(0),uint(0)],[uint(235),uint(420)],[uint(279),uint(411)],[uint(333),uint(385)],[uint(376),uint(345)],[uint(406),uint(293)],[uint(419),uint(235)],[uint(415),uint(175)],[uint(393),uint(120)],[uint(356),uint(73)],[uint(307),uint(40)],[uint(250),uint(22)],[uint(190),uint(22)],[uint(133),uint(40)],[uint(84),uint(73)],[uint(47),uint(120)],[uint(25),uint(175)],[uint(21),uint(235)],[uint(34),uint(293)],[uint(64),uint(345)],[uint(107),uint(385)],[uint(161),uint(411)]];

    // array of planet descriptions and symbols for use in sigil generation
    string[8] private _planetSymbols = ['invalid', unicode'♄', unicode'♃', unicode'♂', unicode'☉', unicode'♀', unicode'☿', unicode'☽'];
    string[8] private _planetNames = ["invalid", "Saturn", "Jupiter", "Mars", "Sun", "Venus", "Mercury", "Moon"];

    // Light background gradients with hash to visualise (use color highlight vscode plugin)
    // #9e7682,#ad7780,#bb797c,#c7837c,#d29381,#dda587,#e5b88e,#edcb96
    // #e9d758,#e9e46c,#e3e880,#dce894,#d9e7a8,#d9e7bc,#dde6d0,#e5e6e4
    // #fff4f3,#ffe9ef,#ffe0f3,#ffd6fd,#f0ccff,#d8c2ff,#bab9ff,#afc9ff
    // #c5decd,#afd8be,#9ad2b1,#86cca6,#72c69c,#60c094,#4eba8e,#3eb489
    // #ec9192,#ec9ba9,#eca5bc,#ecafcd,#ecb8da,#ecc2e4,#eccceb,#e9d6ec
    // #ffc4eb,#fbb9d0,#f6b0b1,#f0bea9,#e8cea2,#dedb9d,#c4d39a,#abc798
    // #bdd2a6,#aacda3,#a0c7a7,#9ec1b1,#9cbbb7,#9aaeb4,#99a2ad,#9899a6
    // #eff8e2,#ebf4dc,#e8f0d7,#e4ebd2,#dfe5ce,#dadecb,#d5d7c9,#cecfc7
    // #f3dfc1,#f1dabd,#eed6b9,#ebd1b5,#e8ccb1,#e4c7ae,#e1c3ab,#ddbea8
    // #b2a3b5,#a796b4,#9687b4,#7d78b4,#6976b6,#5880b8,#4695bb,#3aafb9
    // #91818a,#a88591,#bd8b91,#cf9994,#deb2a0,#eacdae,#f3e6c0,#faf8d4
    bytes6[8][11] private _gradientsLight = [[bytes6('9e7682'),bytes6('ad7780'),bytes6('bb797c'),bytes6('c7837c'),bytes6('d29381'),bytes6('dda587'),bytes6('e5b88e'),bytes6('edcb96')],[bytes6('e9d758'),bytes6('e9e46c'),bytes6('e3e880'),bytes6('dce894'),bytes6('d9e7a8'),bytes6('d9e7bc'),bytes6('dde6d0'),bytes6('e5e6e4')],[bytes6('fff4f3'),bytes6('ffe9ef'),bytes6('ffe0f3'),bytes6('ffd6fd'),bytes6('f0ccff'),bytes6('d8c2ff'),bytes6('bab9ff'),bytes6('afc9ff')],[bytes6('c5decd'),bytes6('afd8be'),bytes6('9ad2b1'),bytes6('86cca6'),bytes6('72c69c'),bytes6('60c094'),bytes6('4eba8e'),bytes6('3eb489')],[bytes6('ec9192'),bytes6('ec9ba9'),bytes6('eca5bc'),bytes6('ecafcd'),bytes6('ecb8da'),bytes6('ecc2e4'),bytes6('eccceb'),bytes6('e9d6ec')],[bytes6('ffc4eb'),bytes6('fbb9d0'),bytes6('f6b0b1'),bytes6('f0bea9'),bytes6('e8cea2'),bytes6('dedb9d'),bytes6('c4d39a'),bytes6('abc798')],[bytes6('bdd2a6'),bytes6('aacda3'),bytes6('a0c7a7'),bytes6('9ec1b1'),bytes6('9cbbb7'),bytes6('9aaeb4'),bytes6('99a2ad'),bytes6('9899a6')],[bytes6('eff8e2'),bytes6('ebf4dc'),bytes6('e8f0d7'),bytes6('e4ebd2'),bytes6('dfe5ce'),bytes6('dadecb'),bytes6('d5d7c9'),bytes6('cecfc7')],[bytes6('f3dfc1'),bytes6('f1dabd'),bytes6('eed6b9'),bytes6('ebd1b5'),bytes6('e8ccb1'),bytes6('e4c7ae'),bytes6('e1c3ab'),bytes6('ddbea8')],[bytes6('b2a3b5'),bytes6('a796b4'),bytes6('9687b4'),bytes6('7d78b4'),bytes6('6976b6'),bytes6('5880b8'),bytes6('4695bb'),bytes6('3aafb9')],[bytes6('91818a'),bytes6('a88591'),bytes6('bd8b91'),bytes6('cf9994'),bytes6('deb2a0'),bytes6('eacdae'),bytes6('f3e6c0'),bytes6('faf8d4')]];
    bytes12[11] private _gradientsLightDesc = [
        bytes12('kitchen wall'),
        bytes12('bike dreamer'),
        bytes12('cotton candy'),
        bytes12('falling tree'),
        bytes12('heart desire'),
        bytes12('fluorescence'),
        bytes12('forest mists'),
        bytes12('ancient moor'),
        bytes12('desert peaks'),
        bytes12('shimmer pool'),
        bytes12('night wander')
    ];

    // Dark gradients
    // #800815,#920832,#a40757,#b60783,#c905b6,#c404db,#a602ed,#7f00ff
    // #884274,#994272,#aa406a,#bb3b59,#cc3541,#dd3c2e,#ee5524,#ff7518
    // #1e0336,#1a044b,#0c0461,#041276,#03328c,#035ca1,#018fb7,#00cccc
    // #453a94,#574097,#67479a,#774d9d,#86549f,#945ba2,#a063a5,#a86aa4
    // #090a0f,#161826,#22253c,#2e3153,#393b6a,#434381,#4e4c97,#5a55ae
    // #0d3b66,#102370,#1f137a,#461684,#701a8d,#971e8f,#a12271,#ab274f
    // #aa4465,#a64258,#a2414c,#9e3f40,#9b463d,#974e3b,#93553a,#8f5c38
    // #590925,#5a113a,#5b1a4c,#5c235b,#552c5e,#4f355f,#4c3e60,#4d4861
    // #093a3e,#0e4d52,#135f65,#197077,#208189,#28919a,#31a0aa,#3aafb9
    // #3d5a6c,#3d4a66,#3d3e5f,#443d59,#493c53,#4b3c4e,#483b46,#433a3f
    // #17301c,#1d3a27,#244434,#2b4e42,#325750,#3a5f5e,#426468,#4a6670
    bytes6[8][11] private _gradientsDark = [[bytes6('800815'),bytes6('920832'),bytes6('a40757'),bytes6('b60783'),bytes6('c905b6'),bytes6('c404db'),bytes6('a602ed'),bytes6('7f00ff')],[bytes6('884274'),bytes6('994272'),bytes6('aa406a'),bytes6('bb3b59'),bytes6('cc3541'),bytes6('dd3c2e'),bytes6('ee5524'),bytes6('ff7518')],[bytes6('1e0336'),bytes6('1a044b'),bytes6('0c0461'),bytes6('041276'),bytes6('03328c'),bytes6('035ca1'),bytes6('018fb7'),bytes6('00cccc')],[bytes6('453a94'),bytes6('574097'),bytes6('67479a'),bytes6('774d9d'),bytes6('86549f'),bytes6('945ba2'),bytes6('a063a5'),bytes6('a86aa4')],[bytes6('090a0f'),bytes6('161826'),bytes6('22253c'),bytes6('2e3153'),bytes6('393b6a'),bytes6('434381'),bytes6('4e4c97'),bytes6('5a55ae')],[bytes6('0d3b66'),bytes6('102370'),bytes6('1f137a'),bytes6('461684'),bytes6('701a8d'),bytes6('971e8f'),bytes6('a12271'),bytes6('ab274f')],[bytes6('aa4465'),bytes6('a64258'),bytes6('a2414c'),bytes6('9e3f40'),bytes6('9b463d'),bytes6('974e3b'),bytes6('93553a'),bytes6('8f5c38')],[bytes6('590925'),bytes6('5a113a'),bytes6('5b1a4c'),bytes6('5c235b'),bytes6('552c5e'),bytes6('4f355f'),bytes6('4c3e60'),bytes6('4d4861')],[bytes6('093a3e'),bytes6('0e4d52'),bytes6('135f65'),bytes6('197077'),bytes6('208189'),bytes6('28919a'),bytes6('31a0aa'),bytes6('3aafb9')],[bytes6('3d5a6c'),bytes6('3d4a66'),bytes6('3d3e5f'),bytes6('443d59'),bytes6('493c53'),bytes6('4b3c4e'),bytes6('483b46'),bytes6('433a3f')],[bytes6('17301c'),bytes6('1d3a27'),bytes6('244434'),bytes6('2b4e42'),bytes6('325750'),bytes6('3a5f5e'),bytes6('426468'),bytes6('4a6670')]];
    bytes12[11] private _gradientsDarkDesc = [
        bytes12('booba paints'),
        bytes12('hallowed eve'),
        bytes12('fallen light'),
        bytes12('logos flight'),
        bytes12('seeping dark'),
        bytes12('volcanic art'),
        bytes12('archaeologer'),
        bytes12('lava bubbles'),
        bytes12('escaping out'),
        bytes12('night terror'),
        bytes12('misty copses')
    ];
    // #e3be46,#e1bb43,#dab53c,#d1ac32,#c8a229,#bf9a21,#b8931b,#b69119
    bytes6[8] private _gradientGold = [bytes6('e3be46'),bytes6('e1bb43'),bytes6('dab53c'),bytes6('d1ac32'),bytes6('c8a229'),bytes6('bf9a21'),bytes6('b8931b'),bytes6('b69119')];

    bytes6[11] private _colorsLight = [bytes6('ffc4eb'),bytes6('e9e46c'),bytes6('9ad2b1'),bytes6('ec9192'),bytes6('3aafb9'),bytes6('e5e6e4'),bytes6('fff4f3'),bytes6('e5b88e'),bytes6('c5decd'),bytes6('e9d6ec'),bytes6('b2a3b5')];
    bytes6[11] private _colorsDark = [bytes6('3f19af'),bytes6('101010'),bytes6('0D3B66'),bytes6('800815'),bytes6('ff7518'),bytes6('090a0f'),bytes6('433a3f'),bytes6('4a6670'),bytes6('17301c'),bytes6('34403a'),bytes6('1e0336')];

    constructor() ERC721("Sigils", "SIGIL") {
        _owner = msg.sender;
    }

    // shuffle numbers in a way that prevents repeats
    function _shuffle(string memory seed) private view returns (uint8[21] memory){
        uint8[21] memory _numArray = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21];
        for (uint256 i = 0; i < _numArray.length; i++) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, seed))) % (_numArray.length - i);
            uint8 temp = _numArray[n];
            _numArray[n] = _numArray[i];
            _numArray[i] = temp;
        }
        return _numArray;
    }

    // return a randomised number
    function _random(uint mod, string memory seed1, string memory seed2, string memory seed3, string memory seed4) private view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, seed1, seed2, seed3, seed4)))%mod);
    }

    // unpack coordinates array
    function _drawSigil(sigilValues storage s) private view returns (string memory) {
        bytes memory sigilBuffer = new bytes(8192);
        uint8 _sigNum = s.sigil[0];

        Buffer.append(sigilBuffer, string(abi.encodePacked(toString(_coords[_sigNum][0]), ', ', toString(_coords[_sigNum][1]))));
        for (uint i=1; i<s.sigil.length; ++i) {
            _sigNum = s.sigil[i];
            Buffer.append(sigilBuffer, string(abi.encodePacked(' ', toString(_coords[_sigNum][0]), ', ', toString(_coords[_sigNum][1]))));
        }

        return Buffer.toString(sigilBuffer);
    }

    function _genSigil(sigilValues storage s, bytes6 color, bytes6[8] storage gradient) private view returns (string memory) {
        uint[2] memory _firstCoords = _coords[s.sigil[0]];
        uint[2] memory _lastCoords = _coords[s.sigil[s.sigil.length-1]];

        string memory sigilCoords = _drawSigil(s);

        bytes memory svgBuffer = new bytes(8192);

        Buffer.append(svgBuffer, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><svg version="1.1" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 440 440"><defs><linearGradient id="lg" x1="0" x2="0" y1="0" y2="1">');

        for (uint i=0; i<gradient.length; i++) {
            string memory offset;
            if (i == 0) { offset = '0'; }
            if (i == 1) { offset = '14'; }
            if (i == 2) { offset = '28'; }
            if (i == 3) { offset = '42'; }
            if (i == 4) { offset = '56'; }
            if (i == 5) { offset = '70'; }
            if (i == 6) { offset = '84'; }
            if (i == 7) { offset = '100'; }
            Buffer.append(svgBuffer, string(abi.encodePacked('<stop offset="', offset, '%" stop-color="#', gradient[i], '"/>')));
        }

        bytes6 floodColor;
        if (s.darkBG == 1) {
            floodColor = color;
        } else {
            floodColor = bytes6('f0f0f0');
        }

        string memory circle;
        if (s.rareNumber == 93 || s.rareNumber == 888) {
            // mega rares have a special effect layer
            circle = string(abi.encodePacked('<filter id="circEff" color-interpolation-filters="sRGB" x="0" y="0" width="200%" height="200%"><feTurbulence type="turbulence" baseFrequency=".01,.2" numOctaves="2" seed="',toString(s.rareNumber),'"/><feDiffuseLighting surfaceScale="1" diffuseConstant="1" lighting-color="#ffffff" x="0%" y="0%" width="100%" height="100%"><feDistantLight azimuth="15" elevation="105"/></feDiffuseLighting><feComposite in2="SourceGraphic" operator="in"/><feBlend in2="SourceGraphic" mode="multiply"/></filter><circle cx="220" cy="220" r="215" stroke-width="0" fill="url(#lg)" shape-rendering="geometricPrecision" filter="url(#circEff)"/>'));
        } else if (s.rareNumber >= 655 && s.rareNumber <= 677) {
            // not so rare but still cool, gets rock filter
            circle = string(abi.encodePacked('<filter id="circEff" color-interpolation-filters="sRGB" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency=".07,.03" numOctaves="4" seed="',toString(s.rareNumber),'"/><feDiffuseLighting surfaceScale="5" diffuseConstant="0.75" lighting-color="#fff" x="0%" y="0%" width="100%" height="100%"><feDistantLight azimuth="3" elevation="100"/></feDiffuseLighting><feComposite in2="SourceGraphic" operator="in"/><feBlend in="SourceGraphic" mode="multiply"/></filter><circle cx="220" cy="220" r="215" stroke-width="0" fill="url(#lg)" shape-rendering="geometricPrecision" filter="url(#circEff)"/>'));
        } else if (s.rareNumber >= 10 && s.rareNumber <= 50) {
            // these guys get a fabric effect
            circle = string(abi.encodePacked('<filter id="circEff" color-interpolation-filters="sRGB" x="0" y="0" width="100%" height="100%"><feTurbulence type="turbulence" baseFrequency=".03,.003" numOctaves="1" seed="',toString(s.rareNumber),'"/><feColorMatrix type="matrix" values="0 0 0 0 0,0 0 0 0 0,0 0 0 0 0,0 0 0 -1.5 1.1"/><feComposite in="SourceGraphic" operator="in"/><feBlend in="SourceGraphic" mode="screen"/></filter><circle cx="220" cy="220" r="215" stroke-width="0" fill="url(#lg)" shape-rendering="geometricPrecision" filter="url(#circEff)"/>'));
        } else {
            circle = '<circle cx="220" cy="220" r="215" stroke-width="0" fill="url(#lg)" shape-rendering="geometricPrecision"/>';
        }
        Buffer.append(svgBuffer, string(abi.encodePacked('</linearGradient></defs><filter id="shadow" x="0" y="0" width="200%" height="200%" filterUnits="userSpaceOnUse"><feGaussianBlur in="SourceAlpha" stdDeviation="4"/><feOffset dx="0" dy="0" result="offsetblur"/><feFlood flood-color="#', floodColor, '" flood-opacity="0.75"/><feComposite in2="offsetblur" operator="in"/><feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter>',circle)));
        Buffer.append(svgBuffer, string(abi.encodePacked('<g fill="none" stroke="#', color, '" stroke-width="5" stroke-linejoin="round" filter="url(#shadow)" shape-rendering="geometricPrecision"><polyline points="', sigilCoords, '" />')));

        Buffer.append(svgBuffer, string(abi.encodePacked('<polyline points="', toString(_lastCoords[0]), ', ', toString(_lastCoords[1] + 10), ', ', toString(_lastCoords[0]), ', ', toString(_lastCoords[1] - 10), '" stroke-linecap="round" />')));
        Buffer.append(svgBuffer, string(abi.encodePacked('<circle cx="', toString(_firstCoords[0]), '" cy="', toString(_firstCoords[1]), '" r="5" fill="#', color, '"/></g>')));
        Buffer.append(svgBuffer, string(abi.encodePacked('<text x="110" y="330" fill="#', color, '" font-size="80px" font-weight="bold" stroke="transparent" fill-opacity="0.25" dominant-baseline="middle" text-anchor="middle">', _planetSymbols[s.planetDay], '</text><text x="330" y="330" fill="#', color, '" font-size="80px" font-weight="bold" stroke="transparent" fill-opacity="0.25" dominant-baseline="middle" text-anchor="middle">', _planetSymbols[s.planetHour], '</text></svg>')));

        return Buffer.toString(svgBuffer);
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory jsonOut;
        string memory svgOut;

        sigilValues storage s = idSigils[tokenId];

        bytes6 color;
        bytes6[8] storage gradient;
        bytes12 gradientDesc;
        if (s.rareNumber == 93 || s.rareNumber == 888) {
            // this is a super rare mega gold card
            color = bytes6('FDF2C3'); // #FDF2C3
            gradient = _gradientGold;
            gradientDesc = bytes12('gold bullrun');
        } else {
            // this is a boring normal card
            if (s.darkBG == 1) {
                color = _colorsLight[s.color];
                gradient = _gradientsDark[s.gradient];
                gradientDesc = _gradientsDarkDesc[s.gradient];
            } else {
                color = _colorsDark[s.color];
                gradient = _gradientsLight[s.gradient];
                gradientDesc = _gradientsLightDesc[s.gradient];
            }
        }

        svgOut = _genSigil(s, color, gradient);

        bytes memory jsonBuffer = new bytes(8192);
        Buffer.append(jsonBuffer, string(abi.encodePacked('{"name": "Sigil #', toString(tokenId), '", "attributes": [ { "trait_type": "Color", "value": "#', color ,'" }, { "trait_type": "Gradient", "value": "', gradientDesc, '" }, { "trait_type": "Intent", "value": "', s.intent, '" },')));
        Buffer.append(jsonBuffer, string(abi.encodePacked(' { "trait_type": "Texture", "value": "', s.texture, '" }, { "trait_type": "Planetary Day", "value": "', _planetNames[s.planetDay], '"}, { "trait_type": "Planetary Hour", "value": "', _planetNames[s.planetHour], '"} ], "description": "Sigils are an on-chain representation of pure intent. Users input their intent after deep reflection and receive this image in response.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svgOut)), '"}')));
        jsonOut = Base64.encode(bytes(Buffer.toString(jsonBuffer)));
        bytes memory result = new bytes(8192);
        Buffer.append(result, 'data:application/json;base64,');
        Buffer.append(result, jsonOut);
        return Buffer.toString(result);
    }

    function mint(string memory intent, uint8 planetDay, uint8 planetHour) internal {
        bytes memory intentBytes = bytes(intent);
        require(intentBytes.length > 2, "Must provide at least 3 chars");
        // we arent actually checking for repeating letters - the only time this happens is when people do dumb stuff via directly interacting with the contract, and who cares if those people make their sigils look dumb
        require(intentBytes.length < 22, "No repeating letters");
        require(planetDay < 8, "Invalid planetDay");
        require(planetHour < 8, "Invalid planetHour");

        uint8 ord;
        uint8[] memory intentArray = new uint8[](intentBytes.length);
        uint8[21] memory shuffleArray = _shuffle(toString(_count));
        for (uint i=0; i<intentBytes.length; ++i) {
            ord = toUint8(bytes.concat(intentBytes[i]), 0);
            require(ord > 97 && ord <= 122, "Only use lowercase latin letters");
            require(ord != 101 && ord != 105 && ord != 111 && ord != 117, "No vowels permitted");
            // we need to reduce the numbers down to the range of 1-21
            // we also map them to the shuffled number thats in shuffleArray
            uint8 shufOrd;
            if (ord > 97 && ord < 101) {
                shufOrd = ord - 98;
            } else if (ord > 101 && ord < 105) {
                shufOrd = ord - 99;
            } else if (ord > 105 && ord < 111) {
                shufOrd = ord - 100;
            } else if (ord > 111 && ord < 117) {
                shufOrd = ord - 101;
            } else if (ord > 117) {
                shufOrd = ord - 102;
            }
            intentArray[i] = shuffleArray[shufOrd];
        }

        if (planetDay == 0) {
            // get a random planet, use static seed
            planetDay = _random(7, 'planetDay', intent, string(abi.encodePacked(msg.sender)), toString(_count)) + 1;
        }
        if (planetHour == 0) {
            // get a random planet, use static seed
            planetHour = _random(7, 'planetHour', intent, string(abi.encodePacked(msg.sender)), toString(_count)) + 1;
        }

        sigilValues storage thisSigil = idSigils[_count];
        thisSigil.planetDay = planetDay;
        thisSigil.planetHour = planetHour;
        thisSigil.sigil = intentArray;
        thisSigil.intent = intentBytes;
        thisSigil.gradient = _random(11, 'gradient', intent, string(abi.encodePacked(msg.sender)), toString(_count));
        thisSigil.color = _random(11, 'color', intent, string(abi.encodePacked(msg.sender)), toString(_count));
        thisSigil.darkBG = _random(2, 'color', intent, string(abi.encodePacked(msg.sender)), toString(_count));

        uint16 rareNumber = _random(1000, 'rarity', intent, string(abi.encodePacked(msg.sender)), toString(_count));
        thisSigil.rareNumber = rareNumber;
        if (rareNumber == 93 || rareNumber == 888) {
            thisSigil.texture = 'gold';
        } else if (rareNumber >= 655 && rareNumber <= 677) {
            thisSigil.texture = 'rock';
        } else if (rareNumber >= 10 && rareNumber <= 50) {
            thisSigil.texture = 'fabric';
        } else {
            thisSigil.texture = 'flat';
        }

        _safeMint(_msgSender(), _count);
        ++_count;
    }

    function mintWithCryptomancy(uint256 _cryptomancyId, string memory _intent, uint8 _planetDay, uint8 _planetHour) external nonReentrant {
        require(cryptomancyContract.balanceOf(msg.sender, _cryptomancyId) > 0, "Not the owner of this Cryptomancy.");
        require(!_cryptomancyMints[_cryptomancyId], "This Cryptomancy has already been used.");
        _cryptomancyMints[_cryptomancyId] = true;
        mint(_intent, _planetDay, _planetHour);
    }

    function mintWithCD(uint256 _cdId, string memory _intent, uint8 _planetDay, uint8 _planetHour) external nonReentrant {
        require(cdContract.ownerOf(_cdId) == msg.sender, "Not the owner of this Ghost CD.");
        require(!_cdMints[_cdId], "This Ghost CD has already been used.");
        _cdMints[_cdId] = true;
        mint(_intent, _planetDay, _planetHour);
    }

    function mintSigil(string memory _intent, uint8 _planetDay, uint8 _planetHour) public payable nonReentrant {
        require(msg.value >= _price, "Price is 0.01 ETH!");
        // maxSupply should only apply for the paid ones, cd-rom and cryptomancy will always succeed
        require(_count < maxSupply, "Capped!");
        mint(_intent, _planetDay, _planetHour);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function withdraw() external {
        address payable ownerDestination = payable(_owner);

        ownerDestination.transfer(address(this).balance);
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function totalSupply() external view returns (uint256) {
        return _count;
    }

    function claimPrice() external view returns (uint256) {
        return _price;
    }

    function hasClaimedCryptomancy(uint256 id) external view returns (bool) {
        return _cryptomancyMints[id];
    }

    function hasClaimedCD(uint256 id) external view returns (bool) {
        return _cdMints[id];
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;
        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }
        return tempUint;
    }

    function toString(uint256 value) internal pure returns (string memory) {
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
