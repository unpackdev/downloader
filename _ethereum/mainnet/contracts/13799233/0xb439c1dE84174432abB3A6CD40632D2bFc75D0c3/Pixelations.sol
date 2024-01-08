// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";

/*

    ██████╗░██╗██╗░░██╗███████╗██╗░░░░░░█████╗░████████╗██╗░█████╗░███╗░░██╗░██████╗
    ██╔══██╗██║╚██╗██╔╝██╔════╝██║░░░░░██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║██╔════╝
    ██████╔╝██║░╚███╔╝░█████╗░░██║░░░░░███████║░░░██║░░░██║██║░░██║██╔██╗██║╚█████╗░
    ██╔═══╝░██║░██╔██╗░██╔══╝░░██║░░░░░██╔══██║░░░██║░░░██║██║░░██║██║╚████║░╚═══██╗
    ██║░░░░░██║██╔╝╚██╗███████╗███████╗██║░░██║░░░██║░░░██║╚█████╔╝██║░╚███║██████╔╝
    ╚═╝░░░░░╚═╝╚═╝░░╚═╝╚══════╝╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝╚═════╝░


    What are Pixelations?

    Pixelations are an NFT collection of 32x32 pixelated images. There are 3,232 Pixelations,
    each 100% stored and rendered on chain.

    For this collection, we took a unique approach. Rather than designing the art ourselves,
    we are giving the minter the ability to provide the art. This image could be anything:
    an IRL photo, a painting, or a JPEG pulled off the internet.

    How does it work?

    Upon minting, we perform a number of image processing steps in order to viably store your
    image on chain, and also reduce minting gas fees as much as possible. At a high level we
    do the following off chain:

    1. Convert the image into 32x32 pixels.

    2. Extract the 32 colors that best represent the image via k-means clustering.

    3. Compress the image via bit-packing since we now only need 5-bits to represent it's 32 colors.

    After these off chain steps, your image is roughly 700 bytes of data that we store in
    our custom ERC-721 smart contract. When sites like OpenSea attempt to fetch your
    Pixelation's metadata and image, our contract renders an SVG at run-time.

    ----------------------------------------------------------------------------

    Special shoutout to Chainrunners and Blitmap for the inspiration and help.
    We used a lot of the same techniques in order to perform efficient rendering.
*/

