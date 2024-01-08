// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./console.sol";

/*
A Linked Tree Of The Logged Universe:
An experiment in collaborative creative storytelling in The Logged Universe from Untitled Frontier.
Each story node is an NFT, and each story node MUST point to a previous story.
To continue telling the story, merely point to a previous story node and mint your addition.
Words are compiled into an NFT image from on-chain SVG.
NOTE: This is experimental and not audited. The SVG might break. And under some circumstances, the rendering might not work properly. Basically, don't submit weird formatted text and you'll be fine.
It costs a ~ 450k of gas to store 512 bytes, so it can be expensive. Play with accordingly.
Partly inspired by Loot Project + Kalen Iwamoto's "Few Understand" series, linking text NFTs to each other. https://opensea.io/collection/kalen-iwamoto.
*/

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract TreeVerseChecker {
    function returnBytesOfStory(string memory story) public pure returns (bytes memory) {
        return bytes(story);
    }

    function returnBytesLengthOfStory(string memory story) public pure returns (uint256) {
        return bytes(story).length;
    }

    function generateImage(string memory story) public view returns (string memory) {
        // string memory story = stories[tokenId];
        bytes memory bs = bytes(story);
        require(bs.length < 512, "Story is too long!");
        string memory textBoxes = "";
        uint256 amount = 1;
        uint256 offset = 0;
        uint256 e = 60;

        for (uint i = 0; i<bs.length; i+=e-offset) {
            console.log(i);
            offset = 0;
            if(i+e > bs.length) {
                textBoxes = string(abi.encodePacked(textBoxes, '<text x="20" y="',toString(60+amount*20),'" class="base">',substring(story,i,bs.length),'</text>'));
            } else {
                // somewhat inefficient hack to wrap words.
                // CAN break in some circumstances
                while(bs[i+e-offset] != " ") {
                    offset+=1;
                }
                console.log(offset);    
                textBoxes = string(abi.encodePacked(textBoxes, '<text x="20" y="',toString(60+amount*20),'" class="base">',substring(story,i,i+e-offset),'</text>'));
            }
            amount += 1;
        }

        return string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 300 300"><style>.base { fill: white; font-family: serif; font-size: 10px; }</style><rect width="100%" height="100%" fill="black" />',
                '<text x="20" y="20" class="base">Story Node #',toString(4000),'</text>',
                '<text x="20" y="40" class="base">Linked To Node #',toString(3999),'</text>',
                textBoxes,
                '</svg>'
            )
        );
    }    
    
    // GENERIC helpers

    // from: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Strings.sol
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

    // from: https://ethereum.stackexchange.com/questions/31457/substring-in-solidity/31470
    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }
}