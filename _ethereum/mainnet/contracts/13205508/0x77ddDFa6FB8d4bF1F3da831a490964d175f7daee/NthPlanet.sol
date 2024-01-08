// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./NPassCore.sol";
import "./IN.sol";

/**@title Nth Planet
***@author @nth_planet (inspired by @t_snark and @knaveth)*/

contract NthPlanet is NPassCore {
    using Strings for uint256;

    constructor(address _nContractAddress) NPassCore("Nth Planet", "NTH", IN(_nContractAddress), 
    false, 10000, 8888, 25000000000000000, 50000000000000000) {}

    string constant GEN_FRAGMENT_1 = "https://nthpla.net/api/generate?sample=";
    string constant GEN_FRAGMENT_2 = "+intensity=";

    function dnaGenerator(uint256 tokenId) public view virtual returns (uint256, string memory) {
        string memory dna;

        uint256 total = n.getFirst(tokenId) + n.getSecond(tokenId);
        total = total + n.getThird(tokenId);
        total = total + n.getFourth(tokenId);
        total = total + n.getFifth(tokenId);
        total = total + n.getSixth(tokenId);
        total = total + n.getSeventh(tokenId);
        total = total + n.getEight(tokenId);

        if (total >= 40 && total <= 50) {
            dna = "ctggtgatgggctgtttattgaacaacaatatcgctgacactagtgacagacagcctcta";
        } else if (total >= 35 && total <= 55) {
            dna = "ggaggtttaccccgccctcgtgacgtcagactgctcccactggagtagtcacaagacacc";
        } else if (total >= 29 && total <= 61) {
            dna = "tacgctatatctcccacccccgcgatcttggctccgctaaacacactcagggtaacaccg";
        } else if (total >= 24 && total <= 66) {
            dna = "gctagacgaaagtccccgtggaccaccgtacacaactctattacctccaagttgcagacg";
        } else {
            dna = "ggactttaactccatacaaaaacgtagacgctcccccaattgaagctgaggcattaaata";
        }

        return (total / 10, dna);
    }

    function characterGenerator(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        (uint256 total, string memory dna) = dnaGenerator(tokenId);

        string[14] memory parts;
        parts[0] = GEN_FRAGMENT_1;
        parts[1] = dna;
        parts[2] = GEN_FRAGMENT_2;
        parts[3] = total.toString();

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3]));
        return output;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
            require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

            string memory output = "null";
            string memory baseURI = "https://nth-planet-api.herokuapp.com/api/token/";
            output = string(abi.encodePacked(baseURI, tokenId.toString()));

            return output;
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

