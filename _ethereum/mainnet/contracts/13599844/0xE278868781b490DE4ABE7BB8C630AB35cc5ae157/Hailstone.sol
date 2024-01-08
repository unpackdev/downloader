//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";


// ABOUT: HAILSTONE is a work in solidity celebrating the Collatz conjecture.
//        https://en.wikipedia.org/wiki/Collatz_conjecture
//
//        HAILSTONE implements the Collatz algorithm in reverse to create a
//        path of NFTs away from the seed number 1

// HOW-TO: Each HAILSTONE NFT has a unique tokenId.
//
//         The last tokenId minted at any time becomes "head".
//
//         Head can be found by calling the head() function.
//
//         HAILSTONEs can be minted by calling the mint() function
//         while providing the next tokenId as the message value in wei.
//
//         The next tokenId/wei must be either:
//         head * 2
//         or
//         (head - 1) / 3    [if such a value exists, is odd, and not divisible by 3]
//
//         Thus the head will move up and down as a combination of human rationale
//         and the constraints of the algorithm. Together all minters will create
//         a unique Collatz path through the integers.
//
//         The Collatz algorithm and head value alone contain enough information
//         to traverse all previous HAILSTONE NFTs' tokenIds back to HAILSTONE 1.


contract Hailstone is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Bitmask for uint256;

    uint constant MAX_UINT = 2**256 - 1;

    constructor()
    ERC721("HAILSTONE", "HAILS") {
        _mint(msg.sender, head);
    }


    ///////
    // Core
    ///////

    uint public head = 1;

    function mint() external payable nonReentrant() {
        uint msgValue = msg.value;

        if (msgValue == nextHigher(head) || msgValue == nextLower(head)) {
            checkGatewayTimeout();
            head = msgValue;
            _safeMint(_msgSender(), msgValue);
            return;
        }

        revert("message value was not a valid next step in sequence");
    }

    function nextHigher(uint _h) internal pure returns (uint) {
        return 2 * _h;
    }

    function nextLower(uint _h) internal pure returns (uint) {
        // Only proceed if (_h - 1) / 3 is an integer and is odd
        // NOTE: Because we first check that _h % 3 == 1 we know
        //       that _h / 3 will produce the same result as (_h - 1) / 3
        //       because the remainer of _h / 3 is always 1 and
        //       is always truncated in integer division by 3
        if (_h % 3 != 1 || (_h / 3) % 2 == 0) {
            return MAX_UINT;
        }

        // NOTE: Once you reach a head divisible by 3 you can only
        //       keep doubling forever *I think* (>_<). This is no fun
        //       so we catch this before we get to that situation.
        if (((_h / 3) % 3 == 0)) {
            return MAX_UINT;
        }

        // NOTE: (1 - 1) % 3 == 0, we don't want to go to 0 so we special-case reject 1->0
        // NOTE: 1->2->4->1 is a cycle, we break it by special-case rejecting 4->1
        if (_h == 1 || _h == 4) {
            return MAX_UINT;
        }

        return _h / 3;
    }

    function adminWithdraw(uint _amount) external {
        (bool success, ) = payable(owner()).call{ value: _amount }("");
        require(success, "nope");
    }


    ///////////////
    // Core [Extra]
    ///////////////

    bool public easyMode;

    function adminEasyMode(bool _b) external onlyOwner() {
        easyMode = _b;
    }

    modifier onlyEasyMode() {
        require(easyMode, "get head + use a calculator :)");
        _;
    }

    function getNextHigher() public view onlyEasyMode() returns (uint) {
        return nextHigher(head);
    }

    function getNextLower() public view onlyEasyMode() returns (uint) {
        return nextLower(head);
    }

    // NOTE: Never public visiblity, it makes things too easy, less dynamic, and less fun.
    function getCheapest(uint _head) internal pure returns (uint) {
        uint low = nextLower(_head);

        if (low != MAX_UINT) {
            return low;
        }

        return nextHigher(_head);
    }

    function previous(uint _n) external pure returns (uint) {
        // NOTE: if _n == 1, we go to 1->4->2->1->...

        if (_n % 2 == 0) {
            return _n / 2;
        }

        return (3 * _n) + 1;
    }

    // NOTE: Not needed for current implementation, but maybe interesting..
    function getNth(uint _idx) public view returns (uint) {
        return getNthPure(_idx, totalSupply(), head);
    }

    function getNthPure(uint _idx, uint _supply, uint _head) public pure returns (uint v) {
        require(_idx > 0, "start counting at 1");
        require(_idx <= _supply, "idx can't be greater than supply");

        uint i = _supply;
        v = _head;

        while (true) {
            if (_idx == i) {
                return v;
            }

            if (v % 2 == 0) {
                v = v / 2;
            } else {
                v = 3 * v + 1;
            }

            i--;
        }
    }


    /////////////////////
    // Token URI and JSON
    /////////////////////

    function tokenURI(uint _tokenId) public view override returns (string memory output) {
        uint vis = customVis[_tokenId];
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{',
            getJsonName(_tokenId),
            getJsonDescription(_tokenId),
            getJsonImage(_tokenId),
            getJsonAnimation(_tokenId, vis),
            '}'
        ))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
    }

    function getJsonName(uint _tokenId) internal pure returns (string memory) {
        return string(abi.encodePacked('"name": "HAILSTONE ', Conv.uintToString(_tokenId), '"'));
    }

    function getJsonDescription(uint _tokenId) internal pure returns (string memory) {
        return string(abi.encodePacked(',"description": "HAILSTONE ', Conv.uintToString(_tokenId), '"'));
    }

    function getJsonImage(uint _tokenId) internal pure returns (string memory) {
        return string(abi.encodePacked(',"image": "data:image/svg+xml;base64,', Base64.encode(bytes(HailImage.createSvgImage(_tokenId))), '"'));
    }

    function getJsonAnimation(uint _tokenId, uint _vis) internal view returns (string memory) {
        if (_vis.hasBit(FLAG_GRAPH_DISABLE)) {
            return "";
        }

        return string(abi.encodePacked(',"animation_url": "', createThreeGraph(_vis.hasBit(FLAG_GRAPH_LOG), head, _tokenId) ,'"'));
    }


    ///////////////////////
    // Visualization Custom
    ///////////////////////

    uint8 constant FLAG_GRAPH_DISABLE = 0;
    uint8 constant FLAG_GRAPH_LOG = 1;

    mapping(uint => uint) customVis;

    modifier onlyApprovedOrOwner(uint _tokenId) {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "must be token owner/approved");
        _;
    }

    // NOTE: Token owners can customize thier specific token's visualization. While this should generally be
    //       unnecessary it may be useful in the listed circumstances:

    //  - The three.js IPFS content becomes unavailable and the contract owner is unable or unwilling
    //    to correct this.
    function customGraphDisable(uint _tokenId, bool _b) external onlyApprovedOrOwner(_tokenId) {
        customVis[_tokenId] = customVis[_tokenId].chooseBit(FLAG_GRAPH_DISABLE, _b);
    }

    //  - A user prefers the three.js graph to begin rendering as logarithmic rather than linear
    //    depending on A E S T H E T I C S and the current size and shape of the hailstone path.
    function customGraphLog(uint _tokenId, bool _b) external onlyApprovedOrOwner(_tokenId) {
        customVis[_tokenId] = customVis[_tokenId].chooseBit(FLAG_GRAPH_LOG, _b);
    }


    ///////////////////////////////
    // Visualization Three.JS Graph
    ///////////////////////////////

    string systemThreeUri = "ipfs://QmQk6NT44gE2Wy2VEMV2kpptyaNBTZ4oSQ2vZosAPNg13W";

    function adminThreeUri(string calldata _threeUri) external onlyOwner() {
        systemThreeUri = _threeUri;
    }

    function createThreeGraph(bool _log, uint _head, uint _tokenId) internal view returns (string memory) {
        string memory logStr = "";
        if (_log) {
            logStr = "&log=1";
        }

        return string(abi.encodePacked(
            systemThreeUri,
            "?head=", Conv.uintToString(_head),
            "&target=", Conv.uintToString(_tokenId),
            "&network=1",   // PROD: network=1 for prod
            logStr
        ));
    }

    // Up - Log
    // Down - Lin
    // Left Left - ?
    // Right Right - ?


    /////////////////////
    // Gateway Management
    /////////////////////

    function checkGatewayTimeout() internal view {
        // PROD: uncomment for prod
        require(balanceOf(msg.sender) < 2, "client gateway timeout"); // The Tourist [Chorus]
    }


    ////////////////////
    // Contract Metadata
    ////////////////////

    string systemContractImageUri = "ipfs://Qmc1ku4XyZyVrtgppnw3VpmQdg7hpZfppdsxGPNd97yddc";

    function adminContractImageUri(string calldata _contractImageUri) external onlyOwner() {
        systemContractImageUri = _contractImageUri;
    }

    function contractURI() public view returns (string memory output) {
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{'
                '"name": "HAILSTONE", '
                '"description": "HAILSTONE is a work in solidity celebrating the Collatz conjecture.", '
                '"image": "', systemContractImageUri, '" '
            '}'
        ))));

        output = string(abi.encodePacked('data:application/json;base64,', json));
    }
}


