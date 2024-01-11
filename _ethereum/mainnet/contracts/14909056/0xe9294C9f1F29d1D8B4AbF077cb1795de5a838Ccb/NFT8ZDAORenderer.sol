// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Strings.sol";
import "./Base64.sol";

contract NFT8ZDAORenderer {
    using Strings for uint256;
    string public constant description = unicode"天地之间，一气而已。惟有动静，遂分阴阳；有老少，遂分四象。水者，太阴也；火者，太阳也；木者，少阳也；金者，少阴也；土者，阴阳老少，木火金水冲气所结也。——《子平真诠》";

    function renderStrings(
        uint256 tokenId,
        string memory name,
        string[] memory words
    ) external pure returns (string memory) {
        string memory svg = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
            '<style>.t { fill: white; font-family: sans-serif; font-size: ',
            words.length == 1 ? '196' : '128',
            'px; text-anchor: middle; dominant-baseline: auto; writing-mode: tb; }</style>',
            '<rect width="100%" height="100%" fill="black" />',
            '<text x="50%" y="50%" class="t">'
        ));
        for (uint256 i=0; i<words.length; ++i) {
            svg = string(abi.encodePacked(svg, words[i]));
        }
        svg = string(abi.encodePacked(svg, '</text></svg>'));
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{',
            '"name":"8ZDAO #', tokenId.toString(), ' - ', name, '",',
            '"description":"', description, '",',
            '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"',
            '}'
        ))));
        string memory output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }
}
