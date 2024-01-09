// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Floadmap1155.sol";

contract Flipdata {

    struct Palette {
        string color1;
        string color2;
        string color3;
    }

    Palette[4] public palettes;

    uint256 maxLineLength = 38;

    constructor() {
        palettes[0] = Palette('#00b1ff', '#fF00fF', '#ffe100');
        palettes[1] = Palette('#ffe100', '#00b1ff', '#fF00fF');
        palettes[2] = Palette('#fF00fF', '#ffe100', '#00b1ff');
        palettes[3] = Palette('#CAD2C5', '#CAD2C5', '#CAD2C5');
    }

    function getJSON(uint256 tokenId, Floadmap1155.Quest memory quest, uint256 questSolved, string memory payload) public view returns (string memory) {
        string memory name = string(abi.encodePacked('#', toString(tokenId)));
        string memory description = 'Floadmap - the ever-evolving story of the Flipverse. Including riddles and puzzles to reward the Flipmap family.';
        string memory image = string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(makeSVG(tokenId, quest, questSolved, payload)))));
        string memory json = string(abi.encodePacked('{"name": "', name, '", "description": "', description, '", "image": "', image, '", "attributes": [', makeAttributes(tokenId, questSolved), ']}'));
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(json))));
    }

    function makeAttributes(uint256 tokenId, uint256 questSolved) public pure returns (string memory attributes) {
        if(tokenId > 12) {
            attributes = string(abi.encodePacked(attributes, '{"trait_type":"Type","value":"Lore"}'));
        } else {
            attributes = string(abi.encodePacked(attributes, '{"trait_type":"Type","value":"Quest"},'));
            bool solved;
            if(questSolved > 0) {
                solved = true;
            }
            attributes = string(abi.encodePacked(attributes, '{"trait_type":"Solved","value":"', toStringBool(solved), '"}'));
        }
    }

    function makeSVG(uint256 tokenId, Floadmap1155.Quest memory quest, uint256 questSolved, string memory payload) public view returns (string memory svg) {
        svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1080 1080" shape-rendering="crispEdges">';

        string memory color1;
        string memory color2;
        string memory color3;
        if(questSolved > 0) {
            color1 = palettes[3].color1;
            color2 = palettes[3].color2;
            color3 = palettes[3].color3;
        } else {
            uint256 key = tokenId % 3;
            color1 = palettes[key].color1;
            color2 = palettes[key].color2;
            color3 = palettes[key].color3;
        }

        svg = string(abi.encodePacked(svg, '<rect fill="', color1, '" width="1080" height="1080"/>'));
        svg = string(abi.encodePacked(svg, '<rect x="51.89" y="51.89" width="976.21" height="976.21"/>'));
        svg = string(abi.encodePacked(svg, '<rect fill="#00b1ff" x="74.87" y="74.87" width="166.06" height="166.06"/><polygon fill="#f0f" points="126.76 126.82 126.76 95.62 220.17 95.62 220.17 220.17 189.03 220.17 189.03 189.03 157.9 189.03 157.9 157.9 189.03 157.9 189.03 126.76 126.76 126.82"/><polygon fill="#ffe100" points="189.03 188.97 189.03 220.17 95.62 220.17 95.62 95.62 126.76 95.62 126.76 126.76 157.9 126.76 157.9 157.9 126.76 157.9 126.76 189.03 189.03 188.97"/><rect x="157.9" y="126.76" width="31.14" height="31.14"/><rect x="126.76" y="157.9" width="31.14" height="31.14"/>'));

        if(bytes(payload).length > 0) {
            uint256 lines = bytes(payload).length / maxLineLength;
            string memory text;
            uint256 y;
            for(uint256 i=0; i<=lines; i++) {
                y = 300 + 40*i;
                uint256 slice2 = (i+1)*maxLineLength;
                if(slice2 > bytes(payload).length) {
                    slice2 = bytes(payload).length;
                }
                text = getSlice(i*maxLineLength+1, slice2, payload);
                svg = string(abi.encodePacked(svg, '<text x="50%" y="', toString(y), 'px" fill="', color2, '" font-family="monospace" font-size="40px" font-weight="bold" text-anchor="middle">', text, '</text>'));
            }
        } else if(tokenId > 12) {
            svg = string(abi.encodePacked(svg, '<text x="50%" y="50%" class="base" fill="', color2, '" font-family="monospace" font-size="40px" font-weight="bold" text-anchor="middle">LORE COMING SOON</text>'));
        } else {
            string memory text;
            if(questSolved > 0) {
                text = 'SOLVED';
            } else {
                text = quest.clue;
            }

            svg = string(abi.encodePacked(svg, '<rect fill="', color2, '" x="74.57" y="839.07" width="166.36" height="166.36"/>'));
            svg = string(abi.encodePacked(svg, '<rect fill="', color3, '" x="839.07" y="839.07" width="166.61" height="166.61"/>'));

            string[5] memory parts;
            parts[0] = string(abi.encodePacked('<text x="50%" y="120" class="base" fill="', color2, '" font-family="monospace" font-size="40px" font-weight="bold" text-anchor="middle">', quest.feature, '</text>'));
            parts[1] = string(abi.encodePacked('<text x="50%" y="50%" class="base" fill="', color2, '" font-family="monospace" font-size="40px" font-weight="bold" text-anchor="middle">', text, '</text>'));
            parts[2] = string(abi.encodePacked('<text x="50%" y="980" class="base" fill="', color2, '" font-family="monospace" font-size="40px" font-weight="bold" text-anchor="middle">', quest.keyword, '</text>'));
            parts[3] = string(abi.encodePacked('<text x="925" y="945" class="base" fill="#000000" font-family="monospace" font-size="60px" font-weight="bold" text-anchor="middle">', quest.cipher, '</text>'));
            parts[4] = string(abi.encodePacked('<text x="155" y="945" class="base" fill="#000000" font-family="monospace" font-size="60px" font-weight="bold" text-anchor="middle">#', toString(tokenId), '</text>'));
            svg = string(abi.encodePacked(svg, parts[0], parts[1], parts[2], parts[3], parts[4]));
        }

        svg = string(abi.encodePacked(svg, '</svg>'));
    }

    function toString(uint256 value) public pure returns (string memory) {
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

    function toStringBool(bool value) public pure returns (string memory) {
        if(value) {
            return "true";
        }
        return "false";
    }

    function getSlice(uint256 begin, uint256 end, string memory text) public pure returns (string memory) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i=0;i<=end-begin;i++){
            a[i] = bytes(text)[i+begin-1];
        }
        return string(a);
    }

}
