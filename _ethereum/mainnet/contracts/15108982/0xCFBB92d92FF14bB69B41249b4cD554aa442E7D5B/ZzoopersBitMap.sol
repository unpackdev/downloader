// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ZzoopersBitMaps {
    struct ZzoopersBitMap {
        uint32 _cap; //The cap of BitMap
        uint32 _used; //The used bit in BitMap;
        //Bucket => bitMap, the first 8 bits of bitMap is the count of used bits, so the cap of a bucket is (32 - 1) * 8 = 248;
        mapping(uint256 => uint256) _bits;
    }

    function cap(ZzoopersBitMap storage bitMap)
        internal
        view
        returns (uint256)
    {
        return bitMap._cap;
    }

    function init(ZzoopersBitMap storage bitMap, uint32 _cap) internal {
        bitMap._cap = _cap;
    }

    function unused(ZzoopersBitMap storage bitMap)
        internal
        view
        returns (uint256)
    {
        return bitMap._cap - bitMap._used;
    }

    function getBits(ZzoopersBitMap storage bitMap, uint256 bucket)
        internal
        view
        returns (uint256)
    {
        return bitMap._bits[bucket];
    }

    /**
     * @dev Sets the bit at `index`, if the bit has already been set, try the next bit until find a unset bit.
     * @dev Returns the really set index.
     */
    function trySetTo(ZzoopersBitMap storage bitMap, uint256 index)
        internal
        returns (uint256 setIndex)
    {
        require(index < bitMap._cap, "ZooBitMap: Index out of range");
        require(bitMap._cap - bitMap._used > 0, "ZooBitMap: Out of cap");

        unchecked {
            uint256 bucket = index / 248;
            uint256 i = index % 248; // index in bucket;
            uint256 maxBucket = bitMap._cap / 248;
            if (bitMap._cap % 248 != 0) {
                maxBucket++;
            }

            bool success = false;
            while (true) {
                uint256 bits = bitMap._bits[bucket];
                uint256 usedOfBucket = (bits >> 248) & 0xff;
                if (usedOfBucket < 248) {
                    uint256 bound = bitMap._cap - bucket * 248;
                    if (bound > 248) {
                        bound = 248;
                    }
                    for (; i < bound; i++) {
                        uint256 mask = 1 << (i & 0xff);
                        if (mask & bits == 0) {
                            //found a unused bit
                            bits = bits | mask; // set bit
                            usedOfBucket++;
                            mask = usedOfBucket << 248;
                            bits = ((bits << 8) >> 8) | mask; // update usedOfBucket
                            bitMap._bits[bucket] = bits; //update bits in bucket
                            bitMap._used++;
                            success = true;
                            break;
                        }
                    }
                    if (success) {
                        break;
                    }
                }
                //move to next bucket
                i = 0;
                bucket++;
                if (bucket == maxBucket) {
                    bucket = 0;
                }
            }
            setIndex = bucket * 248 + i;
        }

        return setIndex;
    }
}
