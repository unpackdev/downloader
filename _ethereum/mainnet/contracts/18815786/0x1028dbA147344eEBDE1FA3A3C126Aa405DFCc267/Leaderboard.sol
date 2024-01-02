// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

import "./IDougBank.sol";
import "./IDougToken.sol";

uint16 constant LEADERBOARD_PTS_TOTAL = 546;
uint32 constant MAX_LEADERBOARD_SCORE = 2097151;

contract Leaderboard {
    uint32[7] private _increments;

    uint8[DOUG_TYPES] public _leaderboard;
    uint32[DOUG_TYPES] public _typeScore; // init to zero
    uint128[DOUG_TYPES] public _typeRoyalties;

    uint8[21] public _leaderboardAmounts;

    uint8[21] private _top20Amounts;
    uint8 private top20Count;
    uint8[21] private _top20TiedAmounts;
    uint8 private completeCount;

    constructor() {
        _increments[1] = 1;
        _increments[2] = 64;
        _increments[3] = 2048;
        _increments[4] = 32768;
        _increments[5] = 262144;
        _increments[6] = 1048576;

        for (uint8 i = 0; i < 100; i++) {
            // the very first entry is not an actual flavor, we use it to find the start of the flavor list
            _leaderboard[i] = i;
        }

        _top20Amounts[0] = 100;
        _top20Amounts[1] = 76;
        _top20Amounts[2] = 60;
        _top20Amounts[3] = 50;
        _top20Amounts[4] = 42;
        _top20Amounts[5] = 36;
        _top20Amounts[6] = 31;
        _top20Amounts[7] = 27;
        _top20Amounts[8] = 23;
        _top20Amounts[9] = 20;
        _top20Amounts[10] = 17;
        _top20Amounts[11] = 14;
        _top20Amounts[12] = 12;
        _top20Amounts[13] = 10;
        _top20Amounts[14] = 8;
        _top20Amounts[15] = 7;
        _top20Amounts[16] = 5;
        _top20Amounts[17] = 4;
        _top20Amounts[18] = 3;
        _top20Amounts[19] = 2;
        _top20Amounts[20] = 0; // have an extra entry to elimate need for a bounds check

        _top20TiedAmounts[0] = 100;
        _top20TiedAmounts[1] = 88;
        _top20TiedAmounts[2] = 78;
        _top20TiedAmounts[3] = 71;
        _top20TiedAmounts[4] = 65;
        _top20TiedAmounts[5] = 60;
        _top20TiedAmounts[6] = 56;
        _top20TiedAmounts[7] = 53;
        _top20TiedAmounts[8] = 49;
        _top20TiedAmounts[9] = 46;
        _top20TiedAmounts[10] = 43;
        _top20TiedAmounts[11] = 41;
        _top20TiedAmounts[12] = 39;
        _top20TiedAmounts[13] = 36;
        _top20TiedAmounts[14] = 35;
        _top20TiedAmounts[15] = 33;
        _top20TiedAmounts[16] = 31;
        _top20TiedAmounts[17] = 30;
        _top20TiedAmounts[18] = 28;
        _top20TiedAmounts[19] = 27;
        _top20TiedAmounts[20] = 0; // last entry (21st place ) stops the top20 Bonus altogether
    }

    function updateLeaderboard(uint8 _rank, uint8 _type) internal {
        uint32 _delta = _increments[_rank];

        uint32 _newTypeScore = _typeScore[_type] + _delta;

        _typeScore[_type] = _newTypeScore;

        // Activate each of the leaderboard top20 payout slots as each of the first 20 types enter the top20

        if (_newTypeScore == 1) {
            if (top20Count < 20) {
                _leaderboardAmounts[top20Count] = _top20Amounts[top20Count];
                top20Count++;
            }
        }

        // Flatten Top20 rewards when top spot is tied
        // When all 20 are tied, top20 rewards go to 0 and
        // so top20 portion will now distributes across all 100 Doug Flavors

        if (_newTypeScore == MAX_LEADERBOARD_SCORE) {
            if (completeCount < 21) {
                completeCount++;
                for (uint8 i = completeCount; i > 0; i--) {
                    _leaderboardAmounts[i - 1] = _top20TiedAmounts[completeCount - 1];
                }
            }
        }

        // Scan list backward (0 is highest score) from current position copying forward until we find new position
        // Also copy forward the array of _typeRoyalties each time
        // (At the start this may take up to 99 iterations)

        uint8 pos = leaderboardPosition(_type); // find where this type is in the leaderboard (0 is highest)
        uint128 thisRoyalty = _typeRoyalties[pos];

        while (pos > 0) {
            // only check/loop while current pos is not the highest
            uint8 nextType = _leaderboard[pos - 1];
            if (_newTypeScore > _typeScore[nextType]) {
                _leaderboard[pos] = nextType; // relocate the exisitng type that *was* higher in the leaderboard
                _typeRoyalties[pos] = _typeRoyalties[pos - 1]; // relocate the coreespnding Royalty total
            } else {
                break;
            }
            pos--;
        }
        _leaderboard[pos] = _type;
        _typeRoyalties[pos] = thisRoyalty;
    }

    function typeScores() public view returns (uint32[100] memory) {
        return _typeScore;
    }

    function leaderboard() public view returns (uint8[DOUG_TYPES] memory) {
        return _leaderboard;
    }

    function leaderboardPosition(uint8 _type) public view returns (uint8) {
        uint8 pos = 0;
        while (_leaderboard[pos] != _type) {
            pos++;
        }
        return pos;
    }
}
