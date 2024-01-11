// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

library LibCalculator {
    uint256 internal constant PERCENTAGE_BASE = 10000; // Represents 100%
    uint256 internal constant MAX_REDEMPTION_PART = 100; // Represents 1%

    function mulWithPrecisionFactor(uint256 _x, uint256 _y) internal pure returns (uint256) {
        return (_x * _y) / 1e18;
    }

    function modWithPrecisionFactor(uint256 _x) internal pure returns (uint256) {
        return _x % 1e18;
    }
}
