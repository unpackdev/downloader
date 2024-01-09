// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./SafeCast.sol";

library PredyMath {
    function max(uint128 a, uint128 b) internal pure returns (uint128) {
        return a > b ? a : b;
    }

    function min(uint128 a, uint128 b) internal pure returns (uint128) {
        return a > b ? b : a;
    }

    function abs(int128 x) internal pure returns (uint128) {
        return uint128(x >= 0 ? x : -x);
    }

    function mulDiv(
        uint256 _x,
        uint256 _y,
        uint256 _d,
        bool _roundUp
    ) internal pure returns (uint128) {
        uint256 tailing;
        if (_roundUp) {
            uint256 remainer = (_x * _y) % _d;
            if (remainer > 0) {
                tailing = 1;
            }
        }

        uint256 result = (_x * _y) / _d + tailing;

        return SafeCast.toUint128(result);
    }

    function scale(
        uint256 _a,
        uint256 _from,
        uint256 _to
    ) internal pure returns (uint256) {
        if (_from > _to) {
            return _a / 10**(_from - _to);
        } else if (_from < _to) {
            return _a * 10**(_to - _from);
        } else {
            return _a;
        }
    }

    function toInt128(uint256 _a) internal pure returns (int128) {
        return SafeCast.toInt128(SafeCast.toInt256(_a));
    }
}
