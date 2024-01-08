// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

library MintMath {
    struct MintArgs {
        uint128 p;
        uint16 aNumerator;
        uint16 aDenominator;
        uint16 bNumerator;
        uint16 bDenominator;
        uint16 c;
        uint16 d;
    }

    struct Anchor {
        MintArgs args;
        uint256 lastTimestamp;
        uint256 n;
    }

    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        assembly {
            let c := mul(a, b)
            result := div(c, denominator)
        }
        return result;
    }

    function initialize(
        Anchor storage last,
        MintArgs memory args,
        uint256 time
    ) internal {
        last.args = args;
        last.lastTimestamp = (time / 86400) * 86400;
        last.n = 0;
    }

    function total(Anchor storage last, uint256 endTimestamp) internal returns (uint256) {
        uint256 d = last.args.d;
        uint256 p = last.args.p;
        uint256 an = last.args.aNumerator;
        uint256 ad = last.args.aDenominator;
        uint256 bn = last.args.bNumerator;
        uint256 bd = last.args.bDenominator;
        uint256 c = last.args.c;

        uint256 beginN = last.n + 1;
        uint256 n = last.n + ((endTimestamp / 86400) * 86400 - last.lastTimestamp) / 86400;

        uint256 result = 0;
        uint256 lastCoefficient = 0;
        uint256 lastValue = 0;

        for (uint256 i = beginN; i <= n; i++) {
            uint256 coefficient = mulDiv(bn, i-1, bd);
            uint256 value = lastValue;
            if (coefficient != lastCoefficient || i == beginN) {
                value = coefficient + c;
                value = (((an**value) * p) * 1e12) / (ad**value);
                value += d * 1e12;
                if (value < 0) value = 0;
                value = value / 1e12;
                lastValue = value;
                lastCoefficient = coefficient;
            }
            result += value;
        }

        last.lastTimestamp = endTimestamp;
        last.n = n;
        return result;
    }
}