contract Pixelations is ERC721Enumerable, Ownable, ReentrancyGuard {
    uint256 public MAX_TOKENS = 3232;

    mapping(address => uint256) public earlyAccessMintsAllowed;
    uint256 private constant MAX_PER_EARLY_ACCESS_ADDRESS = 3;

    mapping(address => uint256) public privateSaleMintsAllowed;
    uint256 private constant PRIVATE_SALE_MINT_PRICE = 0.025 ether;
    uint256 private constant MAX_PER_PRIVATE_SALE_ADDRESS = 5;

    uint256 public publicSaleStartTimestamp;
    uint256 private constant PUBLIC_SALE_MINT_PRICE = 0.05 ether;

    uint256 public numberOfMints;
    bytes[] private _tokenDatas;
    bytes[] private _colorsByToken;
    string[32] private _coordinateLookup;

    bool public mintingCompleteAndValid;

    struct SVGRowBuffer {
        string one;
        string two;
        string three;
        string four;
        string five;
        string six;
        string seven;
        string eight;
    }

    struct SVGCursor {
        uint8 x;
        uint8 y;
        string color1;
        string color2;
        string color3;
        string color4;
    }

    constructor() ERC721("Pixelations", "PIXELATIONS") {
        // base64-encoded svg coordinates from 010 to 310
        _coordinateLookup = [
            "MDAw",
            "MDEw",
            "MDIw",
            "MDMw",
            "MDQw",
            "MDUw",
            "MDYw",
            "MDcw",
            "MDgw",
            "MDkw",
            "MTAw",
            "MTEw",
            "MTIw",
            "MTMw",
            "MTQw",
            "MTUw",
            "MTYw",
            "MTcw",
            "MTgw",
            "MTkw",
            "MjAw",
            "MjEw",
            "MjIw",
            "MjMw",
            "MjQw",
            "MjUw",
            "MjYw",
            "Mjcw",
            "Mjgw",
            "Mjkw",
            "MzAw",
            "MzEw"
        ];
    }

    modifier whenPublicSaleActive() {
        require(isPublicSaleOpen(), "Public sale not open");
        _;
    }

    function isPublicSaleOpen() public view returns (bool) {
        return publicSaleStartTimestamp != 0 && block.timestamp >= publicSaleStartTimestamp;
    }

    function setPublicSaleStartTimestamp(uint256 timestamp) external onlyOwner {
        publicSaleStartTimestamp = timestamp;
    }

    function mintEarlyAccess(bytes memory tokenData, bytes memory colors)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        require(getRemainingEarlyAccessMints(msg.sender) > 0, "Address has no more early access mints remaining.");
        earlyAccessMintsAllowed[msg.sender]--;
        return _mintNewToken(tokenData, colors);
    }

    function mintPrivateSale(bytes memory tokenData, bytes memory colors)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        require(getRemainingPrivateSaleMints(msg.sender) > 0, "Address has no more private sale mints remaining.");
        require(PRIVATE_SALE_MINT_PRICE == msg.value, "Incorrect amount of ether sent.");
        privateSaleMintsAllowed[msg.sender]--;
        return _mintNewToken(tokenData, colors);
    }

    function mintPublicSale(bytes memory tokenData, bytes memory colors)
        external
        payable
        nonReentrant
        whenPublicSaleActive
        returns (uint256)
    {
        require(PUBLIC_SALE_MINT_PRICE == msg.value, "Incorrect amount of ether sent.");
        return _mintNewToken(tokenData, colors);
    }

    // tokenData needs to be 640 bytes where every 5 bits represents the color index of a pixel.
    // colors needs to be 32 hex colors concatenated together.
    function _mintNewToken(bytes memory tokenData, bytes memory colors) internal returns (uint256) {
        require(tokenData.length == 640, "tokenData must be 640 bytes.");
        require(colors.length == 96, "colors must be 96 bytes.");
        require(numberOfMints < MAX_TOKENS, "All Pixelations have been minted.");

        _tokenDatas.push(tokenData);
        _colorsByToken.push(colors);

        uint256 newItemId = numberOfMints + 1;

        _safeMint(msg.sender, newItemId);
        numberOfMints++;

        return newItemId;
    }

    function getRemainingEarlyAccessMints(address addr) public view returns (uint256) {
        return earlyAccessMintsAllowed[addr];
    }

    function addToEarlyAccessList(address[] memory toEarlyAccessList) external onlyOwner {
        for (uint256 i = 0; i < toEarlyAccessList.length; i++) {
            earlyAccessMintsAllowed[toEarlyAccessList[i]] = MAX_PER_EARLY_ACCESS_ADDRESS;
        }
    }

    function getRemainingPrivateSaleMints(address addr) public view returns (uint256) {
        return privateSaleMintsAllowed[addr];
    }

    function addToPrivateSaleList(address[] memory toPrivateSaleList) external onlyOwner {
        for (uint256 i = 0; i < toPrivateSaleList.length; i++) {
            privateSaleMintsAllowed[toPrivateSaleList[i]] = MAX_PER_PRIVATE_SALE_ADDRESS;
        }
    }

    // Hopefully we don't have to use this. But as a safeguard for if somebody needs to change their photo
    // we have the ability to override the token data. Once all tokens are minted and verified to be valid, we can close
    // off this functionality with: setMintingCompleteAndValid()
    function overwriteExistingTokenData(
        uint256 tokenId,
        bytes memory tokenData,
        bytes memory colors
    ) external onlyOwner {
        require(tokenId >= 1, "Invalid tokenId.");
        require(tokenId <= numberOfMints, "Token hasn't been minted yet.");
        require(tokenData.length == 640, "tokenData must be 640 bytes.");
        require(colors.length == 96, "tokenData must be 96 bytes.");
        require(!mintingCompleteAndValid, "You are not allowed to overwrite existing token data anymore.");

        uint256 tokenIndex = tokenId - 1;
        _tokenDatas[tokenIndex] = tokenData;
        _colorsByToken[tokenIndex] = colors;
    }

    function setMintingCompleteAndValid() external onlyOwner {
        mintingCompleteAndValid = true;
    }

    // This returns the base64-encoded JSON metadata for the given token.  Metadata looks like this:
    //
    //  {
    //      "image_data": "<svg>...</svg>",
    //      "name": "Pixelation #31",
    //      "description": "A 32x32 pixelated image, stored and rendered completely on chain."
    //  }
    //
    // As you'll see in the rest of this contract, we try to keep everything pre base64-encoded.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string[4] memory buffer = tokenSvgDataOf(tokenId);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,eyAgImltYWdlX2RhdGEiOiAiPHN2ZyB2ZXJzaW9uPScxLjEnIHZpZXdCb3g9JzAgMCAzMjAgMzIwJyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHNoYXBlLXJlbmRlcmluZz0nY3Jpc3BFZGdlcyc+",
                    buffer[0],
                    buffer[1],
                    buffer[2],
                    buffer[3],
                    "PHN0eWxlPnJlY3R7d2lkdGg6MTBweDtoZWlnaHQ6MTBweDt9PC9zdHlsZT48L3N2Zz4iLCAgIm5hbWUiOiAiUGl4ZWxhdGlvbiAj",
                    Base64.encode(uintToByteString(tokenId, 6)),
                    "IiwgImRlc2NyaXB0aW9uIjogIkEgMzJ4MzIgcGl4ZWxhdGVkIGltYWdlLCBzdG9yZWQgYW5kIHJlbmRlcmVkIGNvbXBsZXRlbHkgb24gY2hhaW4uIn0g"
                )
            );
    }

    // Handy function for only rendering the svg.
    function tokenSVG(uint256 tokenId) public view returns (string memory) {
        string[4] memory buffer = tokenSvgDataOf(tokenId);

        return
            string(
                abi.encodePacked(
                    "PHN2ZyB2ZXJzaW9uPScxLjEnIHZpZXdCb3g9JzAgMCAzMjAgMzIwJyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHNoYXBlLXJlbmRlcmluZz0nY3Jpc3BFZGdlcyc+",
                    buffer[0],
                    buffer[1],
                    buffer[2],
                    buffer[3],
                    "PHN0eWxlPnJlY3R7d2lkdGg6MTBweDtoZWlnaHQ6MTBweDt9PC9zdHlsZT48L3N2Zz4"
                )
            );
    }

    function tokenDataOf(uint256 tokenId) public view returns (bytes memory) {
        return _tokenDatas[tokenId - 1];
    }

    function tokenColors(uint256 tokenId) public view returns (bytes memory) {
        return _colorsByToken[tokenId - 1];
    }

    // In order to convert the _tokenData and _colorsByToken for a given tokenId, we need
    // to loop over every pixel, grab the color for that pixel, and generate an svg rect for
    // that pixel.  The difficulty is doing this in a gas efficient manner.
    //
    // The naive approach would be to store the output in a string, and continually append
    // svg rects to that string via abi.encodePacked.  However calling abi.encodePacked on
    // a successively larger output string is expensive.  And so the solution here is to
    // build up a series of buffers of strings.  The first buffer contains 8 strings where
    // each string is a single row of svg rects.  The second buffer contains 4 strings
    // where each string is 8 rows of svg rects (really its just the concatenation of the
    // previous buffer).
    //
    // At the end we return this buffer of 4 strings, and it is up to the caller to concatenate
    // those strings together in order to form the resulting svg.
    //
    // Shoutout to Chainrunners for the help here.
    function tokenSvgDataOf(uint256 tokenId) private view returns (string[4] memory) {
        SVGCursor memory cursor;

        SVGRowBuffer memory cursorRow;

        string[8] memory bufferOfRows;
        uint8 indexIntoBufferOfRows;

        string[4] memory bufferOfEightRows;
        uint8 indexIntoBufferOfEightRows;

        for (uint256 dataIndex = 0; dataIndex < 1024; ) {
            cursor.color1 = getColor(tokenId, dataIndex, 0);
            cursor.color2 = getColor(tokenId, dataIndex, 1);
            cursor.color3 = getColor(tokenId, dataIndex, 2);
            cursor.color4 = getColor(tokenId, dataIndex, 3);
            cursorRow.one = fourPixels(cursor);

            cursor.x += 4;
            cursor.color1 = getColor(tokenId, dataIndex, 4);
            cursor.color2 = getColor(tokenId, dataIndex, 5);
            cursor.color3 = getColor(tokenId, dataIndex, 6);
            cursor.color4 = getColor(tokenId, dataIndex, 7);
            cursorRow.two = fourPixels(cursor);

            dataIndex += 8;

            cursor.x += 4;
            cursor.color1 = getColor(tokenId, dataIndex, 0);
            cursor.color2 = getColor(tokenId, dataIndex, 1);
            cursor.color3 = getColor(tokenId, dataIndex, 2);
            cursor.color4 = getColor(tokenId, dataIndex, 3);
            cursorRow.three = fourPixels(cursor);

            cursor.x += 4;
            cursor.color1 = getColor(tokenId, dataIndex, 4);
            cursor.color2 = getColor(tokenId, dataIndex, 5);
            cursor.color3 = getColor(tokenId, dataIndex, 6);
            cursor.color4 = getColor(tokenId, dataIndex, 7);
            cursorRow.four = fourPixels(cursor);

            dataIndex += 8;

            cursor.x += 4;
            cursor.color1 = getColor(tokenId, dataIndex, 0);
            cursor.color2 = getColor(tokenId, dataIndex, 1);
            cursor.color3 = getColor(tokenId, dataIndex, 2);
            cursor.color4 = getColor(tokenId, dataIndex, 3);
            cursorRow.five = fourPixels(cursor);

            cursor.x += 4;
            cursor.color1 = getColor(tokenId, dataIndex, 4);
            cursor.color2 = getColor(tokenId, dataIndex, 5);
            cursor.color3 = getColor(tokenId, dataIndex, 6);
            cursor.color4 = getColor(tokenId, dataIndex, 7);
            cursorRow.six = fourPixels(cursor);

            dataIndex += 8;

            cursor.x += 4;
            cursor.color1 = getColor(tokenId, dataIndex, 0);
            cursor.color2 = getColor(tokenId, dataIndex, 1);
            cursor.color3 = getColor(tokenId, dataIndex, 2);
            cursor.color4 = getColor(tokenId, dataIndex, 3);
            cursorRow.seven = fourPixels(cursor);

            cursor.x += 4;
            cursor.color1 = getColor(tokenId, dataIndex, 4);
            cursor.color2 = getColor(tokenId, dataIndex, 5);
            cursor.color3 = getColor(tokenId, dataIndex, 6);
            cursor.color4 = getColor(tokenId, dataIndex, 7);
            cursorRow.eight = fourPixels(cursor);

            dataIndex += 8;

            bufferOfRows[indexIntoBufferOfRows++] = string(
                abi.encodePacked(
                    cursorRow.one,
                    cursorRow.two,
                    cursorRow.three,
                    cursorRow.four,
                    cursorRow.five,
                    cursorRow.six,
                    cursorRow.seven,
                    cursorRow.eight
                )
            );
            cursor.x = 0;
            cursor.y += 1;

            if (indexIntoBufferOfRows >= 8) {
                bufferOfEightRows[indexIntoBufferOfEightRows++] = string(
                    abi.encodePacked(
                        bufferOfRows[0],
                        bufferOfRows[1],
                        bufferOfRows[2],
                        bufferOfRows[3],
                        bufferOfRows[4],
                        bufferOfRows[5],
                        bufferOfRows[6],
                        bufferOfRows[7]
                    )
                );
                indexIntoBufferOfRows = 0;
            }
        }

        return bufferOfEightRows;
    }

    // Extracts the base64-encoded hex color for a single pixel.
    function getColor(
        uint256 tokenId,
        uint256 dataIndex,
        uint256 offset
    ) internal view returns (string memory) {
        uint256 pixelIndex = dataIndex + offset;
        uint256 indexIntoColors = getColorIndexFromPixelIndex(tokenId, pixelIndex);
        bytes memory rgbBytes = subBytesOfLength3(_colorsByToken[tokenId - 1], indexIntoColors * 3);

        uint256 n = uint256(uint8(rgbBytes[0]));
        n = (n << 8) + uint256(uint8(rgbBytes[1]));
        n = (n << 8) + uint256(uint8(rgbBytes[2]));

        return Base64.encode(uintToHexBytes6(n));
    }

    // Unpack the 5-bit value representing the color index for a given pixel. A bunch of bitwise operations
    // needed to pull this off. Code is confusing af, just trust me that the math works out here.
    function getColorIndexFromPixelIndex(uint256 tokenId, uint256 pixelIndex) internal view returns (uint8) {
        uint256 indexIntoBytes = (5 * pixelIndex) / 8;
        uint8 indexIntoByte = uint8((5 * pixelIndex) % 8);

        bytes memory tokenData = _tokenDatas[tokenId - 1];

        uint8 value = 0;
        uint8 indexedByte = uint8(tokenData[indexIntoBytes]);

        if (indexIntoByte >= 3) {
            uint8 mod = uint8(2**(8 - indexIntoByte));
            uint8 shift = (indexIntoByte - 3);
            value = (indexedByte % mod) << shift;
        } else {
            uint8 mod = (3 - indexIntoByte);
            value = (indexedByte >> mod) % 32;
        }

        if (indexIntoByte > 3) {
            uint8 leftoverBits = indexIntoByte - 3;
            uint8 nextByte = uint8(tokenData[indexIntoBytes + 1]);

            value += nextByte >> (8 - leftoverBits);
        }

        return value;
    }

    function subBytesOfLength3(bytes memory bb, uint256 startIndex) internal pure returns (bytes memory) {
        bytes memory result = new bytes(3);
        for (uint256 i = startIndex; i < startIndex + 3; i++) {
            result[i - startIndex] = bb[i];
        }

        return result;
    }

    // Rather than constructing each svg rect one at a time, let's save on gas and construct four at a time.
    // Unfortunately we can't construct more than four pixels at a time, otherwise we would
    // run into "stack too deep" errors at compile time.
    //
    // In order to get this to compile correctly, make sure to have the following compiler settings:
    //
    //      optimizer: {
    //          enabled: true,
    //          runs: 2000,
    //          details: {
    //              yul: true,
    //              yulDetails: {
    //                  stackAllocation: true,
    //                  optimizerSteps: "dhfoDgvulfnTUtnIf"
    //              }
    //          }
    //      }
    function fourPixels(SVGCursor memory pos) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "PHJlY3QgICBmaWxsPScj",
                    pos.color1,
                    "JyAgeD0n",
                    _coordinateLookup[pos.x],
                    "JyAgeT0n",
                    _coordinateLookup[pos.y],
                    "JyAvPjxyZWN0ICBmaWxsPScj",
                    pos.color2,
                    "JyAgeD0n",
                    _coordinateLookup[pos.x + 1],
                    "JyAgeT0n",
                    _coordinateLookup[pos.y],
                    "JyAvPjxyZWN0ICBmaWxsPScj",
                    pos.color3,
                    "JyAgeD0n",
                    _coordinateLookup[pos.x + 2],
                    "JyAgeT0n",
                    _coordinateLookup[pos.y],
                    "JyAvPjxyZWN0ICBmaWxsPScj",
                    pos.color4,
                    "JyAgeD0n",
                    _coordinateLookup[pos.x + 3],
                    "JyAgeT0n",
                    _coordinateLookup[pos.y],
                    "JyAgIC8+"
                )
            );
    }

    function uintToHexBytes6(uint256 a) public pure returns (bytes memory) {
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

    /*
    Convert uint to hex string, padding to 2 hex nibbles
    */
    function uintToHexString2(uint256 a) public pure returns (string memory) {
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

    function uintToHexDigit(uint8 d) public pure returns (bytes1) {
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
        j = fixedLen;
        if (a == 0) {
            bstr[0] = "0";
            len = 1;
        }
        while (j > len) {
            j = j - 1;
            bstr[j] = bytes1(" ");
        }
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

    receive() external payable {}

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
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
