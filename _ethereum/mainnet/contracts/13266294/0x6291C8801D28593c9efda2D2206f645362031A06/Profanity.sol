//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

import "./console.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./ProfanityLib.sol";
import "./NPass.sol";

// todo: string utils attribution

/**
 * @title Profanity Contract
 * @author @shinyhands
 * @notice This contract allows n-project holders to mint a Profranity via n
 */
contract Profanity is NPass {
    using Strings for uint256;

    constructor(address _nContractAddress)
        NPass(_nContractAddress, "Profanity", "PROFANITY", false, 4444, 0, 35000000000000000, 50000000000000000) {}

    struct WordInfo {
        string first;
        string second;
        string third;
        string fourth;

        string wordsSvg;

        string animation;
        string wordCount;
        string phrase;
    }

    struct slice {
        uint _len;
        uint _ptr;
    }

    struct Traits {
        string animation;
        string overlayCount;
        string phrase;
        string words;
    }

    string constant BEGIN = '<svg viewBox="0 0 280 280" fill="#000000" xmlns="http://www.w3.org/2000/svg"><defs><style>';
    string constant BEGIN_2 = '</style></defs><style>.word { font-size: 19px; fill: rgba(0,0,0,.7); text-transform: "uppercase"; font-family: "Early GameBoy"; }.word-small { font-size: 14px; fill: rgba(0,0,0,.7); text-transform: "uppercase";  font-family: "Early GameBoy"; }</style>';
    string constant END = '</svg>';

    function random(uint max, uint seed, uint tokenId) private pure returns (uint) {
        // not really random, but since we can provide variations of the user's N as seeds it will do.
        uint randomHash = uint(keccak256(abi.encode(seed, tokenId)));
        return randomHash % max;
    }

    function generateWords(uint[8] memory nNumbers, uint tokenId) public view virtual returns (WordInfo memory) {
        WordInfo memory words;

        // Calculate Animations
        string memory animation = '';
        uint animationChance = random(100, nNumbers[5], tokenId);
        if (animationChance <= 15) {
            words.animation = 'Blink';
            animation = '<animate attributeName="fill" values="rgba(0,0,0,.7);transparent" begin="0s" dur="2s" calcMode="discrete" repeatCount="indefinite" />';
        } else if (animationChance <= 50) {
            words.animation = 'Colors';
            animation = string(abi.encodePacked('<animate attributeName="fill" values="', ProfanityLib.getColorScheme(nNumbers[6], tokenId), '" begin="0s" dur="2s" calcMode="discrete" repeatCount="indefinite" />'));
        } else {
            words.animation = 'None';
        }

        (words.first, words.second, words.third, words.fourth) = ProfanityLib.getWords(nNumbers[0] + nNumbers[1] + nNumbers[2], nNumbers[1] + nNumbers[2] + nNumbers[3], nNumbers[2] + nNumbers[3] + nNumbers[4], nNumbers[3] + nNumbers[4] + nNumbers[5], tokenId);

        uint TYPE = random(100, nNumbers[7], tokenId);
        if (TYPE < 33) {
            words.third = words.fourth;

            words.phrase = words.third;
            words.wordCount = '1';

            words.wordsSvg = string(abi.encodePacked('<text x="50%" y="50%" class="word" dominant-baseline="middle" text-anchor="middle">', words.third, animation, '</text>'));
        } else if (TYPE >= 66) {
            words.phrase = string(abi.encodePacked(words.second, ' ', words.third));
            words.wordCount = '2';

            words.wordsSvg = string(abi.encodePacked(
                '<text x="50%" y="40%" class="word" dominant-baseline="middle" text-anchor="middle">', words.second, animation, '</text>',
                '<text x="50%" y="60%" class="word" dominant-baseline="middle" text-anchor="middle">', words.third, animation, '</text>'
            ));
        } else {
            words.phrase = string(abi.encodePacked(words.first, ' ', words.second, ' ', words.third));
            words.wordCount = '3';
            
            words.wordsSvg = string(abi.encodePacked(
                '<text x="50%" y="30%" class="word-small" dominant-baseline="middle" text-anchor="middle">', words.first, '</text>',
                '<text x="50%" y="50%" class="word" dominant-baseline="middle" text-anchor="middle">', words.second, animation, '</text>',
                '<text x="50%" y="70%" class="word-small" dominant-baseline="middle" text-anchor="middle">', words.third, '</text>'
            ));
        }

        return words;
    }

    function getOverlays(uint[8] memory nNumbers, uint tokenId) public pure returns (string[2] memory, string memory) {
        string[2] memory overlays;
        string memory overlayCount;

        uint overlayChance = random(100, nNumbers[0], tokenId);
        overlayCount = "0";

        if (overlayChance > 33) {
            overlayCount = "1";
            overlays[1] = string(abi.encodePacked('<polygon points="', random(280, nNumbers[1], tokenId).toString(), ', 0 ', random(280, nNumbers[6], tokenId).toString(), ', 280 ', random(100, nNumbers[1] + nNumbers[2], tokenId) > 50 ? '280, 280 280, 0' : ', 0, 280 0, 0', '" fill="#000000" fill-opacity="0.3" />'));
        }

        if (overlayChance > 66) {
            overlayCount = "2";
            overlays[0] = string(abi.encodePacked('<polygon points="0, ', random(280, nNumbers[0], tokenId).toString(), ' 280, ', random(280, nNumbers[6] + nNumbers[7], tokenId).toString(), random(100, nNumbers[2], tokenId) > 50 ? ' 280, 280 0, 280' : " 280, 0 0, 0", '" fill="#000000" fill-opacity="0.3" />'));
        }

        return (overlays, overlayCount);
    }

    function tokenSVG(uint256 tokenId) public view virtual returns (string memory, string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        Traits memory traits;
        uint[8] memory nNumbers = [
            n.getFirst(tokenId),
            n.getSecond(tokenId),
            n.getThird(tokenId),
            n.getFourth(tokenId),
            n.getFifth(tokenId),
            n.getSixth(tokenId),
            n.getSeventh(tokenId),
            n.getEight(tokenId)
        ];

        // Calculate Overlays
        string[2] memory overlays;
        (overlays, traits.overlayCount) = getOverlays(nNumbers, tokenId);

        WordInfo memory wordInfo = generateWords(nNumbers, tokenId);
        string memory SVG = string(abi.encodePacked(
            BEGIN,
            ProfanityLib.getFontFace(),
            BEGIN_2,
            '<rect width="100%" height="100%" fill="hsl(', (random(255, nNumbers[3], tokenId)).toString(), ', ', (random(100, nNumbers[4], tokenId)).toString(),'%, 50%)" />',
            overlays[0],
            overlays[1],
            wordInfo.wordsSvg,
            END
        ));        

        string memory attributes = string(abi.encodePacked('[{"trait_type": "Animation", "value": "', wordInfo.animation, '"}, {"trait_type": "Overlays", "value": "', traits.overlayCount, '"}, {"trait_type": "Phrase", "value": "', wordInfo.phrase, '"}, {"trait_type": "Lines", "value": "', wordInfo.wordCount, '"}]'));

        return (SVG, attributes);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        (string memory output, string memory attributes) = tokenSVG(tokenId);

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Profanity #',
                        tokenId.toString(),
                        '", "description": "Profanity.  100% on chain fuckery.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '", "attributes": ', attributes, '}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
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
