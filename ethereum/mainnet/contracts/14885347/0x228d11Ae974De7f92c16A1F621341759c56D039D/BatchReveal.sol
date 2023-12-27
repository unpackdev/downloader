//SPDX-License-Identifier: CC0
pragma solidity ^0.8.2;

import "./Strings.sol";

// Forked from tubby-cats
abstract contract BatchReveal {
    uint256 public constant TOKEN_LIMIT = 10000;
    uint256 public constant REVEAL_BATCH_SIZE = 200;
    mapping(uint256 => uint256) public batchToSeed;
    uint256 public lastTokenRevealed = 0; // in [0-9999]. offset not included

    struct Range {
        int128 start;
        int128 end;
    }

    event LogReveal(uint256 indexed lastTokenRevealed);

    // Forked from openzeppelin
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(int128 a, int128 b) internal pure returns (int128) {
        return a < b ? a : b;
    }

    uint256 constant RANGE_LENGTH = (TOKEN_LIMIT / REVEAL_BATCH_SIZE) * 2;
    int128 constant intTOKEN_LIMIT = int128(int256(TOKEN_LIMIT));

    // ranges include the start but not the end [start, end)
    function addRange(
        Range[RANGE_LENGTH] memory ranges,
        int128 start,
        int128 end,
        uint256 lastIndex
    ) private pure returns (uint256) {
        uint256 positionToAssume = lastIndex;
        for (uint256 j = 0; j < lastIndex; j++) {
            int128 rangeStart = ranges[j].start;
            int128 rangeEnd = ranges[j].end;
            if (start < rangeStart && positionToAssume == lastIndex) {
                positionToAssume = j;
            }
            if (
                (start < rangeStart && end > rangeStart) ||
                (rangeStart <= start && end <= rangeEnd) ||
                (start < rangeEnd && end > rangeEnd)
            ) {
                int128 length = end - start;
                start = min(start, rangeStart);
                end = start + length + (rangeEnd - rangeStart);
                ranges[j] = Range(-1, -1); // Delete
            }
        }
        for (uint256 pos = lastIndex; pos > positionToAssume; pos--) {
            ranges[pos] = ranges[pos - 1];
        }
        ranges[positionToAssume] = Range(start, min(end, intTOKEN_LIMIT));
        lastIndex++;
        if (end > intTOKEN_LIMIT) {
            addRange(ranges, 0, end - intTOKEN_LIMIT, lastIndex);
            lastIndex++;
        }
        return lastIndex;
    }

    function buildJumps(uint256 lastBatch)
        view
        private
        returns (Range[RANGE_LENGTH] memory)
    {
        Range[RANGE_LENGTH] memory ranges;
        uint256 lastIndex = 0;

        for (uint256 i = 0; i < lastBatch; i++) {
            int128 start = int128(
                int256(getFreeTokenId(batchToSeed[i], ranges))
            );
            int128 end = start + int128(int256(REVEAL_BATCH_SIZE));
            lastIndex = addRange(ranges, start, end, lastIndex);
        }
        return ranges;
    }

    function getShuffledTokenId(uint256 startId) view internal returns (uint256) {
        uint256 batch = startId / REVEAL_BATCH_SIZE;
        Range[RANGE_LENGTH] memory ranges = buildJumps(batch);
        uint256 positionsToMove = (startId % REVEAL_BATCH_SIZE) +
            batchToSeed[batch];
        return getFreeTokenId(positionsToMove, ranges);
    }

    function getFreeTokenId(
        uint256 positionsToMoveStart,
        Range[RANGE_LENGTH] memory ranges
    ) pure private returns (uint256) {
        int128 positionsToMove = int128(int256(positionsToMoveStart));
        int128 id = 0;
        for (uint256 round = 0; round < 2; round++) {
            for (uint256 i = 0; i < RANGE_LENGTH; i++) {
                int128 start = ranges[i].start;
                int128 end = ranges[i].end;
                if (id < start) {
                    int128 finalId = id + positionsToMove;
                    if (finalId < start) {
                        return uint256(uint128(finalId));
                    } else {
                        positionsToMove -= start - id;
                        id = end;
                    }
                } else if (id < end) {
                    id = end;
                }
            }
            if ((id + positionsToMove) >= intTOKEN_LIMIT) {
                positionsToMove -= intTOKEN_LIMIT - id;
                id = 0;
            }
        }
        return uint256(uint128(id + positionsToMove));
    }

    function setBatchSeed(uint256 randomness) internal {
        uint256 batchNumber;
        unchecked {
            batchNumber = lastTokenRevealed / REVEAL_BATCH_SIZE;
            lastTokenRevealed += REVEAL_BATCH_SIZE;
        }
        // not perfectly random since the folding doesn't match bounds perfectly, but difference is small
        batchToSeed[batchNumber] =
            randomness %
            (TOKEN_LIMIT - (batchNumber * REVEAL_BATCH_SIZE));
        
        emit LogReveal(lastTokenRevealed);
    }
}
