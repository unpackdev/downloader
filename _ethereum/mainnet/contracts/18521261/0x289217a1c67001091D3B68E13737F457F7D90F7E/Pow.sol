// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/**
 * @title Asymetrix Protocol V2 Pow library
 * @author Asymetrix Protocol Inc Team
 * @notice A library that includes an implementation of pow function.
 */
library Pow {
    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) return 1e18;

        if (x == 0) return 0;

        require(x >> 255 == 0, "xoob");

        int256 x_int256 = int256(x);

        require(y < uint256(2 ** 254) / 1e20, "yoob");

        int256 y_int256 = int256(y);
        int256 logx_times_y = (_ln(x_int256) * y_int256) / 1e18;

        require(-41e18 <= logx_times_y && logx_times_y <= 130e18, "poob");

        return uint256(_exp(logx_times_y));
    }

    int256 private constant X0 = 128000000000000000000; // 2ˆ7
    int256 private constant A0 = 38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
    int256 private constant X1 = 64000000000000000000; // 2ˆ6
    int256 private constant A1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)
    int256 private constant X2 = 3200000000000000000000; // 2ˆ5
    int256 private constant A2 = 7896296018268069516100000000000000; // eˆ(x2)
    int256 private constant X3 = 1600000000000000000000; // 2ˆ4
    int256 private constant A3 = 888611052050787263676000000; // eˆ(x3)
    int256 private constant X4 = 800000000000000000000; // 2ˆ3
    int256 private constant A4 = 298095798704172827474000; // eˆ(x4)
    int256 private constant X5 = 400000000000000000000; // 2ˆ2
    int256 private constant A5 = 5459815003314423907810; // eˆ(x5)
    int256 private constant X6 = 200000000000000000000; // 2ˆ1
    int256 private constant A6 = 738905609893065022723; // eˆ(x6)
    int256 private constant X7 = 100000000000000000000; // 2ˆ0
    int256 private constant A7 = 271828182845904523536; // eˆ(x7)
    int256 private constant X8 = 50000000000000000000; // 2ˆ-1
    int256 private constant A8 = 164872127070012814685; // eˆ(x8)
    int256 private constant X9 = 25000000000000000000; // 2ˆ-2
    int256 private constant A9 = 128402541668774148407; // eˆ(x9)
    int256 private constant X10 = 12500000000000000000; // 2ˆ-3
    int256 private constant A10 = 113314845306682631683; // eˆ(x10)
    int256 private constant X11 = 6250000000000000000; // 2ˆ-4
    int256 private constant A11 = 106449445891785942956; // eˆ(x11)

    function _ln(int256 a) private pure returns (int256) {
        if (a < 1e18) return -_ln((1e18 * 1e18) / a);

        int256 sum = 0;

        if (a >= A0 * 1e18) {
            a /= A0;
            sum += X0;
        }

        if (a >= A1 * 1e18) {
            a /= A1;
            sum += X1;
        }

        sum *= 100;
        a *= 100;

        if (a >= A2) {
            a = (a * 1e20) / A2;
            sum += X2;
        }

        if (a >= A3) {
            a = (a * 1e20) / A3;
            sum += X3;
        }

        if (a >= A4) {
            a = (a * 1e20) / A4;
            sum += X4;
        }

        if (a >= A5) {
            a = (a * 1e20) / A5;
            sum += X5;
        }

        if (a >= A6) {
            a = (a * 1e20) / A6;
            sum += X6;
        }

        if (a >= A7) {
            a = (a * 1e20) / A7;
            sum += X7;
        }

        if (a >= A8) {
            a = (a * 1e20) / A8;
            sum += X8;
        }

        if (a >= A9) {
            a = (a * 1e20) / A9;
            sum += X9;
        }

        if (a >= A10) {
            a = (a * 1e20) / A10;
            sum += X10;
        }

        if (a >= A11) {
            a = (a * 1e20) / A11;
            sum += X11;
        }

        int256 z = ((a - 1e20) * 1e20) / (a + 1e20);
        int256 z_squared = (z * z) / 1e20;
        int256 num = z;
        int256 seriesSum = num;

        num = (num * z_squared) / 1e20;
        seriesSum += num / 3;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 5;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 7;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 9;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 11;
        seriesSum *= 2;

        return (sum + seriesSum) / 100;
    }

    function _exp(int256 x) internal pure returns (int256) {
        require(x >= -41e18 && x <= 130e18, "ie");

        if (x < 0) return ((1e18 * 1e18) / _exp(-x));

        int256 firstAN;

        if (x >= X0) {
            x -= X0;
            firstAN = A0;
        } else if (x >= X1) {
            x -= X1;
            firstAN = A1;
        } else {
            firstAN = 1;
        }

        x *= 100;

        int256 product = 1e20;

        if (x >= X2) {
            x -= X2;
            product = (product * A2) / 1e20;
        }

        if (x >= X3) {
            x -= X3;
            product = (product * A3) / 1e20;
        }

        if (x >= X4) {
            x -= X4;
            product = (product * A4) / 1e20;
        }

        if (x >= X5) {
            x -= X5;
            product = (product * A5) / 1e20;
        }

        if (x >= X6) {
            x -= X6;
            product = (product * A6) / 1e20;
        }

        if (x >= X7) {
            x -= X7;
            product = (product * A7) / 1e20;
        }

        if (x >= X8) {
            x -= X8;
            product = (product * A8) / 1e20;
        }

        if (x >= X9) {
            x -= X9;
            product = (product * A9) / 1e20;
        }

        int256 seriesSum = 1e20;
        int256 term;

        term = x;
        seriesSum += term;
        term = ((term * x) / 1e20) / 2;
        seriesSum += term;
        term = ((term * x) / 1e20) / 3;
        seriesSum += term;
        term = ((term * x) / 1e20) / 4;
        seriesSum += term;
        term = ((term * x) / 1e20) / 5;
        seriesSum += term;
        term = ((term * x) / 1e20) / 6;
        seriesSum += term;
        term = ((term * x) / 1e20) / 7;
        seriesSum += term;
        term = ((term * x) / 1e20) / 8;
        seriesSum += term;
        term = ((term * x) / 1e20) / 9;
        seriesSum += term;
        term = ((term * x) / 1e20) / 10;
        seriesSum += term;
        term = ((term * x) / 1e20) / 11;
        seriesSum += term;
        term = ((term * x) / 1e20) / 12;
        seriesSum += term;

        return (((product * seriesSum) / 1e20) * firstAN) / 100;
    }
}
