// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

library BitMaps {
    struct BitMap {
        mapping(uint256 bucket => uint256 tokenIdHasMinted) _data;
    }

    function get(BitMap storage bitmap, uint256 tokenId) internal view returns (bool) {
        uint256 bucket = tokenId >> 8;
        uint256 mask = 1 << (tokenId & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    function set(BitMap storage bitmap, uint256 tokenId) internal {
        uint256 bucket = tokenId >> 8;
        uint256 mask = 1 << (tokenId & 0xff);
        bitmap._data[bucket] |= mask;
    }

    function batchSet(BitMap storage bitmap, uint256[] memory tokenId) internal {
        uint256 bucket;
        uint256 mask;
        for (uint256 i = 0; i < tokenId.length;) {
            bucket = tokenId[i] >> 8;
            mask = 1 << (tokenId[i] & 0xff);
            bitmap._data[bucket] |= mask;
            unchecked {
                ++i;
            }
        }
    }
}
