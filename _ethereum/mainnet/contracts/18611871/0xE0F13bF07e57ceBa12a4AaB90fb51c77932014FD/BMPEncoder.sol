// SPDX-License-Identifier: MIT
// Author: Sylvain Magicking Laurent
pragma solidity ^0.8.4;
import "./ERC721.sol";
import "./Base64.sol";
import "./Strings.sol";
import "./BytesLib.sol";

import "./Script.sol";
contract BMPImage {
    struct InfoHeader {
        uint32 width; // width in pixels
        uint32 height; // height in pixels
        uint16 colorPlanes; // number of color planes (must be 1)
        uint16 bitsPerPixel; // bits per pixel
        uint32 compression; // compression method
        uint32 imageSize; // image size in bytes
        uint32 horizontalResolution; // horizontal resolution in pixels per meter
        uint32 verticalResolution; // vertical resolution in pixels per meter
        uint32 colorsInPalette; // number of colors in the color palette
        uint32 importantColors; // number of important colors used
    }

    struct Image {
        Header header;
        InfoHeader infoHeader;
        bytes data;
    }
    function writeInfoHeader(InfoHeader memory h) pure public  returns (bytes memory) {
        bytes memory header = new bytes(40);
        // write header size
        header[0] = 0x28;
        header[1] = 0;
        header[2] = 0;
        header[3] = 0;
        // write image width
        header[4] = bytes1(uint8(h.width));
        header[5] = bytes1(uint8(h.width >> 8));
        header[6] = bytes1(uint8(h.width >> 16));
        header[7] = bytes1(uint8(h.width >> 24));
        // write image height
        header[8] = bytes1(uint8(h.height));
        header[9] = bytes1(uint8(h.height >> 8));
        header[10] = bytes1(uint8(h.height >> 16));
        header[11] = bytes1(uint8(h.height >> 24));
        // write color planes
        header[12] = bytes1(uint8(h.colorPlanes));
        header[13] = bytes1(uint8(h.colorPlanes >> 8));
        // write bits per pixel
        header[14] = bytes1(uint8(h.bitsPerPixel));
        header[15] = bytes1(uint8(h.bitsPerPixel >> 8));
        // write compression method
        header[16] = bytes1(uint8(h.compression));
        header[17] = bytes1(uint8(h.compression >> 8));
        header[18] = bytes1(uint8(h.compression >> 16));
        header[19] = bytes1(uint8(h.compression >> 24));
        // write image size
        uint32 imageSize = h.imageSize;
        header[20] = bytes1(uint8(imageSize));
        header[21] = bytes1(uint8(imageSize >> 8));
        header[22] = bytes1(uint8(imageSize >> 16));
        header[23] = bytes1(uint8(imageSize >> 24));
        // write horizontal resolution
        header[24] = bytes1(uint8(h.horizontalResolution));
        header[25] = bytes1(uint8(h.horizontalResolution >> 8));
        header[26] = bytes1(uint8(h.horizontalResolution >> 16));
        header[27] = bytes1(uint8(h.horizontalResolution >> 24));
        // write vertical resolution
        header[28] = bytes1(uint8(h.verticalResolution));
        header[29] = bytes1(uint8(h.verticalResolution >> 8));
        header[30] = bytes1(uint8(h.verticalResolution >> 16));
        header[31] = bytes1(uint8(h.verticalResolution >> 24));
        // write colors in palette
        header[32] = bytes1(uint8(h.colorsInPalette));
        header[33] = bytes1(uint8(h.colorsInPalette >> 8));
        header[34] = bytes1(uint8(h.colorsInPalette >> 16));
        header[35] = bytes1(uint8(h.colorsInPalette >> 24));
        // write important colors
        header[36] = bytes1(uint8(h.importantColors));
        header[37] = bytes1(uint8(h.importantColors >> 8));
        header[38] = bytes1(uint8(h.importantColors >> 16));
        header[39] = bytes1(uint8(h.importantColors >> 24));

        return header;
    }
    struct Header {
        uint16 signature; // signature (must be 0x4d42)
        uint32 fileSize; // file size in bytes
        uint32 reserved; // reserved (must be 0)
        uint32 dataOffset; // offset to image data in bytes from beginning of file (54 bytes)
    }
    function writeHeader(Header memory h) pure public  returns (bytes memory) {
        bytes memory header = new bytes(14);
        // write signature
        header[0] = bytes1(uint8(h.signature));
        header[1] = bytes1(uint8(h.signature >> 8));
        // write file size
        uint32 fileSize = h.fileSize;
        header[2] = bytes1(uint8(fileSize));
        header[3] = bytes1(uint8(fileSize >> 8));
        header[4] = bytes1(uint8(fileSize >> 16));
        header[5] = bytes1(uint8(fileSize >> 24));
        // write reserved
        header[6] = bytes1(uint8(h.reserved));
        header[7] = bytes1(uint8(h.reserved >> 8));
        header[8] = bytes1(uint8(h.reserved >> 16));
        header[9] = bytes1(uint8(h.reserved >> 24));
        // write data offset
        header[10] = bytes1(uint8(h.dataOffset));
        header[11] = bytes1(uint8(h.dataOffset >> 8));
        header[12] = bytes1(uint8(h.dataOffset >> 16));
        header[13] = bytes1(uint8(h.dataOffset >> 24));

        return header;
    }
    function switchEndianness32(uint32 i) pure internal returns (uint32 out) {
        return ((i >> 24)&0x000000ff) | ((i >> 8)&0x0000ff00) | ((i << 8)&0x00ff0000) | ((i<<24)&0xff000000);
    }
    function newImage(uint32 width, uint32 height) pure public returns (Image memory) {
        Image memory image;
        image.header.signature = 0x4d42;
        image.header.fileSize = 54 + width * height * 4;
        image.header.reserved = 0;
        image.header.dataOffset = 0x28 + 14;
        image.infoHeader.width = width;
        image.infoHeader.height = height;
        image.infoHeader.colorPlanes = 1;
        image.infoHeader.bitsPerPixel = 32;
        image.infoHeader.compression = 0;
        image.infoHeader.imageSize = width * height * 4;
        image.infoHeader.horizontalResolution = 0x00000b13;
        image.infoHeader.verticalResolution = 0x00000b13;
        /* Specifies the number of color indexes in the color table
        actually used by the bitmap. If this value is zero, the bitmap uses the
        maximum number of colors corresponding to the value of the biBitCount member.
        For more information on the maximum sizes of the color table, see the
        description of the BITMAPINFO structure earlier in this topic.
        */
        image.infoHeader.colorsInPalette = 0;
        /*
        Specifies the number of color indexes that are considered
        important for displaying the bitmap. If this value is zero, all colors are
        important.
         */
        image.infoHeader.importantColors = 0;

        image.data = new bytes(width * height * 4);
        return image;
    }

    // Human pixel layout
    /****************
    * 0,0           *
    *               *
    *               *
    *       w-1;h-1 *
    ****************/

    // Canvas pixel layout
    /****************
    *       w-1;h-1 *
    *               *
    *               *
    * 0,0           *
    ****************/

    // setPixelAt convert (x,y) from human to canvas layout
    // 32 bits per pixel
    function setPixelAt(Image memory image, uint32 x, uint32 y, uint8 r, uint8 g, uint8 b, uint8 a) public pure returns (Image memory)  {
        uint32 width = image.infoHeader.width;
        uint32 height = image.infoHeader.height;
        require(x < width, "x out of bounds");
        require(y < height, "y out of bounds");
        uint32 index = x * 4 + ((height - y - 1) * width * 4);
        bytes memory mem = image.data;
        assembly {
            // Pascal type array with length at the beginning
            index := add(add(mem, 0x20), index)
            mstore8(index, b)
            index := add(index, 1)
            mstore8(index, g)
            index := add(index, 1)
            mstore8(index, r)
            index := add(index, 1)
            mstore8(index, a)
        }
        return image;
    }
    // Draw bitfield
    /*

    Canvas content:
    0b00000000000000000000000000000000000000000000000000000000000000000000011111111110000000000000000011110000000000000000000100000000
    0b00000111111111000000000000000000000000111111111000000000000000000001110000000000000000000000011110000000000000000000101000000000
    0b00111100000001111000000000000000011111100000001110000000000000000001111111111111100000000001110000000000000000000011100000000000
    0b00100000000000001111111111111111110000000000000011100000110000000000000000000011100000000011000000000000001111000000000000000000
    0b00000000000000000000000000000000000000000000000000111111100000000111111111111110001110000111111111111111111000000000000000000000
    0b00000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000001000000000000

    in hex 256 * 3:

    0x000000000000000007fe0000f000010007fc000003fe00001c00000780000a00
    0x3c0780007e0380001fff801c000038002000ffffc000e0c000038030003c0000
    0x0000000000003f807ffe387fffe0000000000000000000000000400000001000
     */
    function draw128pxLinesBitfield(Image memory image, uint32 x, uint32 y, uint256 colors, uint256[] memory parts) pure public returns (Image memory) {
        uint8 r = uint8((colors >> 16) & 0xFF);
        uint8 g = uint8((colors >> 8)  & 0xFF);
        uint8 b = uint8(colors       & 0xFF);
        uint8 a/* = r = g = b */= 255;
        uint32 width = image.infoHeader.width;
        uint32 height = image.infoHeader.height;
        uint8 line = uint8(parts.length*2);
        require(x+128 < width, "x out of bounds");
        require(y+uint32(line) < height, "y out of bounds");
        for (uint8 i = 0; i < line; i++) {
            for (uint8 j = 0; j < 128; j++) {
                uint256 bitField = parts[uint256(i)/2];
                uint256 bit = (bitField >> (255 - ((uint256(j)+uint256(i)*128) % 256))) & 0x1;
                if (bit == 1) {
                    image = setPixelAt(image, x + j, y + i, r, g, b, a);
                }/*
                 // Uncomment to have a black background
                 else {
                    image = setPixelAt(image, x + j, y + i, 0, 0, 0, 255);
                }*/
            }
        }
        return image;
    }
    // Draw dotted line
    function drawSkipLine(Image memory image, uint32 x1, uint32 y1, uint32 x2, uint32 y2, uint8 r, uint8 g, uint8 b, uint8 a, uint32 skip) public pure returns (Image memory) {
        uint32 width = image.infoHeader.width;
        uint32 height = image.infoHeader.height;
        require(x1 < width, "x1 out of bounds");
        require(y1 < height, "y1 out of bounds");
        require(x2 < width, "x2 out of bounds");
        require(y2 < height, "y2 out of bounds");
        uint32 dx = x2 - x1;
        uint32 dy = y2 - y1;
        uint32 steps = 0;
        if (dx > dy) {
            steps = dx;
        } else {
            steps = dy;
        }
        uint32 xInc = dx / steps;
        uint32 yInc = dy / steps;
        uint32 x = x1;
        uint32 y = y1;
        for (uint32 i = 0; i < steps; i++) {
            if (skip > 0) {
                if (i % skip == 0) {
                    image = setPixelAt(image, x, y, r, g, b, a);
                }
            }else {
                image = setPixelAt(image, x, y, r, g, b, a);
            }
            x += xInc;
            y += yInc;
        }
        return image;
    }
    function drawLine(Image memory image, uint32 x1, uint32 y1, uint32 x2, uint32 y2, uint8 r, uint8 g, uint8 b, uint8 a) public pure returns (Image memory) {
        return drawSkipLine(image, x1, y1, x2, y2, r, g, b, a, 0);
    }

    function palette256() pure public returns (bytes memory) {
        bytes memory palette = new bytes(3*256);
        uint256 index = 0;
        for (uint8 r = 0; r < 8; r++) {
            for (uint8 g = 0; g < 8; g++) {
                for (uint8 b = 0; b < 4; b++) {
                    palette[index] = bytes1(uint8((uint256(r)*255)/7));
                    palette[index + 1] = bytes1(uint8((uint256(g)*255)/7));
                    palette[index + 2] = bytes1(uint8((uint256(b)*255)/7));
                    index += 3;
                }
            }
        }
        return palette;
    }

    function InPalette256(uint8 _r, uint8 _g, uint8 _b) pure public returns (bool) {
        for (uint8 r = 0; r < 8; r++) {
            for (uint8 g = 0; g < 8; g++) {
                for (uint8 b = 0; b < 4; b++) {
                    if ((_r == uint8((uint256(r)*255)/7)) && (_g == uint8((uint256(g)*255)/7)) && (_b == uint8((uint256(b)*255)/7)))
                        return true;
                }
            }
        }
        return false;
    }

    function getCharacter(uint8 index) public pure returns (uint8[15] memory) {
        require(index < 26, "a-z out of range");
        uint256 fontDataA2N = 0x2bedd75ce48f5b779a7f348e5aedf6f497e9356eb6493df6d; // Font data encoded in an uint256 A -> N
        uint256 fontDataM2Z = 0x5f6d76d7ef81db36badf11cba4b5d65b6fd6df6ab5eddf9cf; // Font data encoded in an uint256 M -> Z
        uint8[15] memory ret;
        // Use the second font data if the index is greater than 13
        if (index >= 13) {
            index -= 13;
            fontDataA2N = fontDataM2Z;
        }

        for (uint8 i = 0; i < 15; i++) {
            uint shift = (195 - index*15) - i - 1;
            if (shift == 0) {
                ret[i] = uint8(fontDataA2N & 0x1);
                continue;
            }
            ret[i] = uint8((fontDataA2N >> shift) & 0x1);
        }
        return ret;
    }

    function drawString(Image memory img, uint32 x, uint32 y, string memory s) public pure returns (BMPImage.Image memory ret) {
        uint8 r = 255;
        uint8 g = 255;
        uint8 b = 255;
        uint8 a = 255;
        ret = img;

        for (uint8 j = 0; j < bytes(s).length; j++) {
            // Convert from A-Z or a-z to 0-25
            uint8 c = uint8(bytes(s)[j]);
            // Skip non-alphabet characters
            if (!((c >= 0x41 && c <= 0x5a) || (c >= 0x61 && c <= 0x7a))) 
            {
                // if digit draw it
                if (c >= 0x30 && c <= 0x39) {
                    ret = writeN(ret, x + j*4, y, c - 0x30);
                }
                continue;
            }  
            c = (c | 0x60) - 0x61;
            uint8[15] memory fontChar = getCharacter(c);
            for (uint8 i = 0; i < 15; i++) {
                if (fontChar[i] == 1) {
                    ret = setPixelAt(ret, x + (i % 3) + j*4, y + (i / 3), r, g, b, a);
                } else {
                    ret = setPixelAt(ret, x + (i % 3) + j*4, y + (i / 3), 0, 0, 0, a);
                }
            }
        }
        return ret;
    }


    function writeN(Image memory img, uint32 x, uint32 y, uint8 n) public pure returns (BMPImage.Image memory ret) {
        require(n < 10, "N must be less than 10");
        uint8 r = 255;
        uint8 g = 255;
        uint8 b = 255;
        uint8 a = 255;
        ret = img;
/*
        uint8[10*15] memory fontData = [
        0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0,   // 0
        010
        101
        101    0
        101
        010

        010
        110
        010    1
        010
        111
...
        110001010100111 2
        110001010001110 3
        101101111001001 4
        111100110001110 5
        011100111101011 6
        ...
        111001010100100011101011101011011101111001011
        0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1,
        1, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 1, 1,
        1, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 1, 0,
        1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 1,
        1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 0,
        0, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1,
        1, 1, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0,
        0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1,
        0, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 1, 0, 1, 1];

101111101101101011101101101011111101111100000011101101100110111101111101101111000010100111111101001010111110101110101100111101101101101110101101101111 101101010101101 011110110111011111100111001111
101111101101101011101101101011111101111100000011101101100110 110101110101101 111000010100111111101001010111110101110101100111101101101101110101101101111101101010101101011110110111011111100111001111
101111101101101011101101101011111101111100000011101101100110110101110101101111000010100111111101001010111110101110101100111101101101101110101101101111101101010101101011110110111011111100111001111

 */
        // bitfield encoded in a uint256
        uint256 fontData = 0x15b52c97c54f8a3ade4f98e73d7ca91d75bbcb; // Font data encoded in an uint256 0 -> 9

        uint8 pix;
        for (uint8 i = 0; i < 15; i++) {
            uint shift = (150 - n*15) - i-1;
            if (shift == 0) {
                pix = uint8(fontData & 0x1);
                continue;
            }
            pix = uint8((fontData >> shift) & 0x1);

            if (pix > 0) {
                ret = setPixelAt(ret, x + (i % 3), y + (i / 3), r, g, b, a);
            } else {
                ret = setPixelAt(ret, x + (i % 3), y + (i / 3), 0, 0, 0, a);
            }
        }
    }

    function drawFrenchFlags(Image memory img, uint32 x, uint32 y) public pure returns (BMPImage.Image memory ret) {
 
        // Write a blue, white and red line pixel by pixel
        
        ret = img;
        for (uint32 i = 0; i < 3; i++) {
            ret = setPixelAt(ret, x + 2, y + i, 255, 0, 0, 255);
        }
        for (uint32 i = 0; i < 3; i++) {
            ret = setPixelAt(ret, x + 1, y + i, 255, 255, 255, 255);
        }
        for (uint32 i = 0; i < 3; i++) {
            ret = setPixelAt(ret, x + 0, y +  i, 0, 0, 255, 255);
        }
    }

    function drawNumber(Image memory img, uint32 x, uint32 y, uint256 bn, uint256 digit) public pure returns (BMPImage.Image memory ret) {
        ret = img;
        uint32 j = 0;
        for (uint8 i = 0; i < digit; i++) {
            uint256 n = uint256(bn / (10 ** uint256((digit-1) - i))) % 10;
            ret = writeN(ret, x + j*4, y, uint8(n));
            j++;
        }
    }

    function drawDuration(Image memory img, uint32 x, uint32 y, uint256 remainingSeconds) public pure returns (BMPImage.Image memory ret) {
        ret = img;
        uint256 day = remainingSeconds / 86400;
        remainingSeconds -= day * 86400;
        uint256 hour = remainingSeconds / 3600;
        remainingSeconds -= hour * 3600;
        uint256 minute = remainingSeconds / 60;
        remainingSeconds -= minute * 60;

       ret = drawNumber(img, x         , y, day, 1);
       ret = drawString(img, x + 1 * 4 , y, "d");
       ret = drawNumber(img, x + 3 * 4 , y, hour, 2);
       ret = drawString(img, x + 5 * 4 , y, "h");
       ret = drawNumber(img, x + 7 * 4 , y, minute, 2);
       ret = drawString(img, x + 9 * 4 , y, "m");
       ret = drawNumber(img, x + 11 * 4 , y, remainingSeconds, 2);
       ret = drawString(img, x + 13 * 4, y, "s");
    }
    function encode(Image memory img) pure public returns (bytes memory file) {
        bytes memory header = writeHeader(img.header);
        bytes memory infoHeader = writeInfoHeader(img.infoHeader);
        
        file = new bytes(header.length + infoHeader.length + img.data.length);
        for (uint256 i = 0; i < header.length; i++) {
            file[i] = header[i];
        }
        for (uint256 i = 0; i < infoHeader.length; i++) {
            file[header.length + i] = infoHeader[i];
        }
        for (uint256 i = 0; i < img.data.length; i++) {
            file[header.length + infoHeader.length + i] = img.data[i];
        }
        return file;
    }

    function encodeURI(Image memory img) pure public returns (string memory) {
        return string(abi.encodePacked("data:image/bmp;base64,", Base64.encode(encode(img))));
    }

}
