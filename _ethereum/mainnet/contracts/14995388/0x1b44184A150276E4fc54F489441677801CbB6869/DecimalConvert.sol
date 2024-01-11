// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

library DecimalConvert {
    uint256 private constant UINT256_MAX_DECIMALS = 77;

    function convertDecimal(
        uint256 value,
        uint256 from,
        uint256 to
    ) internal pure returns (uint256) {
        if (from > to + UINT256_MAX_DECIMALS) {
            return 0;
        } else if (from > to) {
            return value / (10**(from - to));
        } else if (from < to) {
            return value * (10**(to - from));
        } else {
            return value;
        }
    }
}
