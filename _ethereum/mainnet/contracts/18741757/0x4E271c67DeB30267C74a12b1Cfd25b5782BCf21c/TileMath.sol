// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Math.sol";

library TileMath {
    struct XYCoordinate {
        int32 x;
        int32 y;
    }

    struct XYZCoordinate {
        uint32 x;
        uint32 y;
        uint32 z;
    }

    function check(uint32 tileCoordinate) public pure {
        require(
            tileCoordinate > 3000000 && tileCoordinate < 17000000,
            "coordinate x overflow"
        );
        tileCoordinate = tileCoordinate % 10000;
        require(
            tileCoordinate > 300 && tileCoordinate < 1700,
            "coordinate y overflow"
        );
    }

    function LandRingNum(uint32 LandId) public pure returns (uint32 n) {
        n = uint32((Math.sqrt(9 + 12 * uint256(LandId)) - 3) / 6);
        if ((3 * n * n + 3 * n) == LandId) {
            return n;
        } else {
            return n + 1;
        }
    }

    function LandRingPos(uint32 LandId) public pure returns (uint32) {
        uint32 ringNum = LandRingNum(LandId) - 1;
        return LandId - (3 * ringNum * ringNum + 3 * ringNum);
    }

    function LandRingStartCenterTile(
        uint32 LandIdRingNum_
    ) public pure returns (uint32) {
        return
            (1000 - LandIdRingNum_ * 5) * 10000 + (1000 + LandIdRingNum_ * 11);
    }

    function LandCenterTile(
        uint32 LandId
    ) public pure returns (uint32 tileCoordinate) {
        if (LandId == 0) {
            return 10001000;
        }

        uint32 LandIdRingNum_ = LandRingNum(LandId);

        uint32[3] memory startTile = coordinateIntToArr(
            LandRingStartCenterTile(LandIdRingNum_)
        );

        uint32 LandIdRingPos_ = LandRingPos(LandId);

        uint32 side = uint32(Math.ceilDiv(LandIdRingPos_, LandIdRingNum_));

        uint32 sidepos = 0;
        if (LandIdRingNum_ > 1) {
            sidepos = (LandIdRingPos_ - 1) % LandIdRingNum_;
        }
        if (side == 1) {
            tileCoordinate = (startTile[0] + sidepos * 11) * 10000;
            tileCoordinate += startTile[1] - sidepos * 6;
        } else if (side == 2) {
            tileCoordinate = (2000 - startTile[2] + sidepos * 5) * 10000;
            tileCoordinate += 2000 - startTile[0] - sidepos * 11;
        } else if (side == 3) {
            tileCoordinate = (startTile[1] - sidepos * 6) * 10000;
            tileCoordinate += startTile[2] - sidepos * 5;
        } else if (side == 4) {
            tileCoordinate = (2000 - startTile[0] - sidepos * 11) * 10000;
            tileCoordinate += 2000 - startTile[1] + sidepos * 6;
        } else if (side == 5) {
            tileCoordinate = (startTile[2] - sidepos * 5) * 10000;
            tileCoordinate += startTile[0] + sidepos * 11;
        } else if (side == 6) {
            tileCoordinate = (2000 - startTile[1] + sidepos * 6) * 10000;
            tileCoordinate += 2000 - startTile[2] + sidepos * 5;
        }
    }

    function LandTileRange(
        uint32 tileCoordinate
    ) public pure returns (uint32[] memory, uint32[] memory) {
        uint32[] memory xrange = new uint32[](11);
        uint32[] memory yrange = new uint32[](11);
        uint32[3] memory blockArr = coordinateIntToArr(tileCoordinate);
        for (uint256 i = 0; i < 11; i++) {
            xrange[i] = blockArr[0] + uint32(i) - 5;
            yrange[i] = blockArr[1] + uint32(i) - 5;
        }
        return (xrange, yrange);
    }

    function getLandTilesMOPNPoint(
        uint32 LandId
    ) public pure returns (uint256[] memory) {
        uint32 tileCoordinate = LandCenterTile(LandId);
        uint256[] memory TilesMOPNPoint = new uint256[](91);
        TilesMOPNPoint[0] = getTileMOPNPoint(tileCoordinate);
        for (uint256 i = 1; i <= 5; i++) {
            tileCoordinate++;
            uint256 preringblocks = 3 * (i - 1) * (i - 1) + 3 * (i - 1);
            for (uint256 j = 0; j < 6; j++) {
                for (uint256 k = 0; k < i; k++) {
                    TilesMOPNPoint[
                        preringblocks + j * i + k + 1
                    ] = getTileMOPNPoint(tileCoordinate);
                    tileCoordinate = neighbor(tileCoordinate, j);
                }
            }
        }
        return TilesMOPNPoint;
    }

    function getTileMOPNPoint(
        uint32 tileCoordinate
    ) public pure returns (uint256 tile) {
        unchecked {
            if ((tileCoordinate / 10000) % 10 == 0) {
                if (tileCoordinate % 10 == 0) {
                    return 1500;
                }
                return 500;
            } else if (tileCoordinate % 10 == 0) {
                return 500;
            }
            return 100;
        }
    }

    function coordinateIntToArr(
        uint32 tileCoordinate
    ) public pure returns (uint32[3] memory coordinateArr) {
        coordinateArr[0] = tileCoordinate / 10000;
        coordinateArr[1] = tileCoordinate % 10000;
        coordinateArr[2] = 3000 - (coordinateArr[0] + coordinateArr[1]);
    }

    function coordinateIntToStuct(
        uint32 tileCoordinate
    ) public pure returns (XYZCoordinate memory coordinate) {
        coordinate.x = tileCoordinate / 10000;
        coordinate.y = tileCoordinate % 10000;
        coordinate.z = 3000 - (coordinate.x + coordinate.y);
    }

    function spiralRingTiles(
        uint32 tileCoordinate,
        uint256 radius
    ) public pure returns (uint32[] memory) {
        uint256 blockNum = 3 * radius * radius + 3 * radius;
        uint32[] memory blocks = new uint32[](blockNum);
        blocks[0] = tileCoordinate;
        for (uint256 i = 1; i <= radius; i++) {
            uint256 preringblocks = 3 * (i - 1) * (i - 1) + 3 * (i - 1);
            tileCoordinate++;
            for (uint256 j = 0; j < 6; j++) {
                for (uint256 k = 0; k < i; k++) {
                    blocks[preringblocks + j * i + k + 1] = tileCoordinate;
                    tileCoordinate = neighbor(tileCoordinate, j);
                }
            }
        }
        return blocks;
    }

    function ringTiles(
        uint32 tileCoordinate,
        uint256 radius
    ) public pure returns (uint32[] memory) {
        uint256 blockNum = 6 * radius;
        uint32[] memory blocks = new uint32[](blockNum);

        blocks[0] = tileCoordinate;
        tileCoordinate += uint32(radius);
        for (uint256 j = 0; j < 6; j++) {
            for (uint256 k = 0; k < radius; k++) {
                blocks[j * radius + k + 1] = tileCoordinate;
                tileCoordinate = neighbor(tileCoordinate, j);
            }
        }
        return blocks;
    }

    function tileSpheres(
        uint32 tileCoordinate
    ) public pure returns (uint32[] memory) {
        uint32[] memory blocks = new uint32[](7);
        blocks[0] = tileCoordinate;
        tileCoordinate++;
        for (uint256 i = 1; i < 7; i++) {
            blocks[i] = tileCoordinate;
            tileCoordinate = neighbor(tileCoordinate, i);
        }
        return blocks;
    }

    function direction(uint256 direction_) public pure returns (int32) {
        if (direction_ == 0) {
            return 9999;
        } else if (direction_ == 1) {
            return -1;
        } else if (direction_ == 2) {
            return -10000;
        } else if (direction_ == 3) {
            return -9999;
        } else if (direction_ == 4) {
            return 1;
        } else if (direction_ == 5) {
            return 10000;
        } else {
            return 0;
        }
    }

    function neighbor(
        uint32 tileCoordinate,
        uint256 direction_
    ) public pure returns (uint32) {
        if (direction_ == 0) {
            return tileCoordinate + 9999;
        } else if (direction_ == 1) {
            return tileCoordinate - 1;
        } else if (direction_ == 2) {
            return tileCoordinate - 10000;
        } else if (direction_ == 3) {
            return tileCoordinate - 9999;
        } else if (direction_ == 4) {
            return tileCoordinate + 1;
        } else if (direction_ == 5) {
            return tileCoordinate + 10000;
        } else {
            revert();
        }
    }

    function distance(uint32 a, uint32 b) public pure returns (uint32 d) {
        XYZCoordinate memory aarr = coordinateIntToStuct(a);
        XYZCoordinate memory barr = coordinateIntToStuct(b);

        d += aarr.x > barr.x ? aarr.x - barr.x : barr.x - aarr.x;
        d += aarr.y > barr.y ? aarr.y - barr.y : barr.y - aarr.y;
        d += aarr.z > barr.z ? aarr.z - barr.z : barr.z - aarr.z;

        return d / 2;
    }

    function coordinateToXY(
        uint32 tileCoordinate
    ) public pure returns (XYCoordinate memory xycoordinate) {
        xycoordinate.x = int32(tileCoordinate / 10000) - 1000;
        xycoordinate.y = int32(tileCoordinate % 10000) - 1000;
    }

    function tileToBitIndex(
        uint32 tileCoordinate
    ) public pure returns (uint256 index) {
        uint32 x = tileCoordinate / 10000;
        uint32 y = tileCoordinate % 10000;
        if (x >= 1000 && y >= 1000) {
            x = x - 1000;
            y = y - 1000;
        } else if (x >= 1000 && y < 1000) {
            x = x - 1000;
            y = 1000 - y;
            index = 640000;
        } else if (x < 1000 && y <= 1000) {
            x = 1000 - x;
            y = 1000 - y;
            index = 1280000;
        } else {
            x = 1000 - x;
            y = y - 1000;
            index = 1920000;
        }

        index += ((y / 16) * 50 + x / 16) * 256 + (y % 16) * 16 + (x % 16);
    }
}
