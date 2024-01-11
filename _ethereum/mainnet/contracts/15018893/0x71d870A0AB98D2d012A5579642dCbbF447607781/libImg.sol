// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

library libImg {

    struct IMAGE{
        uint256 width;
        uint256 height;
        bytes pixels;
    }

    function toIndex(int256 _x, int256 _y, uint256 _width) internal pure returns (uint256 index){
        unchecked{
            index = uint256(_y) * (_width +1) + uint256(_x) + 1;
        }
        
    }

    function assignMidPoint(uint256 seed, uint256 width, uint256 height) internal pure returns (int256 x, int256 y) {

        x = int256(
                (
                    ((seed >> 2*8) % width) +
                    (width / 2)
                ) /2
            );

        y = int256(
                (
                    ((seed) % height) +
                    (height / 2)

                ) /2
            );


    }

    function rasterFilledCircle(IMAGE memory img, int256 xMid, int256 yMid, int256 r, bytes1 idxColour) internal pure returns (IMAGE memory) {

        int256 xSym;
        int256 ySym;
        int256 x = 0;
        int256 y = int(r);

        unchecked {
            for (x = xMid - r ; x <= xMid; x++) {
                for (y = yMid - r ; y <= yMid; y++) {
                    if ((x - xMid)*(x - xMid) + (y - yMid)*(y - yMid) <= r*r) 
                    {
                        xSym = xMid - (x - xMid);
                        ySym = yMid - (y - yMid);
                        // (x, y), (x, ySym), (xSym , y), (xSym, ySym) are in the circle
                        if (x >= 0 && y >= 0) {
                            img.pixels[toIndex(x, y,img.width)] = idxColour;
                        }
                        if (x >= 0 && ySym >= 0) {
                            img.pixels[toIndex(x, ySym,img.width)] = idxColour;
                        }
                        if (xSym >= 0 && y >= 0) {
                            img.pixels[toIndex(xSym, y,img.width)] = idxColour;
                        }
                        if (xSym >= 0 && ySym >= 0) {
                            img.pixels[toIndex(xSym, ySym,img.width)] = idxColour;
                        }
                    }
                }
            }
        }
        return img;
    }

    function drawImage(IMAGE memory img, uint256 circleCount) internal view returns (bytes memory){

        IMAGE memory tempImg;
        int256 xMid;
        int256 yMid;
        uint256 randoSeed;

        for (uint8 i = 0; i<circleCount; i++) {
            randoSeed = uint256(keccak256(abi.encodePacked(block.timestamp, i)));
            (xMid, yMid) = assignMidPoint(randoSeed, img.width, img.height);

            tempImg = rasterFilledCircle(img, xMid, yMid, int256(18), bytes1(i+1));
        }
        
        return tempImg.pixels;

    }

}