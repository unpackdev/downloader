// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

library Math {
    // Coefficients for the expanded Pade approximant of the exponential function exp(x/y).
    uint16 private constant EXP_PADE_5_COEFF_X0_Y5 = 30240;
    uint16 private constant EXP_PADE_5_COEFF_X1_Y4 = 15120;
    uint16 private constant EXP_PADE_5_COEFF_X2_Y3 = 3360;
    uint16 private constant EXP_PADE_5_COEFF_X3_Y2 = 420;
    uint16 private constant EXP_PADE_5_COEFF_X4_Y1 = 30;
    uint16 private constant EXP_PADE_5_COEFF_X5_Y0 = 1;

    /// @notice Expanded Pade approximant of order 5 of the exponential function `exp(x/y)`.
    /// @dev The pade approximant is given by (latex notation): `\frac{\frac{x^5}{30240 y^5}+\frac{x^4}{1008 y^4}+\frac{x^3}{72 y^3}+\frac{x^2}{9 y^2}+\frac{x}{2 y}+1}{-\frac{x^5}{30240 y^5}+\frac{x^4}{1008 y^4}-\frac{x^3}{72 y^3}+\frac{x^2}{9 y^2}-\frac{x}{2 y}+1}`
    /// @dev Both the numerator and the denominator were expanded (i.e. multiplied by `30240 y^5`) to obtain integer coefficients and avoid truncation errors in the divisions.
    /// @dev See also https://www.wolframalpha.com/input?i=PadeApproximant%5BExp%5Bx%2Fy%5D%2C+%7Bx%2C+0%2C+5%7D%5D
    /// @dev The relative accuracy is <1% for `x/y <= 5`.
    /// @dev The input types are limited to 48 bits to avoid overflow in the powers (max power `x^5` hence takes 240 bits)
    /// @param x The numerator of the exponent.
    /// @param y The denominator of the exponent.
    /// @return a The numerator of the result.
    /// @return b The denominator of the result.
    function expPadeApprox5(int48 x, int48 y) internal pure returns (uint256, uint256) {
        int256 a = 0;
        int256 b = 0;

        assembly {
            let xyPowers := exp(y, 5)
            let c := 0

            c := mul(EXP_PADE_5_COEFF_X0_Y5, xyPowers)
            a := add(a, c)
            b := add(b, c)

            xyPowers := sdiv(mul(xyPowers, x), y)
            c := mul(EXP_PADE_5_COEFF_X1_Y4, xyPowers)
            a := add(a, c)
            b := sub(b, c)

            xyPowers := sdiv(mul(xyPowers, x), y)
            c := mul(EXP_PADE_5_COEFF_X2_Y3, xyPowers)
            a := add(a, c)
            b := add(b, c)

            xyPowers := sdiv(mul(xyPowers, x), y)
            c := mul(EXP_PADE_5_COEFF_X3_Y2, xyPowers)
            a := add(a, c)
            b := sub(b, c)

            xyPowers := sdiv(mul(xyPowers, x), y)
            c := mul(EXP_PADE_5_COEFF_X4_Y1, xyPowers)
            a := add(a, c)
            b := add(b, c)

            xyPowers := sdiv(mul(xyPowers, x), y)
            c := mul(EXP_PADE_5_COEFF_X5_Y0, xyPowers)
            a := add(a, c)
            b := sub(b, c)
        }

        if (b < 0) {
            a = -a;
            b = -b;
        }

        return (uint256(a), uint256(b));
    }
}
