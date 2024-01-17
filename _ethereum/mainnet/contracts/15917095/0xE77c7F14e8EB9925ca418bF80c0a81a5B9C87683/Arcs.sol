// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DynamicBuffer.sol";
import "./Random.sol";
import "./Palette.sol";
import "./Utils.sol";

contract Arcs is Random, Palette {

    function generateDashes(uint256 _seed, uint32 n, uint32 strokeMin, uint32 strokeMax, uint32 spaceMin, uint32 spaceMax) private pure returns (uint256 seed, string memory dashes) {
        seed = _seed;
        (, bytes memory buffer) = DynamicBuffer.allocate(n * 8);
        for (uint32 i = 0; i < n;) {
            seed = prng(seed);
            DynamicBuffer.appendBytes(buffer, bytes(abi.encodePacked(
                Utils.uint32ToString(expRandUInt32(seed, strokeMin, strokeMax)),
                ' ',
                Utils.uint32ToString(expRandUInt32(seed * 13, spaceMin, spaceMax)),
                ' '
            )));

            unchecked {
                i++;
            }
        }
        dashes = string(buffer);
    }

    function generateSVG(uint256 _seed) public view returns (string memory svg, string memory attributes) {
        uint32 paletteId;
        uint32 maxSw;
        uint32 minR;
        uint32 maxR;
        uint32 tmp;
        uint256 seed;
        string memory dashes;
        string[8] memory paletteRGB;
        (, bytes memory svgBuffer) = DynamicBuffer.allocate(150 + 105 * 800);
        (, bytes memory attrBuffer) = DynamicBuffer.allocate(1000);

        seed = prng(_seed);
        seed = prng(prng(seed));
        (paletteRGB, paletteId, seed) = getRandomPalette(seed);

        seed = prng(prng(seed));
        tmp = randBool(seed, 950) ? 0 : randUInt32(seed, 1, 4); // filter

        DynamicBuffer.appendBytes(attrBuffer, bytes(abi.encodePacked(
            '{"trait_type":"Shape","value":"Arcs"},',
            '{"trait_type":"Palette ID","value":',
            Utils.uint2str(paletteId),
            '},{"trait_type":"Filter","value":"',
            ['None', 'Contrast', 'Grayscale', 'Sepia'][tmp]
        )));

        seed = prng(seed);
        DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
            '<svg xmlns=\\"http://www.w3.org/2000/svg\\" viewBox=\\"0 0 800 1200\\"><style>/*<![CDATA[*/svg{background:rgb(',
            paletteRGB[randUInt32(seed, 0, 8)],
            ');max-width:100vw;max-height:100vh}svg>g{filter:',
            ['', 'contrast(150%)', 'grayscale(100%) contrast(150%)', 'sepia(100%)'][tmp],
            '}'
        )));

        // classes defs
        for (uint8 i = 0; i < 8;) {
            DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
                '.s', // stroke
                ['0', '1', '2', '3', '4', '5', '6', '7'][i],
                '{fill:none;stroke:rgb(',
                paletteRGB[i],
                ')}'
            )));
            
            unchecked {
                i++;
            }
        }

        seed = prng(seed);
        tmp = randUInt32(seed, 0, 4); // noiseScale

        DynamicBuffer.appendBytes(attrBuffer, bytes(abi.encodePacked(
            '"},{"trait_type":"Noise","value":',
            ['1', '2', '3', '4' ][tmp]
        )));

        DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
            '/*]]>*/</style><defs><filter id=\\"displacementFilter\\"><feTurbulence type=\\"turbulence\\" seed=\\"',
            Utils.uint32ToString(uint32(seed)),
            '\\" baseFrequency=\\".005\\" numOctaves=\\"10\\" result=\\"turbulence\\"/><feDisplacementMap in2=\\"turbulence\\" in=\\"SourceGraphic\\" scale=\\"',
            ['100', '200', '300', '400' ][tmp],
            '\\" xChannelSelector=\\"R\\" yChannelSelector=\\"G\\"/></filter></defs><g transform=\\"translate(400, 600)\\"><g',
            ' filter=\\"url(#displacementFilter)\\"',
            ' opacity=\\".7\\"><g id=\\"a\\">'
        )));

        // first layer
        seed = prng(seed);
        tmp = [1, 3, 3, 5, 5, 5, 15, 15, 15, 15][randUInt32(seed, 0, 10)]; // nbDashes

        for (uint8 index = 0; index < 25;) {
            seed = prng(seed);
            uint32 r = randUInt32(seed, 100, 750);
            seed = prng(seed);
            uint32 sw = expRandUInt32(seed, 50, 100);

            (seed, dashes) = generateDashes(seed, tmp, 1, 150, 1, 40);

            DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
                '<circle opacity=\\".5\\" transform=\\"rotate(',
                Utils.uint32ToString(randUInt32(seed, 0, 360)),
                ')\\" class=\\"s',
                ['0', '1', '2', '3', '4', '5', '6', '7'][randUInt32(seed, 0, 8)],
                '\\" stroke-width=\\"',
                Utils.uint32ToString(sw),
                '\\" r=\\"',
                Utils.uint32ToString(r),
                '\\" stroke-dasharray=\\"',
                dashes,
                '\\" />'
            )));
            
            unchecked {
                index++;
            }
        }

        seed = prng(seed);
        DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
            '</g></g><use href=\\"#a\\" opacity=\\".95\\" />',
            '<g',
            ' filter=\\"url(#displacementFilter)\\"', 
            ' opacity=\\".5\\"><g id=\\"b\\">'
        )));

        // second layer
        seed = prng(seed);
        tmp = [1, 3, 3, 5, 5, 5, 15, 15, 15, 15][randUInt32(seed, 0, 10)]; // nbDashes

        seed = prng(seed);
        maxSw = [25, 50, 50, 50, 50, 100][randUInt32(seed, 0, 6)];

        seed = prng(seed);
        minR = [200, 200, 100][randUInt32(seed, 0, 3)];

        seed = prng(seed);
        maxR = [450, 550, 650, 750][randUInt32(seed, 0, 4)];

        DynamicBuffer.appendBytes(attrBuffer, bytes(abi.encodePacked(
            '},{"trait_type":"Stroke Width Max","value":',
            Utils.uint2str(maxSw),
            '},{"trait_type":"Dashes","value":',
            Utils.uint2str(tmp),
            '},{"trait_type":"Radius Range","value":',
            Utils.uint2str(maxR - minR),
            '}'
        )));

        for (uint8 index = 0; index < 70;) {
            seed = prng(seed);
            uint32 r = randUInt32(seed, minR, maxR);
            seed = prng(seed);
            uint32 sw = expRandUInt32(seed, 3, 100);

            (seed, dashes) = generateDashes(seed, tmp, 1, 150, 1, 150);

            DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
                '<circle opacity=\\".75\\" transform=\\"rotate(',
                Utils.uint32ToString(randUInt32(seed, 0, 360)),
                ')\\" class=\\"s',
                ['0', '1', '2', '3', '4', '5', '6', '7'][randUInt32(seed, 0, 8)],
                '\\" stroke-width=\\"',
                Utils.uint32ToString(sw),
                '\\" r=\\"',
                Utils.uint32ToString(r),
                '\\" stroke-dasharray=\\"',
                dashes,
                '\\" />'
            )));
            
            unchecked {
                index++;
            }
        }

        seed = prng(seed);
        DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked('</g></g><use href=\\"#b\\" opacity=\\".95\\" transform=\\"scale(.8)\\"/></g><g opacity=\\".7\\"><rect x=\\"15\\" y=\\"15\\" width=\\"770\\" height=\\"1170\\" class=\\"s',
        ['0', '1', '2', '3', '4', '5', '6', '7'][randUInt32(seed, 0, 8)],
        '\\" fill=\\"none\\" stroke-width=\\"8\\"/><rect x=\\"30\\" y=\\"30\\" width=\\"740\\" height=\\"1140\\" class=\\"s',
        ['0', '1', '2', '3', '4', '5', '6', '7'][randUInt32(seed, 0, 8)],
        '\\" fill=\\"none\\" stroke-width=\\"2\\"/></g></svg>')));
        
        svg = string(svgBuffer);

        attributes = string(attrBuffer);
    }
}