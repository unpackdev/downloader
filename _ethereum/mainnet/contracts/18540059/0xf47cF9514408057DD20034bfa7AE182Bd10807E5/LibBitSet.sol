// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "./LibBit.sol";

interface ILibBitSet64Filter {
    function isTokenOwner(address owner, uint256 idx) external view returns (bool);
}

library LibBitSet {

    uint256 public constant NOT_FOUND = type(uint256).max;
    uint256 private constant MAX_MASK = type(uint256).max;
    uint256 private constant MAX_INDEX = 16383;
    uint256 private constant FIXED_LENGTH = 64;
    uint16 public constant MAX_POP_COUNT = 256;
    uint16 private constant MASK_LENGTH = 0xFFFF;
    uint8 private constant MAX_BIT_COUNT = 255;
    uint8 private constant MASK_BIT_COUNT = 0xFF;
    uint8 private constant INDEX_SHIFT = 8;
    uint8 private constant INDEX_MASK = 0xFF;
    uint8 private constant INDEX_NOT_FOUND = 0xFF;
    uint8 private constant OFFSET_BUCKET_FLAGS = 192;

    struct Set {
        uint256 offset;
        uint256 count;
        uint256[2] popCounts;
        uint256[64] map;
    }

    function add(Set storage self,
        uint256 tokenId
    ) internal returns (uint256) {
        uint256 count = self.count;
        unchecked {
            tokenId -= self.offset;
            if (tokenId > MAX_INDEX) return uint16(count);
            uint8 bucket = uint8(tokenId >> INDEX_SHIFT);
            uint256 bitIndex = tokenId & INDEX_MASK;
            uint256 mask = 1 << bitIndex;
            uint256 bitmap = self.map[bucket];
            if ((bitmap & mask) == 0) {
                bitmap |= mask;
                self.map[bucket] = bitmap;
                if (bitmap != MAX_MASK) {
                    _addPopCount(self, bucket, 1);
                }
                count = ((count & ~(1 << (bucket + OFFSET_BUCKET_FLAGS))) ^ (((~(bitmap + 1) & bitmap) >> MAX_BIT_COUNT)
                    << (bucket + OFFSET_BUCKET_FLAGS))) + 1;
                self.count = count;
            }
        }
        return uint16(count);
    }

    function addBatch(Set storage self,
        uint256 startId,
        uint256 amount
    ) internal {
        unchecked {
            startId -= self.offset;
            if (startId > MAX_INDEX) return;
            uint256[2] memory popCounts = self.popCounts;
            uint256 mask = 0;
            uint256 delta = 0;
            uint256 count = self.count + amount;
            uint8 bits = 0;
            uint8 bucket = uint8(startId >> INDEX_SHIFT);
            uint8 shift = uint8(startId & INDEX_MASK);
            while (amount > 0) {
                delta = MAX_POP_COUNT - shift;
                if (amount >= delta) {
                    mask = MAX_MASK << shift;
                    bits = MAX_BIT_COUNT - shift;
                    count |= (1 << (bucket + OFFSET_BUCKET_FLAGS));
                    amount -= delta;
                    shift = 0;
                } else {
                    mask = ((1 << amount) - 1) << shift;
                    bits = uint8(amount);
                    count &= ~(1 << (bucket + OFFSET_BUCKET_FLAGS));
                    amount = 0;
                }
                _addPopCounts(popCounts, bucket, bits);
                self.map[bucket] |= mask;
                bucket++;
            }
            self.popCounts = popCounts;
            self.count = count;
        }
    }

    function remove(Set storage self,
        uint256 tokenId
    ) internal returns (bool) {
        unchecked {
            tokenId -= self.offset;
            uint8 bucket = uint8(tokenId >> INDEX_SHIFT);
            if (bucket >= FIXED_LENGTH) return false;
            uint256 bitmap = self.map[bucket];
            uint256 mask = 1 << (tokenId & INDEX_MASK);
            if ((bitmap & mask) == 0) return false;
            uint256 count = self.count;
            uint256 offset = bucket + OFFSET_BUCKET_FLAGS;
            if (((count >> offset) & 1) == 0) {
                _subPopCount(self, bucket, 1);
            }
            self.count = (count - 1) & ~(1 << offset);
            self.map[bucket] = bitmap & ~mask;
            return true;
        }
    }

    function removeAt(Set storage self,
        uint256 index
    ) internal returns (uint256) {
        uint256 count = self.count;
        if (index >= uint16(count)) return NOT_FOUND;
        uint256[2] memory popCounts = self.popCounts;
        (uint256 bucket, uint16 remaining) = _positionOfIndex(count, popCounts, uint16(index));
        if (bucket == INDEX_NOT_FOUND) return NOT_FOUND;
        uint256 bit;
        uint256 pos;
        uint256 offset;
        uint256 bitmap = self.map[bucket];
        unchecked {
            while (bitmap != 0) {
                bit = bitmap & (~bitmap + 1);
                pos = LibBit.fls(bit);
                if (remaining == 0) {
                    offset = bucket + OFFSET_BUCKET_FLAGS;
                    if (((count >> offset) & 1) == 0) {
                        _subPopCounts(popCounts, uint8(bucket), 1);
                        self.popCounts = popCounts;
                    }
                    self.count = (count - 1) & ~(1 << offset);
                    self.map[bucket] ^= bit;
                    return ((bucket << INDEX_SHIFT) | pos) + self.offset;
                }
                remaining--;
                bitmap ^= bit;
            }
        }
        return NOT_FOUND;
    }

    function contains(Set storage self,
        uint256 tokenId
    ) internal view returns (bool isSet) {
        unchecked {
            tokenId -= self.offset;
            uint256 bucket = tokenId >> INDEX_SHIFT;
            if (bucket >= FIXED_LENGTH) return false;
            uint256 bit = (self.map[bucket] >> (tokenId & INDEX_MASK)) & 1;
            /// @solidity memory-safe-assembly
            assembly {
                isSet := bit
            }
        }
    }

    function at(Set storage self,
        uint256 index
    ) internal view returns (uint256) {
        if (index >= uint16(self.count)) return NOT_FOUND;
        uint256 len = 0;
        uint256 bitmap;
        uint256 bitsCount;
        uint256 remaining;
        uint256 bucket;
        uint256 bit;
        uint256 pos;
        unchecked {
            for (bucket = 0; bucket < FIXED_LENGTH; ++bucket) {
                bitmap = self.map[bucket];
                bitsCount = LibBit.popCount(bitmap);
                if (len + bitsCount > index) {
                    remaining = index - len;
                    while (bitmap != 0) {
                        bit = bitmap & (~bitmap + 1);
                        pos = LibBit.fls(bit);
                        if (remaining == 0) {
                            return ((bucket << INDEX_SHIFT) | pos) + self.offset;
                        }
                        remaining--;
                        bitmap ^= bit;
                    }
                }
                len += bitsCount;
            }
        }
        return NOT_FOUND;
    }

    function findFirst(Set storage self
    ) internal view returns (uint256) {
        if (self.count == 0) return NOT_FOUND;
        uint256 bitmap;
        uint256 lsb;
        unchecked {
            for (uint256 bucket = 0; bucket < FIXED_LENGTH; bucket++) {
                bitmap = self.map[bucket];
                if (bitmap != 0) {
                    lsb = LibBit.ffs(bitmap);
                    return (bucket << INDEX_SHIFT | lsb) + self.offset;
                }
            }
        }
        return NOT_FOUND;
    }

    function findFirstOfOwner(Set storage self,
        address owner,
        ILibBitSet64Filter filter
    ) internal view returns (uint256) {
        uint256 count = self.count;
        if (count == 0) return NOT_FOUND;
        unchecked {
            uint256 offset = self.offset;
            uint256 bitmap;
            uint256 tokenId;
            uint256 pos;
            for (uint256 bucket = 0; bucket < FIXED_LENGTH; bucket++) {
                bitmap = self.map[bucket];
                while (bitmap != 0) {
                    pos = LibBit.ffs(bitmap);
                    tokenId = ((bucket << INDEX_SHIFT) | pos) + offset;
                    if (filter.isTokenOwner(owner, tokenId)) return tokenId;
                    bitmap &= ~(1 << pos);
                }
            }
        }
        return NOT_FOUND;
    }

    function findNearest(Set storage self,
        uint256 index
    ) internal view returns (uint256) {
        if (self.count == 0) return NOT_FOUND;
        unchecked {
            index -= self.offset;
            uint256 bucket = index >> INDEX_SHIFT;
            uint256 bitIndex = index & INDEX_MASK;
            uint256 bitmap = bucket < FIXED_LENGTH ? self.map[bucket] : 0;
            if ((bitmap >> bitIndex) & 1 == 1) {
                return index + self.offset;
            }
            for (uint256 i = bucket; i < FIXED_LENGTH; i++) {
                bitmap = self.map[i];
                if (bitmap != 0) {
                    return (i << INDEX_SHIFT) | LibBit.fls(bitmap) + self.offset;
                }
            }
        }
        return NOT_FOUND;
    }

    function findLast(Set storage self) internal view returns (uint256) {
        if (self.count == 0) return NOT_FOUND;
        for (uint256 bucket = FIXED_LENGTH; bucket > 0; bucket--) {
            if (self.map[bucket - 1] != 0) {
                uint256 bitIndex = LibBit.fls(self.map[bucket - 1]);
                return ((bucket - 1) << INDEX_SHIFT) + bitIndex + self.offset;
            }
        }
        return 0;
    }

    function mapRange(Set storage self
    ) internal view returns (uint256 start, uint256 len) {
        unchecked {
            for (uint256 i = 0; i < FIXED_LENGTH; i++) {
                if (self.map[i] != 0) {
                    start = (i << INDEX_SHIFT) + LibBit.ffs(self.map[i]);
                    break;
                }
            }
            for (uint256 i = FIXED_LENGTH; i > 0; i--) {
                if (self.map[i - 1] != 0) {
                    len = ((i - 1) << INDEX_SHIFT) + LibBit.fls(self.map[i - 1]);
                    break;
                }
            }
            len += 1;
        }
        return (start, len);
    }

    function getRange(Set storage self,
        uint256 start,
        uint256 stop
    ) internal view returns (uint256[] memory) {
        unchecked {
            uint256 count = uint16(self.count);
            stop = (stop > count) ? count : stop;
            uint256 startBucket = (start - self.offset) >> INDEX_SHIFT;
            uint256 endBucket = (stop - self.offset) >> INDEX_SHIFT;
            uint256 arraySize = stop - start + 1;
            uint256[] memory result = new uint256[](arraySize);
            uint256 resultIndex = 0;
            uint256 bucketBits;
            for (uint256 i = startBucket; i <= endBucket && i < FIXED_LENGTH; ++i) {
                bucketBits = self.map[i];
                if (bucketBits == 0) continue;
                for (uint256 j = 0; j < MAX_POP_COUNT; ++j) {
                    uint256 bitIndex = (i << INDEX_SHIFT) + j + self.offset;
                    if (bitIndex < start) continue;
                    if (bitIndex > stop) break;
                    if ((bucketBits & (1 << j)) != 0) {
                        result[resultIndex++] = bitIndex;
                    }
                }
            }
            if (resultIndex < arraySize) {
                assembly {
                    mstore(result, resultIndex)
                }
            }
            return result;
        }
    }

    function rangeLength(Set storage self
    ) internal view returns (uint256) {
        unchecked {
            uint256 bitmap;
            for (uint256 bucket = (FIXED_LENGTH - 1); bucket >= 0; bucket--) {
                bitmap = self.map[bucket];
                if (bitmap != 0) {
                    return (bucket << INDEX_SHIFT) + LibBit.fls(bitmap) + 1;
                }
            }
        }
        return 0;
    }

    function mapLength(Set storage
    ) internal pure returns (uint256) {
        return FIXED_LENGTH;
    }

    function length(Set storage self
    ) internal view returns (uint256) {
        return self.count & MASK_LENGTH;
    }

    function trim(Set storage self
    ) internal {
        uint256 len = self.map.length;
        while (len > 0 && self.map[len - 1] == 0) {
            delete self.map[--len];
        }
    }

    function values(Set storage self
    ) internal view returns (uint256[] memory result) {
        result = new uint256[](uint16(self.count));
        uint256 index = 0;
        uint256 offset = self.offset;
        for (uint256 i = 0; i < FIXED_LENGTH; i++) {
            uint256 bucket = self.map[i];
            if (bucket == 0) continue;
            for (uint256 j = 0; j < MAX_POP_COUNT; j++) {
                if ((bucket & (1 << j)) == 0) continue;
                result[index] = ((i << INDEX_SHIFT) | j) + offset;
                index++;
            }
        }
    }

    function _addPopCount(Set storage self,
        uint8 slot,
        uint8 amount
    ) private {
        unchecked {
            self.popCounts[slot >> 5] += uint256(amount & INDEX_MASK) << ((slot & 31) << 3);
        }
    }

    function _addPopCounts(
        uint256[2] memory popCounts,
        uint8 slot,
        uint8 amount
    ) private pure {
        unchecked {
            popCounts[slot >> 5] += uint256(amount & INDEX_MASK) << ((slot & 31) << 3);
        }
    }

    function _subPopCount(Set storage self,
        uint8 slot,
        uint8 amount
    ) private {
        unchecked {
            self.popCounts[slot >> 5] -= uint256(amount & INDEX_MASK) << ((slot & 31) << 3);
        }
    }

    function _subPopCounts(
        uint256[2] memory popCounts,
        uint8 slot,
        uint8 amount
    ) private pure {
        unchecked {
            popCounts[slot >> 5] -= uint256(amount & INDEX_MASK) << ((slot & 31) << 3);
        }
    }

    function _getPopCount(
        uint256 count,
        uint256[2] memory popCounts,
        uint256 slot
    ) private pure returns (uint16) {
        return ((count >> (slot + OFFSET_BUCKET_FLAGS)) & 1) == 1 ? MAX_POP_COUNT :
            uint16((popCounts[slot >> 5] >> ((slot & 31) << 3)) & MASK_BIT_COUNT);
    }

    function _positionOfIndex(
        uint256 count,
        uint256[2] memory popCounts,
        uint16 index
    ) private pure returns (uint8 bucket, uint16 /*pos*/) {
        unchecked {
            if (index > uint16(count)) return (INDEX_NOT_FOUND, 0);
            uint16 total = 0;
            uint16 popCount = 0;
            uint16 next = 0;
            for (bucket = 0; bucket < FIXED_LENGTH; ++bucket) {
                popCount = _getPopCount(count, popCounts, bucket);
                next = total + popCount;
                if (next > index) return (bucket, index - total);
                total = next;
            }
            return (INDEX_NOT_FOUND, 0);
        }
    }
}
