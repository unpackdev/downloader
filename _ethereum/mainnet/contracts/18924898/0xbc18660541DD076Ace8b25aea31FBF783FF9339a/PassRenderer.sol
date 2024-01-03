// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./Base64.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./strings.sol";

contract PassRenderer is Ownable {
    using Strings for uint256;
    using strings for *;

    function buildImage(uint256 tokenId, string calldata passName)
        public
        pure
        returns (string memory)
    {
        string memory zeros = '';
        string memory strTokenId = Strings.toString(tokenId);

        for (uint i=0; i<(6 - bytes(strTokenId).length); i++) {
            zeros = concatenateString(zeros, '0');
        }

        strTokenId = concatenateString(zeros, strTokenId);

        return Base64.encode(bytes(abi.encodePacked(
            '<svg version="1.1" id="" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="400" height="400" viewBox="0 0 400 400" xml:space="preserve">',
            '<defs>',
            '<linearGradient id="grad_card" x1="100%" y1="0%" x2="0%" y2="25%">',
            '<stop offset="0%" style="stop-color:#21022d" />',
            '<stop offset="37%" style="stop-color:#333" />',
            '<stop offset="48%" style="stop-color:#666" />',
            '<stop offset="50%" style="stop-color:#999" />',
            '<stop offset="52%" style="stop-color:#666" />',
            '<stop offset="63%" style="stop-color:#333" />',
            '<stop offset="100%" style="stop-color:#21022d" />',
            '</linearGradient>',
            '<linearGradient id="grad_refl" x1="50%" y1="0%" x2="50%" y2="100%">',
            '<stop offset="0%" style="stop-color:#111" />',
            '<stop offset="100%" style="stop-color:#fff" />',
            '</linearGradient>',
            '</defs>',
            '<rect width="400" height="400" fill="#fff" />',
            '<rect x="44.8" y="90" width="310.4" height="191.6" ry="9.2" style="fill:url(#grad_card);stroke:#555" />',
            '<path d="M44.8,317 h310.4 v-18.8 A 9.2,9.2 0 0,0 346,289 h-292 A 9.2,9.2 0 0,0 44.8,298.2 v18.8 z" style="fill:url(#grad_refl)" />',
            '<circle cx="123.5" cy="186" r="58.5" stroke="white" stroke-width="1%" style="fill:none" />',
            '<path d="m 101.5,157.5 A 35.5 35.5 0 0 1 146 158 l -5.8,3.2 A 30 30 0 0 0 107 161 l -5.5,-3.5" style="stroke:white;fill:white" />',
            '<path d="m 153.1,166 A 35.5 35.5 0 0 1 154.2 204.5 l -4.6,-4.7 A 30 30 0 0 0 149.8 172 l 3.3,-6" style="stroke:white;fill:white" />',
            '<path d="m 137.8,218.8 A 35.5 35.5 0 0 1 107.6 218.2 l 4.4,-5 A 30 30 0 0 0 133.4 214.2 l 4.4,4.6" style="stroke:white;fill:white" />',
            '<path d="m 92.6,203.8 A 35.5 35.5 0 0 1 92.8 167.4 l 3.8,5.4 A 30 30 0 0 0 97 199.4 l -4.4,4.4" style="stroke:white;fill:white" />',
            '<path d="m 114.3,167.9 A 20 20 0 0 1 133.5 168.3 l -4.5,2.7 Q 126,170 123.6,173.1 Q 120,169 117.7,170.4 z" style="stroke:white;fill:white" />',
            '<path d="m 105,192.5 A 20 20 0 0 1 104.2 182.1 l 1.2,1.2 Q 106,190 107,188.3 l 1.6,0.5 z" style="stroke:white;fill:white" />', 
            '<path d="m 142.7,179.6 A 20 20 0 0 1 142.2 192.6 l -2.8,-3.1 Q 142,184 140.5,182 z" style="stroke:white;fill:white" />',
            '<path d="m 123,145 l 0,23 l 2,0, l 0,-23 A 2 2 0 0 0 123 145 z" style="stroke:#fff;fill:white" />',
            '<path d="m 165.4,185 l -23,0 l 0,2, l 23,0 A 2 2 0 0 0 165.4 185 z" style="stroke:#fff;fill:white" />',
            '<path d="m 125,227 l 0,-21 l -1,-1.5 l -1,1.5 l 0,21 A 2 2 0 0 0 125 227 z" style="stroke:#fff;fill:white" />',
            '<path d="m 82.5,187 l 23,0 l 0,-2, l -23,0 A 2 2 0 0 0 82.5 187 z" style="stroke:#fff;fill:white" />',
            '<path d="M 92,157 c 0,0 0,0 0,0 0,0 0,0 0,0 z m 0,0 c 0.8,6 3.2,12 9.2,18 0,0 0.4,-0.4 0.4,-0.4 l 5.6,8.4 c 0,0 0,0 0,0 0,1.2 0.8,2.8 0.4,2.8 l 0.8,0.8 9.6,-9.6 c -0.8,-0.8 -1.6,-1.6 -2,-2 l 0.8,0.8 c 0,-0.4 0,-1.2 1.6,-1.2 0.4,0 0.8,0 1.6,0 l 0,0 1.2,-1.2 -1.04,-1.04 c -0.4,-0.4 -1.6,-0.4 -2.8,-0.4 l -8,-5.6 c 0,0 0.4,-0.4 0,-0.8 -6.4,-6 -11.2,-8.4 -17.6,-9.2 z m 3.2,1.2 c 1.2,0 4,1.6 5.6,2.4 5.6,3.2 6,3.6 8,5.6 l -7.2,-2 3.2,6 c -3.2,-3.2 -4.8,-4 -5.2,-4.8 -2.4,-2.8 -2.8,-3.2 -4,-4.4 -0.8,-0.8 -0.8,-1.6 -0.8,-2 0,0 0,0 0.4,0 z m 42.8,32 -1.2,1.2 15.6,15.2 c 0,1.44 -0.8,2 -1.2,3.2 -4.8,-4.8 -10.8,-10.8 -16.4,-16 l -9.6,9.6 14,14 c 0.8,0.8 1.6,0.8 2.4,0.8 l 0,1.2 c 0,2 3,1.2 4.8,0.8 2,-1.2 3.6,-2 4.8,-3.6 1.2,-1.2 2.4,-2.8 3.6,-4.8 0.4,-1.6 1.6,-4.4 -0.8,-4.8 l -1.2,0 c 0,-0.8 0,-1.6 -0.8,-2.4 z" style="fill:#fff" />',
            '<path d="m 155,157 c 0,0 0,0 0,0 0,0 0,0 0,0 0,0 0,0 0,0 z m 0,0 c 0,0 0,0 0,0 0,0 0,0 0,0 -6.8,0.8 -11.6,3.2 -17.6,9.2 0,0 0,0.4 0.4,0.8 l -8.4,5.6 c -1.2,0 -2.4,0 -2.8,0.4 l -31.2,30.8 c -0.8,0.8 -0.8,1.2 -0.8,2.4 l -1.2,0 c -2.0,0 -1.2,2.8 -0.8,4.4 1.2,2 2,3.6 3.6,4 1.2,1.2 2.8,2.4 4.8,3.6 1.6,0.4 4.4,1.6 4,-0.4 l 0,-1.2 c 0.8,0 2,0 2.4,-0.8 l 31.2,-30.8 c 0,0 0.4,-1.2 0.4,-2.8 0,0 0,0 0,0 l 5.6,-8 c 0,0 0.4,0.4 0.4,0.4 6.4,-6 8,-12 9.2,-18 z m -3.2,1.2 c 0,0 0.4,0 0.4,0 0,0.4 0,1.2 -0.8,2 -1.2,1.2 -1.6,2 -4.9,3.7 -1.8,1.8 -2.6,2.6 -5.8,3 l 3.6,-2.5 -7.2,2 c 2,-2 2.4,-2.4 8,-5.6 1.2,-0.8 4.8,-2.4 5.6,-2.4 z m -24,16.8 c 2.4,0 2,0.8 2,1.2 l 0.8,-0.8 c -4,2.8 -23.2,22.8 -34.8,34 -0.8,-1.2 -1.6,-1.6 -1.2,-3.2 l 32,-31.6 c 0.4,0 0.8,0 1.2,0 z" style="fill:#fff" />',
            '<path d="M 83.7,176.8 A 41 41 0 0 1 164.8 184.8" style="fill:none;stroke:none" id="tp1" />',
            '<text fill="#fff" stroke="#fff" stroke-width="0.2" font-size="14px" font-family="Berlin Sans FB" textLength="112"><textPath href="#tp1">MACHINEGUN</textPath></text>',
            '<text x="340" y="115" text-anchor="end" fill="#fff" font-size="10px" font-family="sans-serif">machinegun girl\'s pass</text>',
            '<text x="340" y="130" text-anchor="end" fill="#fff" font-size="8px" font-family="sans-serif">Ethereum</text>',
            '<text x="340" y="230" text-anchor="end" fill="#fff" font-size="8px" font-family="sans-serif">#', strTokenId, '</text>',
            '<path d="M 90,226.2 L 98.8,232.7" style="stroke:none;fill:none" id="path_g" />',
            '<path d="M 106,235.1 L 114.5,237.9" style="stroke:none;fill:none" id="path_i" />',
            '<path d="M 120,237.9 L 132.1,237.9" style="stroke:none;fill:none" id="path_r" />',
            '<path d="M 138.1,235.9 L 147.5,232.7" style="stroke:none;fill:none" id="path_l" />',
            '<path d="M 152.5,229.1 L 159.9,223.7" style="stroke:none;fill:none" id="path_s" />',
            '<text fill="#fff" stroke="#fff" stroke-width="0.2" font-size="10px" font-family="Arial"><textPath href="#path_g">G</textPath></text>',
            '<text fill="#fff" stroke="#fff" stroke-width="0.2" font-size="10px" font-family="Arial"><textPath href="#path_i">I</textPath></text>',
            '<text fill="#fff" stroke="#fff" stroke-width="0.2" font-size="10px" font-family="Arial"><textPath href="#path_r">R</textPath></text>',
            '<text fill="#fff" stroke="#fff" stroke-width="0.2" font-size="10px" font-family="Arial"><textPath href="#path_l">L</textPath></text>',
            '<text fill="#fff" stroke="#fff" stroke-width="0.2" font-size="10px" font-family="Arial"><textPath href="#path_s">S</textPath></text>',
            '<rect style="opacity:0.5;fill:#000" width="160" height="20" x="180" y="240" />',
            '<text x="332" y="254" text-anchor="end" fill="#fff" font-size="12px" font-family="sans-serif">', passName, '</text>',
            '</svg>'
        )));
    }

    function concatenateString(string memory a, string memory b)
        internal
        pure
        returns (string memory)
    {
        return a.toSlice().concat(b.toSlice());
    }
}