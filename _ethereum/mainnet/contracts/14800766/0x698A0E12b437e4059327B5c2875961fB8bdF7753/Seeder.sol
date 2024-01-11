// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library Seeder {
    function pluck(string memory _prefix, uint256 _seed) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_prefix, _seed)));
    }

    function generateNumber(uint256 _average, uint256 _seed) internal pure returns (uint256) {
        uint256 c = 0;
        uint256 lower = 4;
        uint256 upper = 10;

        while (_seed > 0) {
            uint256 x = _seed & 0xffffffff;
            x = x - ((x >> 1) & 0x55555555);
            x = (x & 0x33333333) + ((x >> 2) & 0x33333333);
            x = (x + (x >> 4)) & 0x0F0F0F0F;
            x = x + (x >> 8);
            x = x + (x >> 16);
            c += x & 0x0000003F;
            _seed >>= 32;
        }

        uint256 n = (c * _average) / 128;

        if (n < _average) {
            uint256 lhs = lower * n;
            uint256 rhs = (lower - 1) * _average;
            if (lhs < rhs) {
                return 0;
            }

            return lhs - rhs;
        }

        return upper * n - (upper - 1) * _average;
    }
}
