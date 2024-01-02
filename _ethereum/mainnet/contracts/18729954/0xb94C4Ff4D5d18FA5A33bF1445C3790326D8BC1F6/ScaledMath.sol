// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

library ScaledMath {
    uint256 internal constant ONE = 1e18;

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / ONE;
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * ONE) / b;
    }

    function changeScale(
        uint256 a,
        uint256 from,
        uint256 to
    ) internal pure returns (uint256) {
        if (from == to) return a;
        else if (from < to) return a * 10 ** (to - from);
        else return a / 10 ** (from - to);
    }
}
