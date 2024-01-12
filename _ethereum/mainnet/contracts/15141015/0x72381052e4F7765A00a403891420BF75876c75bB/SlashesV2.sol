// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DynamicBuffer.sol";
import "./Random.sol";
import "./Palette.sol";
import "./Utils.sol";

contract SlashesV2 is Random, Palette {

    function path(uint256 _seed, bool dir, uint32 lxProba, uint32 lyProba, uint32 wProba, uint32 lProba) internal pure returns (string memory _path, uint256 seed) {
        uint32 x;
        uint32 y;
        uint32 w;
        uint32 l;
        bool lx;
        bool ly;

        // coords
        seed = prng(_seed);
        x = 950 + randUInt32(seed, 0, 1000);
        seed = prng(seed);
        y = 950 + randUInt32(seed, 0, 1400);
        seed = prng(seed);
        // w = expRandUInt32(seed, 3, 50);
        w = expRandUInt32(seed, 3, 50) * (randBool(seed, wProba) ? 4 : 1);
        seed = prng(seed);
        // l = expRandUInt32(seed, 70, 500);
        l = expRandUInt32(seed, 50, 300) * (randBool(seed, lProba) ? 3 : 1);
        seed = prng(seed);
        lx = randBool(seed, lxProba);
        seed = prng(seed);
        ly = randBool(seed, lyProba);

        _path = string(dir ? abi.encodePacked(
            "M", Utils.uint32ToString(x-w), " ", Utils.uint32ToString(y),
            " L", Utils.uint32ToString(lx ? x-w+l : x-w-l), " ", Utils.uint32ToString(ly ? y+l : y-l),
            " L", Utils.uint32ToString(lx ? x+w+l : x+w-l), " ", Utils.uint32ToString(ly ? y+l : y-l),
            " L", Utils.uint32ToString(x+w), " ", Utils.uint32ToString(y),
            " Z"
        ) : abi.encodePacked(
            "M", Utils.uint32ToString(x), " ", Utils.uint32ToString(y-w),
            " L", Utils.uint32ToString(lx ? x+l : x-l), " ", Utils.uint32ToString(ly ? y-w+l : y-w-l),
            " L", Utils.uint32ToString(lx ? x+l : x-l), " ", Utils.uint32ToString(ly ? y+w+l : y+w-l),
            " L", Utils.uint32ToString(x), " ", Utils.uint32ToString(y+w),
            " Z"
        ));
    }

    function shape(uint256 _seed, uint32 gradientProba, uint32 lxProba, uint32 lyProba, uint32 wProba, uint32 lProba) 
    internal pure returns (string memory _shape, uint256 seed) 
    {
        uint32 offset;
        bool stroke;
        bool useGradient;
        bool dir;
        string memory _path;

        // attrs
        seed = prng(_seed);
        stroke = randBool(seed, 200);
        seed = prng(seed);
        offset = randUInt32(seed, 2, 10);
        seed = prng(seed);

        useGradient = randBool(seed, gradientProba);
        seed = prng(seed);
        dir = randBool(seed, 500);
        seed = prng(seed);

        (_path, seed) = path(seed, dir, lxProba, lyProba, wProba, lProba);

        _shape = string(abi.encodePacked(
            '<g class=\\"o\\"><path transform=\\"translate(',
            Utils.uint32ToString(offset),
            ",",
            Utils.uint32ToString(offset*2),
            ')\\" class=\\"S s',
            stroke ? 's' : 'f',
            useGradient ? dir ? 'h' :  'v' : '',
            '\\" d=\\"',
            _path,
            '\\"/>'
        ));

        _shape = string(abi.encodePacked(
            _shape,
            '<path class=\\"',
            stroke ? 's' : 'f',
            useGradient ? dir ? 'h' :  'v' : '',
            Utils.uint32ToString(randUInt32(seed, 1, 8)),
            '\\" d=\\"',
            _path,
            '\\" /></g>'
        ));
    }

    function generateSVG(uint256 _tokenId) public view returns (string memory svg, string memory attributes) {
        uint32 paletteId;
        uint32 gradientProba;
        uint32 lxProba;
        uint32 lyProba;
        uint32 wProba;
        uint32 lProba;
        uint32 slashesNumberx10;
        uint256 seed;
        string[8] memory paletteRGB;
        
        seed = prng(_tokenId + 31012022);
        (paletteRGB, paletteId, seed) = getRandomPalette(seed);

        seed = prng(prng(seed));
        gradientProba = randBool(seed, 800) ? 0 : randUInt32(seed, 1, 4);

        (, bytes memory attrBuffer) = DynamicBuffer.allocate(1000);
        DynamicBuffer.appendBytes(attrBuffer, bytes(abi.encodePacked(
            '{"trait_type":"shape","value":"SlashesV2"},',
            '{"trait_type":"Palette ID","value":',
            Utils.uint32ToString(paletteId),
            '},{"trait_type":"filter","value":"',
            ['none', 'contrast', 'grayscale', 'sepia'][gradientProba]
        )));

        (, bytes memory svgBuffer) = DynamicBuffer.allocate(60000);

        // viewbox
        DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
            '<svg xmlns=\\"http://www.w3.org/2000/svg\\" viewBox=\\"1050 1050 800 1200\\"><style>/*<![CDATA[*/svg{background:rgb(',
            paletteRGB[0],
            ');max-width:100vw;max-height:100vh}path{stroke-width:2}.o{opacity:.75}.S{opacity:.4}.sf{stroke:none;fill:black}.sfh{stroke:none;fill:url(#hs)}.sfv{stroke:none;fill:url(#vs)}.ss{stroke:black;fill:none}.ssh{stroke:url(#hs);fill:none}.ssv{stroke:url(#vs);fill:none}path{filter:',
            ['none', 'contrast(220%)', 'grayscale(100%) contrast(150%)', 'sepia(100%) contrast(150%)'][gradientProba],
            '}'
        )));
        
        // classes defs
        for (uint8 i = 1; i < 8;) {
            string memory index = ['0', '1', '2', '3', '4', '5', '6', '7'][i];
            DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
                '.s', // stroke
                index,
                '{fill:none;stroke:rgb(',
                paletteRGB[i],
                ')}.f', //fill
                index,
                '{stroke:none;fill:rgb(',
                paletteRGB[i],
                ')}.sh', //stroke horizontal gradient
                index,
                '{fill:none;stroke:url(#h',
                index,
                ')}.fh' //fill horizontal gradient
            )));

            DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
                index,
                '{stroke:none;fill:url(#h',
                index,
                ')}.sv', //stroke vertical gradient
                index,
                '{fill:none;stroke:url(#v',
                index,
                ')}.fv', //fill vertical gradient
                index,
                '{stroke:none;fill:url(#v',
                index,
                ')}'
            )));

            unchecked {
                 i++;
            }
        }

        DynamicBuffer.appendBytes(svgBuffer, 
            '/*]]>*/</style><defs><linearGradient gradientTransform=\\"rotate(90)\\" id=\\"hs\\"><stop offset=\\"20%\\" stop-color=\\"#000\\" /><stop offset=\\"95%\\" stop-color=\\"rgba(0, 0, 0, 0)\\" /></linearGradient><linearGradient id=\\"vs\\"><stop offset=\\"20%\\" stop-color=\\"#000\\" /><stop offset=\\"95%\\" stop-color=\\"rgba(0, 0, 0, 0)\\" /></linearGradient>'
        );

        // gradient defs
        for (uint8 i = 1; i < 8;) {
            string memory index = ['0', '1', '2', '3', '4', '5', '6', '7'][i];
            DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
                '<linearGradient gradientTransform=\\"rotate(90)\\" id=\\"h',
                index,
                '\\"><stop offset=\\"20%\\" stop-color=\\"rgba(',
                paletteRGB[i],
                ',1)\\" /><stop offset=\\"95%\\" stop-color=\\"rgba(',
                paletteRGB[i],
                ',0)\\" /></linearGradient>',
                '<linearGradient id=\\"v',
                index,
                '\\"><stop offset=\\"20%\\" stop-color=\\"rgba(',
                paletteRGB[i],
                ',1)\\" /><stop offset=\\"95%\\" stop-color=\\"rgba(',
                paletteRGB[i],
                ',0)\\" /></linearGradient>'
            )));

            unchecked {
                i++;
            }
        }

        seed = prng(seed);
        DynamicBuffer.appendBytes(attrBuffer, bytes(abi.encodePacked(
            '"},{"trait_type":"Background Opacity","value":"0.',
            ['2', '2', '2', '6', '8'][randUInt32(seed, 0, 5)]
        )));

        DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
            '</defs>',
            '<g id=\\"all\\"><g transform-origin=\\"1450 1650\\" transform=\\"scale(2)\\" opacity=\\".',
            ['2', '2', '2', '6', '8'][randUInt32(seed, 0, 5)],
            '\\"><g id=\\"slashes\\">'
        )));

        seed = prng(seed);
        gradientProba = randBool(seed, 800) ? 800 : [0, 1000][randUInt32(seed, 0, 2)];
        seed = prng(seed);
        lxProba = randBool(seed, 300) ? 500 : [0, 1000, 500, 750][randUInt32(seed, 0, 4)];
        seed = prng(seed);
        lyProba = randBool(seed, 300) ? 500 : [0, 1000, 500, 750][randUInt32(seed, 0, 4)];
        seed = prng(seed);
        wProba = randBool(seed, 600) ? 100 : [0, 400, 750][randUInt32(seed, 0, 3)];
        seed = prng(seed);
        lProba = randBool(seed, 600) ? 200 : [0, 500][randUInt32(seed, 0, 2)];
        seed = prng(seed);
        slashesNumberx10 = expRandUInt32(seed, 12, 26);

        DynamicBuffer.appendBytes(attrBuffer, bytes(abi.encodePacked(
            '"},{"trait_type":"Gradients / 1000","value":',
            Utils.uint32ToString(gradientProba),
            '},{"trait_type":"X Direction Force","value":',
            Utils.uint32ToString(lxProba),
            '},{"trait_type":"Y Direction Force","value":',
            Utils.uint32ToString(lyProba),
            '},{"trait_type":"Wider Shapes / 1000","value":',
            Utils.uint32ToString(wProba),
            '},{"trait_type":"Complexity Level","value":',
            Utils.uint32ToString(slashesNumberx10 - 11)
        )));

        for (uint8 index = 0; index < slashesNumberx10;) {
            string[10] memory shapes;
            for (uint8 i = 0; i < 10;) {
                (shapes[i], seed) = shape(seed, gradientProba, lxProba, lyProba, wProba, lProba);

                unchecked {
                    i++;
                }
            }
            DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
                shapes[0],
                shapes[1],
                shapes[2],
                shapes[3],
                shapes[4],
                shapes[5],
                shapes[6],
                shapes[7],
                shapes[8],
                shapes[9]
            )));

            unchecked {
                index++;
            }
        }

        seed = prng(seed);

        DynamicBuffer.appendBytes(attrBuffer, bytes(abi.encodePacked(
            '},{"trait_type":"Shape Type","value":"',
            ['Square', 'Circle', 'Diamond'][randBool(seed, 700) ? 0 : randUInt32(seed, 1, 3)],
            '"},{"trait_type":"Shape StrokeWidth","value":',
            ['10', '20', '40', '20', '40', '80', '160'][randUInt32(prng(prng(seed)), 0, 7)],
            '},{"trait_type":"Shape Filled","value":"',
            randBool(prng(seed), 800) ? 'False' : 'True',
            '"},{"trait_type":"Scales","value":"',
            ['.3', '.6', '.6', '.6', '.7', '.9', '.9', '.9', '.7', '1.3', '1'][randBool(seed, 20) ? 10 : randUInt32(prng(seed), 0, 10)],
            ' | ',
            ['.7', '.6', '.6', '.6', '.3', '.9', '.9', '.9', '1.3', '.7', '1,-1'][randBool(seed, 20) ? 10 : randUInt32(prng(seed), 0, 10)],
            '"}'
        )));

        DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
            '</g><use href=\\"#slashes\\" transform-origin=\\"1450 1650\\" transform=\\"rotate(180) scale(2)\\"/></g>',
            [
                '<rect x=\\"1200\\" y=\\"1400\\" width=\\"500\\" height=\\"500\\" stroke-width=\\"',
                '<circle cx=\\"1450\\" cy=\\"1650\\" r=\\"350\\" stroke-width=\\"',
                '<polyline points=\\"1450,1350 1750,1650 1450,1950 1150,1650 1450,1350 1750,1650\\" stroke-width=\\"'
            ][randBool(seed, 500) ? 0 : randUInt32(seed, 1, 3)],
            ['10', '20', '40', '20', '40', '80', '160'][randUInt32(prng(prng(seed)), 0, 7)],
            '\\" id=\\"shape\\" class=\\"o ',
            randBool(prng(seed), 800) ? 's' : 'f',
            ['1', '2', 's', '4', '5', '6', '7'][randUInt32(seed, 0, 7)],
            '\\" /><use href=\\"#slashes\\" transform-origin=\\"1450 1650\\" transform=\\"scale(',
            ['.5', '.8', '.8', '.8', '.9', '1.1', '1.1', '1.1', '.9', '1.5', '1'][randBool(seed, 20) ? 10 : randUInt32(prng(seed), 0, 10)],
            ')\\"/><use href=\\"#slashes\\" transform-origin=\\"1450 1650\\" transform=\\"rotate(180) scale(',
            ['.9', '.8', '.8', '.8', '.5', '1.1', '1.1', '1.1', '1.5', '.9', '1,-1'][randBool(seed, 20) ? 10 : randUInt32(prng(seed), 0, 10)],

            ')\\"/><use href=\\"#shape\\" opacity=\\".4\\" /></g></svg>'
        )));
        
        svg = string(svgBuffer);
        attributes = string(attrBuffer);
    }
}