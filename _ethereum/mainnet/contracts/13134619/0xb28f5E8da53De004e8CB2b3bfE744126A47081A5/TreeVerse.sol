// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Base64.sol";

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
contract TreeVerse is ERC721 {

    address public owner = 0xaF69610ea9ddc95883f97a6a3171d52165b69B03; // for OpenSea storefront integration. Doesn't do anything in-contract.

    mapping(uint256 => string) public stories;
    mapping(uint256 => uint256) public link;

    uint256 public totalSupply = 0;
    
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        _mintStoryToAddress(owner, 0, "A simulated eternity sprawled in front of them: a veritable meta heaven. Anything and everything they could dream of. However, they soon realised that humans weren't made to live for aeons...");
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory name = string(abi.encodePacked('Node #', toString(tokenId)));
        string memory description = "A Story Node In The Linked Tree Of The Logged Universe";
        string memory image = generateBase64Image(tokenId);

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', 
                            name,
                            '", "description":"', 
                            description,
                            '", "image": "', 
                            'data:image/svg+xml;base64,', 
                            image,
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function generateBase64Image(uint256 tokenId) public view returns (string memory) {
        return Base64.encode(bytes(generateImage(tokenId)));
    }

    function generateImage(uint256 tokenId) public view returns (string memory) {

        string memory story = stories[tokenId];
        bytes memory bs = bytes(story);
        string memory textBoxes = "";
        uint256 amount = 1;
        uint256 offset = 0;
        uint256 e = 60;

        for (uint i = 0; i<bs.length; i+=e-offset) {
            offset = 0;
            if(i+e > bs.length) {
                textBoxes = string(abi.encodePacked(textBoxes, '<text x="20" y="',toString(60+amount*20),'" class="base">',substring(story,i,bs.length),'</text>'));
            } else {
                // somewhat inefficient hack to wrap words.
                // CAN break in some circumstances
                while(bs[i+e-offset] != " ") {
                    offset+=1;
                }    
                textBoxes = string(abi.encodePacked(textBoxes, '<text x="20" y="',toString(60+amount*20),'" class="base">',substring(story,i,i+e-offset),'</text>'));
            }
            amount += 1;
        }

        return string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 300 300"><style>.base { fill: white; font-family: serif; font-size: 10px; }</style><rect width="100%" height="100%" fill="black" />',
                '<text x="20" y="20" class="base">Story Node #',toString(tokenId),'</text>',
                '<text x="20" y="40" class="base">Linked To Node #',toString(link[tokenId]),'</text>',
                textBoxes,
                '</svg>'
            )
        );
    }
    

    function _mintStoryToAddress(address newOwner, uint256 prevStoryId, string memory story) internal {
        if(totalSupply != 0) {
            require(_exists(prevStoryId), "No such previous story exists");
        } 
        require(bytes(story).length < 512, "Too much text");

        stories[totalSupply] = story;
        link[totalSupply] = prevStoryId;
        super._mint(newOwner, totalSupply);
        totalSupply += 1;
    }

    function mintStory(uint256 prevStoryId, string memory story) public {
        _mintStoryToAddress(msg.sender, prevStoryId, story);
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