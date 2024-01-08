// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

interface CryptoPunksAssets {
    function composite(bytes1, bytes1, bytes1, bytes1, bytes1) external view returns (bytes4);
    function getAsset(uint8) external view returns (bytes memory);
    function getAssetName(uint8) external view returns (string memory);
    function getAssetIndex(string calldata, bool) external view returns (uint8);
}

interface CryptoPunksData {
    function punkAttributes(uint16) external view returns (string memory);
}

contract HivePunks is ERC721Enumerable, Ownable {
    CryptoPunksAssets private cryptoPunksAssets;
    CryptoPunksData private cryptoPunksData;

    uint16 private constant MAX_COUNT = 10000;
    uint8 private MAX_MINT_PER_TRANSACTION = 10;
    uint256 private PRICE_IN_WEI = 20000000000000000;
    uint256 private SEED;

    mapping(uint16 => uint16) private nextIndexList;
    mapping(uint16 => uint16) private previousIndexList;
    mapping(uint8 => uint16) private pointers;
    uint8 private constant POINTER_COUNT = 10;

    mapping(uint16 => bytes) private punks;
    mapping(uint16 => uint16) private ogPunks;

    constructor() ERC721("HivePunks", "HIVE") {
        cryptoPunksAssets = CryptoPunksAssets(0x2A256814597B4e3BE62ac0e599Bee9D7bED8C3cf);
        cryptoPunksData = CryptoPunksData(0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2);
        for (uint8 pointerIndex = 0; pointerIndex < POINTER_COUNT; ++pointerIndex) {
            pointers[pointerIndex] = uint16(nextPseudoRandom(MAX_COUNT) + 1);
        }
    }

    function setMintPrice(uint256 priceInWei, uint8 maxPerTransaction) external onlyOwner {
        PRICE_IN_WEI = priceInWei;
        MAX_MINT_PER_TRANSACTION = maxPerTransaction;
    }

    address private constant giveDirectlyDonationAddress = 0xc7464dbcA260A8faF033460622B23467Df5AEA42;
    
    function withdraw() external onlyOwner {
        uint256 donation = address(this).balance / 10;
        payable(giveDirectlyDonationAddress).transfer(donation);
        payable(owner()).transfer(address(this).balance); 
    }
    
    function tokenURI(uint256 index) public view override returns (string memory)
    {
        require(_exists(index));
        
        uint16 punkIndex = uint16(index);
        bytes memory punkAssets = new bytes(8);
        for (uint8 j = 0; j < 8; j++) {
            punkAssets[j] = punks[punkIndex][j];
        }

        string memory json = base64Encode(abi.encodePacked(
            '{"name": "HivePunk #',
            Strings.toString(index), 
            '", "description": "HivePunks are the slightly distorted twins of the original CryptoPunks. All metadata and images are fully generated and stored on-chain. Inspired by LarvaLabs (not affiliated).", "image": "data:image/svg+xml;base64,', 
            base64Encode(bytes(punkAssetsImageSvg(punkAssets))), 
            '", "attributes": [',
            metadataAttributes(punkAssets, punkIndex),
            ']}'));

        return string(abi.encodePacked('data:application/json;base64,', json));
    }
    
    function mintPunk() public payable {
        uint16 index = uint16(totalSupply());
        require(index < MAX_COUNT, "Total cap reached");
        require(PRICE_IN_WEI <= msg.value, "Insufficient Ether sent");

        uint16 punkIndex = nextIndex();

        punks[index] = parseAssets(cryptoPunksData.punkAttributes(punkIndex));
        ogPunks[index] = punkIndex;

        _mint(msg.sender, index);
    }
    
    function mintPunks(uint8 numberOfPunks) external payable {
        require(numberOfPunks <= MAX_MINT_PER_TRANSACTION);
        require((numberOfPunks * PRICE_IN_WEI) <= msg.value, "Insufficient Ether sent");

        for (uint16 i = 0; i < numberOfPunks; ++i) {
            mintPunk();
        }
    }
    
   function parseAssets(string memory attributes) internal view returns (bytes memory punkAssets) {
        punkAssets = new bytes(8);
        bytes memory stringAsBytes = bytes(attributes);
        bytes memory buffer = new bytes(stringAsBytes.length);

        uint index = 0;
        uint j = 0;
        bool isMale;
        for (uint i = 0; i < stringAsBytes.length; i++) {
            if (i == 0) {
                isMale = (stringAsBytes[i] != "F");
            }
            if (stringAsBytes[i] != ",") {
                buffer[j++] = stringAsBytes[i];
            } else {
                punkAssets[index++] = bytes1(getAssetIndex(bufferToString(buffer, j), isMale));
                i++; // skip space
                j = 0;
            }
        }
        if (j > 0) {
            punkAssets[index++] = bytes1(getAssetIndex(bufferToString(buffer, j), isMale));
        }
    }

    function appendAttribute(string memory prefix, string memory key, string memory value, bool asString, bool asNumber, bool append) internal pure returns (string memory text) {
        string memory quote = asString ? '"' : '';
        string memory displayType = asNumber ? '"display_type": "number", ' : '';
        string memory attribute = 
            string(abi.encodePacked('{ ', displayType, '"trait_type": "', key, '", "value": ', quote, value, quote, ' }'));
        if (append) {
            text = string(abi.encodePacked(prefix, ', ', attribute));
        } else {
            text = attribute;
        }
    }

    function metadataAttributes(bytes memory punkAssets, uint16 index) internal view returns (string memory text) {
        uint8 accessoryCount = 0;
        for (uint8 j = 0; j < 8; j++) {
            uint8 asset = uint8(punkAssets[j]);
            if (asset > 0) {
                if (j > 0) {
                    ++accessoryCount;
                    text = appendAttribute(text, "Accessory", getAssetName(asset), true, false, true);
                } else {
                    text = appendAttribute(text, "Type", getAssetName(asset), true, false, false);
                }
            } else {
                break;
            }
        }
        text = appendAttribute(text, "# Traits", Strings.toString(accessoryCount), false, false, true);
        text = appendAttribute(text, "CryptoPunk #", Strings.toString(ogPunks[index]), false, true, true);
    }
    
    function punkAssetsImage(bytes memory punkAssets) internal view returns (bytes memory) {
        bytes memory pixels = new bytes(2304);
        for (uint8 j = 0; j < 8; j++) {
            uint8 asset = uint8(punkAssets[j]);
            if (asset > 0) {
                bytes memory a = getAsset(asset);
                uint n = a.length / 3;
                for (uint i = 0; i < n; i++) {
                    uint[4] memory v = [
                        uint(uint8(a[i * 3]) & 0xF0) >> 4,
                        uint(uint8(a[i * 3]) & 0xF),
                        uint(uint8(a[i * 3 + 2]) & 0xF0) >> 4,
                        uint(uint8(a[i * 3 + 2]) & 0xF)
                    ];
                    for (uint dx = 0; dx < 2; dx++) {
                        for (uint dy = 0; dy < 2; dy++) {
                            uint p = ((2 * v[1] + dy) * 24 + (2 * v[0] + dx)) * 4;
                            if (v[2] & (1 << (dx * 2 + dy)) != 0) {
                                bytes4 c = composite(a[i * 3 + 1], pixels[p], pixels[p + 1], pixels[p + 2], pixels[p + 3]);
                                pixels[p] = c[0];
                                pixels[p+1] = c[1];
                                pixels[p+2] = c[2];
                                pixels[p+3] = c[3];
                            } else if (v[3] & (1 << (dx * 2 + dy)) != 0) {
                                pixels[p] = 0;
                                pixels[p+1] = 0;
                                pixels[p+2] = 0;
                                pixels[p+3] = 0xFF;
                            }
                        }
                    }
                }
            }
        }
        return pixels;
    }
    
    function composite(bytes1 index, bytes1 yr, bytes1 yg, bytes1 yb, bytes1 ya) internal view returns (bytes4) {
        return cryptoPunksAssets.composite(index, yr, yg, yb, ya);
    }
    
    function getAsset(uint8 index) internal view returns (bytes memory) {
        return cryptoPunksAssets.getAsset(index);
    }
    
    function getAssetName(uint8 index) internal view returns (string memory) {
        return cryptoPunksAssets.getAssetName(index);
    }
    
    function getAssetIndex(string memory text, bool isMale) internal view returns (uint8) {
        return cryptoPunksAssets.getAssetIndex(text, isMale);
    }

    function nextPseudoRandom(uint256 max) internal returns (uint) {
        SEED = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, SEED)));
        return SEED % max;
    }
    
    function nextIndex() internal returns (uint16) {
        uint8 pointerIndex = uint8(nextPseudoRandom(POINTER_COUNT));
        uint16 index = pointers[pointerIndex];
        uint8 stepCount = uint8(nextPseudoRandom(100));
        bool backwards = (nextPseudoRandom(2) == 0);
        uint16 previous;
        uint16 next;
        for (uint8 step = 0; step < stepCount; ++step) {
            if (backwards) {
                previous = previousIndexList[index];
                if (previous == 0) { 
                    previous = (index == 1) ? MAX_COUNT : index - 1;
                }
                index = previous;
            } else {
                next = nextIndexList[index];
                if (next == 0) {
                    next = (index == MAX_COUNT) ? 1 : index + 1;
                }
                index = next;
            }
        }
        previous = previousIndexList[index];
        if (previous == 0) { 
            previous = (index == 1) ? MAX_COUNT : index - 1;
        }
        next = nextIndexList[index];
        if (next == 0) {
            next = (index == MAX_COUNT) ? 1 : index + 1;
        }
        nextIndexList[previous] = next;
        previousIndexList[next] = previous;
        pointers[pointerIndex] = next;
        for (pointerIndex = 0; pointerIndex < POINTER_COUNT; ++pointerIndex) {
            if (pointers[pointerIndex] == index) {
                pointers[pointerIndex] = next;
            }
        }
        return (index - 1);
    }
    
    string private constant SVG_HEADER = '<svg id="crisp" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMidYMax meet" viewBox="0 0 350 350"><rect x="0" y="0" width="350" height="350" fill="#333333"/>';
    string private constant SVG_FOOTER = '<style>#crisp{shape-rendering: crispEdges;}</style></svg>';

    function punkAssetsImageSvg(bytes memory punkAssets) internal view returns (string memory svg) {
        bytes memory pixels = punkAssetsImage(punkAssets);
        svg = string(abi.encodePacked(SVG_HEADER));
        for (uint y = 0; y < 24; y++) {
            for (uint x = 0; x < 24; x++) {
                uint p = (y * 24 + x) * 4;
                if (uint8(pixels[p + 3]) > 0) {
                    bytes4 color = bytes4(
                        (uint32(uint8(pixels[p])) << 24) |
                        (uint32(uint8(pixels[p+1])) << 16) |
                        (uint32(uint8(pixels[p+2])) << 8) |
                        (uint32(uint8(pixels[p+3]))));
                    svg = string(abi.encodePacked(
                        svg, 
                        polygonSvg(((y % 2) == 0 ? 17 : 10) + (14 * x), 37 + (12 * y), color)));
                }
            }
        }
        svg = string(abi.encodePacked(svg, SVG_FOOTER));
    }

    bytes16 private constant HEX_SYMBOLS = "0123456789ABCDEF";

    function polygonSvg(uint x, uint y, bytes4 color) internal pure returns (string memory) {
        bytes memory opaqueBuffer = new bytes(6);
        bytes memory buffer = new bytes(8);
        bool isOpaque = false;
        for (uint i = 0; i < 4; i++) {
            uint8 value = uint8(color[i]);
            buffer[i * 2 + 1] = HEX_SYMBOLS[value & 0xf];
            buffer[i * 2] = HEX_SYMBOLS[(value >> 4) & 0xf];
            if (i < 3) {
                opaqueBuffer[i * 2] = buffer[i * 2];
                opaqueBuffer[i * 2 + 1] = buffer[i * 2 + 1];
            } else if (value == 255) {
                isOpaque = true;
            } else if (value == 0) {
                return '';
            }
        }
        return string(abi.encodePacked(
            '<polygon points="', polygonPoints(x, y, false), ',', polygonPoints(x, y, true), 
            '" fill="#', isOpaque ? string(opaqueBuffer) : string(buffer), '"/>'));
    }
    
    function polygonPoints(uint x, uint y, bool left) internal pure returns (string memory) {
        return string(abi.encodePacked(
                Strings.toString(x), ',', Strings.toString(left ? y - 8 : y + 8), ',',
                Strings.toString(left ? x - 7 : x + 7), ',', Strings.toString(left ? y - 4 : y + 4), ',',
                Strings.toString(left ? x - 7 : x + 7), ',', Strings.toString(left ? y + 4 : y - 4)));
    }

    function bufferToString(bytes memory buffer, uint length) internal pure returns (string memory text) {
        bytes memory stringBuffer = new bytes(length);
        for (uint i = 0; i < length; ++i) {
            stringBuffer[i] = buffer[i];
        }
        text = string(stringBuffer);
    }
    
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    // [MIT License]
    // @author Brecht Devos <brecht@loopring.org>
    function base64Encode(bytes memory data) internal pure returns (string memory) {
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
            } lt(i, len) {} {
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
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}