//////////////////////////
// Visualization SVG Image
//////////////////////////

library HailImage {
    function createSvgImage(uint _tokenId) external pure returns (string memory) {
        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">'
            '<style>'
                '@font-face {'
                    'font-family: "zen_kaku_gothic_new_light";'
                    'src: url(data:application/font-woff2;charset=utf-8;base64,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) format("woff2");'
                    'font-weight: light;'
                    'font-style: normal;'
                '} '
                '.base { fill: #222222; font-family: zen_kaku_gothic_new_light, sans-serif; text-anchor: middle } '
                '.tit { font-size: 30px; } '
                '.num { font-size: 32px; } '
                '.poly { fill: #22222244; transform-origin: center; } '
            '</style>'
            '<rect width="100%" height="100%" fill="#dbd8d6" />'
            '<text x="175" y="52" class="base tit">HAILSTONE</text>'
            '<text x="175" y="97" class="base num">', Conv.uintToString(_tokenId), '</text>'
            '<g transform-origin="center" transform="translate(0,20)">',
            polyLayer(_tokenId, 13, 11, true),
            polyLayer(_tokenId, 19, 17, true),
            polyLayer(_tokenId, 29, 23, true),
            extraPolys(_tokenId),
            '</g></svg>'
        ));
    }



    function extraPolys(uint _tokenId) internal pure returns (string memory out) {
        uint dig = countDigits(_tokenId);
        out = string(abi.encodePacked(
            polyLayer(_tokenId, 37, 31, dig > 2),
            polyLayer(_tokenId, 41, 43, dig > 3),
            polyLayer(_tokenId, 53, 47, dig > 5),
            polyLayer(_tokenId, 61, 59, dig > 10),
            polyLayer(_tokenId, 71, 67, dig > 15)
        ));
    }

    function polyLayer(uint _tokenId, uint _modX, uint _modY, bool _active) internal pure returns (string memory) {
        if (!_active) {
            return "";
        }

        return string(abi.encodePacked(
            '<polygon class="poly" points="175,173 177,175, 175,177 173,175" transform="scale(',
            Conv.uintToString(_tokenId % _modX),
            ',',
            Conv.uintToString(_tokenId % _modY),
            ')" />'
        ));
    }

    function countDigits(uint n) internal pure returns (uint r) {
        while (n > 0) {
            r += 1;
            n /= 10;
        }
    }

    function createContractImage() external pure returns (string memory) {
        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">'
            '<style>'
                '.poly { fill: #22222244; transform-origin: center; } '
            '</style>'
            '<rect width="100%" height="100%" fill="#dbd8d6" />'
            '<polygon class="poly" points="175,173 177,175, 175,177 173,175" transform="scale(13, 11)" />'
            '<polygon class="poly" points="175,173 177,175, 175,177 173,175" transform="scale(19, 17)" />'
            '<polygon class="poly" points="175,173 177,175, 175,177 173,175" transform="scale(29, 23)" />'
            '<polygon class="poly" points="175,173 177,175, 175,177 173,175" transform="scale(37, 31)" />'
            '<polygon class="poly" points="175,173 177,175, 175,177 173,175" transform="scale(43, 41)" />'
            '<polygon class="poly" points="175,173 177,175, 175,177 173,175" transform="scale(53, 47)" />'
            '<polygon class="poly" points="175,173 177,175, 175,177 173,175" transform="scale(61, 59)" />'
            '<polygon class="poly" points="175,173 177,175, 175,177 173,175" transform="scale(71, 67)" />'
            '</svg>'
        ));
    }
}


////////////////////
// Support Libraries
////////////////////

library Conv {
    // Copied from 'Loot', ty!
    function uintToString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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


/**
* @title Library implementing bitmask operations
* @author TruSet, modified by hailstone authors
* @dev A maximum of 256 bits can be operated on when storing bits in a uint256, so the bitIndex is a uint8
*/
library Bitmask {
    function hasBit(uint256 bits, uint8 bitIndex) internal pure returns (bool) {
        return (bits & (uint(1) << bitIndex)) > 0;
    }

    function setBit(uint256 bits, uint8 bitIndex) internal pure returns (uint256) {
        uint256 bit = (uint(1) << bitIndex);
        return bits | bit;
    }

    function unsetBit(uint256 bits, uint8 bitIndex) internal pure returns (uint256) {
        uint256 bitmask = ~(uint(1) << bitIndex);
        return bits & bitmask;
    }

    // added by hailstone authors
    function chooseBit(uint256 bits, uint8 bitIndex, bool b) internal pure returns (uint256) {
        if (b) {
            return setBit(bits, bitIndex);
        }

        return unsetBit(bits, bitIndex);
    }
}

