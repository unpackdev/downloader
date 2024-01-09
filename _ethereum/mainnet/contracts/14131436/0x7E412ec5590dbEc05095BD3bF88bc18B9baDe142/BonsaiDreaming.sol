// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";

contract BonsaiDreaming is ERC721Enumerable, Ownable, ReentrancyGuard {
    uint256 public constant MAX_TOKENS = 255;
    
    event MintedToken(address sender, uint256 tokenID);
    
    uint256 public PUBLIC_SALE_MINT_PRICE = 0.065 ether;
    uint256 public mintedBonsaiBitfield;
    uint256 public numberOfMints;
    bytes[] private _tokenDatas;
    mapping(uint8 => uint256) private _bonsaiIdxToTokenDataIdx;
    mapping(uint8 => uint8) private _backgroundCounts;
    mapping(uint8 => uint8) private _effectCounts;

    string[50] private _coordinateLookup;
    int8[8] private _deltaX;
    int8[8] private _deltaY;

    bool public mintingCompleteAndVerified;

    struct SVGCursor {
        bool rowEven;
        uint8 x; // primary pixels (every even pixel) has an x, y and color
        uint8 y;
        string color; // color is found in a 5-bit (32 color) LUT => 5 bit used for primary pixels
        int8 dx;  // secondary pixels have an offset (dx, dy) from where they copy a primary pixel
        int8 dy;  // there are 8 locations possible to copy from for each pixel => 3 bit used for secondary pixels
    }

    constructor() ERC721("BonsaiDreaming", "BONSAIDREAMING") {
        // base64-encoded svg coordinates from -2*8 to 47*8 (pixels render at 8x8 screen pixels)
        _coordinateLookup = [
          "LTE2", // -2
          "LTA4", // -1
          "MDAw", // 0
          "MDA4", // 1
          "MDE2", // ...
          "MDI0", "MDMy", "MDQw", "MDQ4", "MDU2", "MDY0", "MDcy", "MDgw", "MDg4", "MDk2", "MTA0", "MTEy", "MTIw", "MTI4", "MTM2", "MTQ0", "MTUy", "MTYw", "MTY4", "MTc2", "MTg0", "MTky", "MjAw", "MjA4", "MjE2", "MjI0", "MjMy", "MjQw", "MjQ4", "MjU2", "MjY0", "Mjcy", "Mjgw", "Mjg4", "Mjk2", "MzA0", "MzEy", "MzIw", "MzI4", "MzM2", "MzQ0", "MzUy", "MzYw", "MzY4", "Mzc2"];
        
        _deltaX = [-1, -1, 1, 1, 0, 2, 0, -2]; // these are used for decoding the relative coordinates of secondary pixels
        _deltaY = [-2, 0, 0, 2, -1, -1, 1, 1];
    }

    function getBackgroundCount(uint8 bgIdx) external view returns (uint8) {
        return _backgroundCounts[bgIdx];
    }

    function getEffectCount(uint8 effectIdx) external view returns (uint8) {
        return _effectCounts[effectIdx];
    }

    function getBonsaiIdx(uint256 tokenId) external view returns (uint8) {
        require(tokenId <= numberOfMints && tokenId > 0, "Invalid tokenId");
        uint8 retVal = 255; // invalid
        for(uint8 i = 0; i < 255; i++) {
            if(_bonsaiIdxToTokenDataIdx[i] == tokenId) {
                retVal = i;
            }
        }
        return retVal;
    }

    function _getBonsaiIdx(bytes memory tokenData) pure internal returns (uint8) {
        uint8 bonsaiIdx = 0;
        for (uint8 i = 0; i < 8; i++) {
            bonsaiIdx = bonsaiIdx | ((uint8(tokenData[i + 8]) & uint8(1)) << i);
        }
        require(bonsaiIdx < 255, "Invalid bonsaiIdx");
        return bonsaiIdx;
    }

    function _getBgIdx(bytes memory tokenData) pure internal returns (uint8) {
        uint8 bgIdx = 0;
        for (uint8 i = 0; i < 4; i++) {
            bgIdx = bgIdx | ((uint8(tokenData[i + 4]) & uint8(1)) << i);
        }
        return bgIdx;
    }

    function _getEffectIdx(bytes memory tokenData) pure internal returns (uint8) {
        uint8 effectIdx = 0;
        for (uint8 i = 0; i < 4; i++) {
            effectIdx = effectIdx | ((uint8(tokenData[i]) & uint8(1)) << i);
        }
        return effectIdx;
    }

    // tokenData needs to be 744 bytes
    // - first 96 represents the 32 colors using 3 bytes for each color, with metadata encoded in each LSB (bonsaiIdx, backgroundIdx, effectIdx) of the first 2 bytes
    // - next 648 bytes represents 2 pixels each of a 48*27 pixel image, using 5 bits for the first and 3 bits for the second pixel, i.e. 2 pixels per byte
    // - the lower 5 bits represent the color index of the primary pixel
    // - the upper 3 bits represent the offset index of the secondary pixel => on average 4 bits per pixel with 32 possible colors
    function mintPublicSale(bytes memory tokenData) external payable nonReentrant returns (uint256) {
        require(PUBLIC_SALE_MINT_PRICE == msg.value, "Incorrect amount of ether sent");
        require(tokenData.length == 744, "tokenData must be 744 bytes");
        require(numberOfMints < MAX_TOKENS, "All BonsaiDreaming have been minted");

        uint8 bonsaiIdx = _getBonsaiIdx(tokenData);
        uint256 tokenDataIdx = _bonsaiIdxToTokenDataIdx[bonsaiIdx];
        require(tokenDataIdx == 0, "This Bonsai has already been minted");

        tokenDataIdx = numberOfMints + 1;
        
        mintedBonsaiBitfield = mintedBonsaiBitfield | (uint256(1) << bonsaiIdx);
        _tokenDatas.push(tokenData);  // when looking up data, subtract 1 from tokenDataIdx
        _bonsaiIdxToTokenDataIdx[bonsaiIdx] = tokenDataIdx;

        uint8 bgIdx = _getBgIdx(tokenData);
        _backgroundCounts[bgIdx] += 1;

        uint8 effectIdx = _getEffectIdx(tokenData);
        _effectCounts[effectIdx] += 1;

        _safeMint(msg.sender, tokenDataIdx);
        numberOfMints++;

        emit MintedToken(msg.sender, tokenDataIdx);
        return tokenDataIdx;
    }

    // Hopefully this will never be used - it exists as a safeguard for preventing abuse, since any bytes can be pushed into the minting function.
    // This will only be used in the case of someone pushing "evil" photo material, copyrighted stuff, etc. - creative/fun use will be tolerated :)
    // Once minting is complete and verified, the function setMintingCompleteAndVerified() will be used to remove this functionality.
    // Big props to pixelations.xyz for the inspiration for this functionality.
    function overwriteExistingTokenData(bytes memory tokenData, uint256 tokenId) external onlyOwner nonReentrant {
        require(tokenData.length == 744, "tokenData must be 744 bytes");
        require(!mintingCompleteAndVerified, "Minting is complete and bytes cannot be changed anymore");
 
        uint8 bonsaiIdx = _getBonsaiIdx(tokenData);
        uint256 tokenDataIdx = _bonsaiIdxToTokenDataIdx[bonsaiIdx];
        require(tokenDataIdx > 0, "This Bonsai has not been minted");
        require(tokenId == tokenDataIdx, "Found bonsai != tokenId");

        _tokenDatas[tokenDataIdx - 1] = tokenData;
    }

    function setMintingCompleteAndVerified() external onlyOwner {
        mintingCompleteAndVerified = true;
    }

    // This returns the base64-encoded JSON metadata for the given token.  Metadata looks like this:
    // {
    //   "name": "Bonsai, Dreaming #10 ",
	//   "background_color": "000000",
	//   "description": "Hand-crafted bonsais, stored and rendered entirely on chain!",
	//   "attributes": [
	// 	  {
	// 	  	"trait_type": "background",
	//   		"value": 5
	// 	  },
	// 	  {
	// 	  	"trait_type": "effect",
	// 	  	"display_type": "number",
	//   		"value": 2
	// 	  }
	//   ],
	//   "image_data": "<svg>...</svg>"
    // }
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(tokenId <= numberOfMints && tokenId > 0, "Invalid tokenId");

        bytes memory tokenData = _tokenDatas[tokenId - 1];

        return
            string(
                abi.encodePacked(  // all strings are pre-base64 encoded to save gas
                    "data:application/json;base64,eyJuYW1lIjoiQm9uc2FpLCBEcmVhbWluZyAj",
                    Base64.encode(uintToByteString(tokenId, 3)),
                    "IiwgImJhY2tncm91bmRfY29sb3IiOiAiMDAwMDAwIiwgImRlc2NyaXB0aW9uIjogIkhhbmQtY3JhZnRlZCBib25zYWlzLCBzdG9yZWQgYW5kIHJlbmRlcmVkIGVudGlyZWx5IG9uIGNoYWluISIsICJhdHRyaWJ1dGVzIjpbeyJ0cmFpdF90eXBlIjogImJhY2tncm91bmQiLCAiZGlzcGxheV90eXBlIjogIm51bWJlciIsICJ2YWx1ZSI6",
                    Base64.encode(uintToByteString(_getBgIdx(tokenData) + 1, 3)),
                    "fSwgeyJ0cmFpdF90eXBlIjogImVmZmVjdCIsICJkaXNwbGF5X3R5cGUiOiAibnVtYmVyIiwgInZhbHVlIjog",
                    Base64.encode(uintToByteString(_getEffectIdx(tokenData) + 1, 3)),
                    "fV0sImltYWdlX2RhdGEiOiAi",
                    tokenSVG(tokenId),
                    "In0g"
                )
            );
    }

    // Handy function for only rendering the svg
    function tokenSVG(uint256 tokenId) public view returns (string memory) {
        require(tokenId <= numberOfMints && tokenId > 0, "Invalid tokenId");

        string[4] memory buffer = tokenSvgDataOf(tokenId);

        return
            string(
                abi.encodePacked(
                    "PHN2ZyB2ZXJzaW9uPScxLjEnIHZpZXdCb3g9JzAgMCAzODQgMjE2JyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHNoYXBlLXJlbmRlcmluZz0nY3Jpc3BFZGdlcyc+PGRlc2M+Qm9uc2FpLCBkcmVhbWluZyBwcm9qZWN0IDIwMjI8L2Rlc2M+",
                    buffer[0], buffer[1], buffer[2], buffer[3],
                    "PHN0eWxlPnJlY3R7d2lkdGg6OHB4O2hlaWdodDo4cHg7fTwvc3R5bGU+PC9zdmc+"
                )
            );
    }

    // The decoding performs a number of steps:
    // - First of all, the color map is decoded from the first 96 bytes of the encoded image, and stored in a string array for easy retrieval.
    // - Then a number of "nested" buffers are filled:
    //   - One 6th of a row (8 pixels) are generated 2 pixels at a time by calling the function twoPixels() with the relevant data, and collected in the oneSixthRow buffer
    //   - This is done 6 times, and collected in the rowBuffer
    //   - 8 rows are generated this way, and collected in the bufferOfRows (for the final iteration only 3 rows are collected, since we have 27 rows)
    //   - Finally these 3x8+3 rows are collected and returned
    // Big props to Chainrunners and pixelations.xyz for the inspiration for many of the functions below.
    function tokenSvgDataOf(uint256 tokenId) private view returns (string[4] memory) {
        SVGCursor memory cursor;

        string[32] memory colorMap;
        for (uint8 colorIndex = 0; colorIndex < 32; colorIndex++) {
            colorMap[colorIndex] = getColor(tokenId, colorIndex);
        }

        string[4] memory oneSixthRow;
        string[6] memory rowBuffer;

        string[8] memory bufferOfRows;
        uint8 indexIntoBufferOfRows;

        string[4] memory bufferOfEightRows;
        uint8 indexIntoBufferOfEightRows;

        cursor.y = 2; // offset to support "negative" y values down to -2 used in the LUT
        for (uint256 pixelIdx = 0; pixelIdx < 648; ) {
            cursor.rowEven = (cursor.x == 0);
            cursor.x += 2; // offset to support "negative" x values down to -2 used in the LUT
            
            // generate groups of 8 pixels (6 times)
            for (uint8 pixelGroupIdx = 0; pixelGroupIdx < 6; pixelGroupIdx++) {
                cursor.color = colorMap[getColorIndexFromPixelIndex(tokenId, pixelIdx)]; // primary pixel color is retrieved
                (cursor.dx, cursor.dy) = getOffsetsFromPixelIndex(tokenId, pixelIdx++); // secondary pixel offsets are retrieved
                oneSixthRow[0] = twoPixels(cursor);
                cursor.x += 2;

                cursor.color = colorMap[getColorIndexFromPixelIndex(tokenId, pixelIdx)];
                (cursor.dx, cursor.dy) = getOffsetsFromPixelIndex(tokenId, pixelIdx++);
                oneSixthRow[1] = twoPixels(cursor);
                cursor.x += 2;

                cursor.color = colorMap[getColorIndexFromPixelIndex(tokenId, pixelIdx)];
                (cursor.dx, cursor.dy) = getOffsetsFromPixelIndex(tokenId, pixelIdx++);
                oneSixthRow[2] = twoPixels(cursor);
                cursor.x += 2;

                cursor.color = colorMap[getColorIndexFromPixelIndex(tokenId, pixelIdx)];
                (cursor.dx, cursor.dy) = getOffsetsFromPixelIndex(tokenId, pixelIdx++);
                oneSixthRow[3] = twoPixels(cursor);
                cursor.x += 2;

                rowBuffer[pixelGroupIdx] = string(abi.encodePacked(oneSixthRow[0], oneSixthRow[1], oneSixthRow[2], oneSixthRow[3]));
            }

            // generate single row
            bufferOfRows[indexIntoBufferOfRows++] = string(abi.encodePacked(rowBuffer[0], rowBuffer[1], rowBuffer[2], rowBuffer[3], rowBuffer[4], rowBuffer[5]));
            
            cursor.y += 1; // proceed to next row
            cursor.x = cursor.y % 2; // since we have an even number of pixels on each line, odd lines need an offset of 1, to keep pixels spread in a checkerboard pattern
            
            // collect groups of 8 rows
            if (indexIntoBufferOfRows >= 8) {
                bufferOfEightRows[indexIntoBufferOfEightRows++] = string(
                    abi.encodePacked(bufferOfRows[0], bufferOfRows[1], bufferOfRows[2], bufferOfRows[3], bufferOfRows[4], bufferOfRows[5], bufferOfRows[6], bufferOfRows[7])
                );
                indexIntoBufferOfRows = 0;
            }
            // last group only has 3 rows
            if (indexIntoBufferOfEightRows == 3 && indexIntoBufferOfRows >= 3) {
                bufferOfEightRows[indexIntoBufferOfEightRows++] = string(
                    abi.encodePacked(bufferOfRows[0], bufferOfRows[1], bufferOfRows[2])
                );
                indexIntoBufferOfRows = 0;
            }
        }

        return bufferOfEightRows;
    }

    // Extracts the base64-encoded hex color for a single pixel.
    function getColor(uint256 tokenId, uint256 indexIntoColors) internal view returns (string memory) {
        uint256 n = uint256(uint8(_tokenDatas[tokenId - 1][indexIntoColors * 3])) << 16;
        n += uint256(uint8(_tokenDatas[tokenId - 1][indexIntoColors * 3 + 1])) << 8;
        n += uint256(uint8(_tokenDatas[tokenId - 1][indexIntoColors * 3 + 2]));

        return Base64.encode(uintToHexBytes6(n));
    }

    // Unpack the 5-bit value representing the color index for a given pixel (every even pixel)
    function getColorIndexFromPixelIndex(uint256 tokenId, uint256 pixelIndex) internal view returns (uint8) {
        return uint8(_tokenDatas[tokenId - 1][uint256(96) + pixelIndex]) & uint8(31);
    }

    // Unpack the 3-bit value representing the pixels to copy (every odd pixel)
    function getOffsetsFromPixelIndex(uint256 tokenId, uint256 pixelIndex) internal view returns (int8, int8) {
        uint8 offsetIdx = uint8(_tokenDatas[tokenId - 1][uint256(96) + pixelIndex]) >> 5;
        return (_deltaX[offsetIdx], _deltaY[offsetIdx]);
    }

    // This function generates 2 pixels decoded from a single byte (5 bits for primary pixel color, 3 bits for secondary pixel offsets)
    function twoPixels(SVGCursor memory pos) internal view returns (string memory) {
        int8 xOffset = pos.rowEven ? int8(1) : int8(-1);
        return string(abi.encodePacked(
                    "PHJlY3QgeD0n",  // (primary pixel) <rect ...
                    _coordinateLookup[pos.x],
                    "JyAgeT0n",
                    _coordinateLookup[pos.y],
                    "JyBmaWxsPScj",
                    pos.color,
                    "JyBpZD0n",
                    _coordinateLookup[pos.x],
                    _coordinateLookup[pos.y],
                    "Jy8+PHVzZSBocmVmPScj", // '/> (secondary pixel) <use ...
                    _coordinateLookup[uint8(int8(pos.x) + xOffset + pos.dx)],
                    _coordinateLookup[uint8(int8(pos.y) + pos.dy)],
                    "JyAgeD0n",
                    _coordinateLookup[uint8(2 - pos.dx)], // svg <use> blocks have relative x and y coords to the element they copy...
                    "JyAgeT0n",
                    _coordinateLookup[uint8(2 - pos.dy)],
                    "Jy8+" // '/>
                ));
    }

    // Big props to the community for the functions below!
    function uintToHexBytes6(uint256 a) internal pure returns (bytes memory) {
        string memory str = uintToHexString2(a);
        if (bytes(str).length == 2) {
            return abi.encodePacked("0000", str);
        } else if (bytes(str).length == 3) {
            return abi.encodePacked("000", str);
        } else if (bytes(str).length == 4) {
            return abi.encodePacked("00", str);
        } else if (bytes(str).length == 5) {
            return abi.encodePacked("0", str);
        }

        return bytes(str);
    }

    function uintToHexString2(uint256 a) internal pure returns (string memory) {
        uint256 count = 0;
        uint256 b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint256 i = 0; i < count; ++i) {
            b = a % 16;
            res[count - i - 1] = uintToHexDigit(uint8(b));
            a /= 16;
        }

        string memory str = string(res);
        if (bytes(str).length == 0) {
            return "00";
        } else if (bytes(str).length == 1) {
            return string(abi.encodePacked("0", str));
        }
        return str;
    }

    function uintToHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1("0")) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1("a")) + d - 10);
        }
        revert();
    }

    function uintToByteString(uint256 a, uint256 fixedLen) internal pure returns (bytes memory _uintAsString) {
        uint256 j = a;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(fixedLen);
        for(j = 0; j < fixedLen; j++) {
            bstr[j] = bytes1(" ");
        }
        bstr[0] = bytes1("0");
        uint256 k = len;
        while (a != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(a - (a / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            a /= 10;
        }
        return bstr;
    }

    // standard stuff
    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    receive() external payable {}

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    // opensea integreation
    function contractURI() public pure returns (string memory) {
        return "https://bonsaidreaming.art/storefront.json";
    }

    function updInternVal(uint256 value) external onlyOwner nonReentrant {
        PUBLIC_SALE_MINT_PRICE = value;
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