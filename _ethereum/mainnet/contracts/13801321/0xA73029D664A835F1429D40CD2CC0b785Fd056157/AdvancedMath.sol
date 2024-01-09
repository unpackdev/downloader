/// from https://github.com/LienFinance/bondmaker
pragma solidity ^0.8.0;

library AdvancedMath {
    /// @dev sqrt(2*PI) * 10^8
    int256 internal constant SQRT_2PI_E8 = 250662827;
    /// @dev PI * 10^8
    int256 internal constant PI_E8 = 314159265;
    /// @dev Napier's constant
    int256 internal constant E_E8 = 271828182;
    /// @dev Inverse of Napier's constant (1/e)
    int256 internal constant INV_E_E8 = 36787944;

    // for CDF
    int256 internal constant p = 23164190;
    int256 internal constant b1 = 31938153;
    int256 internal constant b2 = -35656378;
    int256 internal constant b3 = 178147793;
    int256 internal constant b4 = -182125597;
    int256 internal constant b5 = 133027442;

    /**
     * @dev Calculate an approximate value of the square root of x by Babylonian method.
     */
    function sqrt(int256 x) internal pure returns (int256 y) {
        require(x >= 0, "cannot calculate the square root of a negative number");
        int256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
     * @dev Returns log(x) for any positive x.
     */
    function logTaylor(int256 inputE4) internal pure returns (int256 outputE4) {
        require(inputE4 > 1, "input should be positive number");
        int256 inputE8 = inputE4 * 1e4;
        // input x for _logTaylor1 is adjusted to 1/e < x < 1.
        while (inputE8 < INV_E_E8) {
            inputE8 = (inputE8 * E_E8) / 1e8;
            outputE4 -= 1e4;
        }
        while (inputE8 > 1e8) {
            inputE8 = (inputE8 * INV_E_E8) / 1e8;
            outputE4 += 1e4;
        }
        outputE4 += logTaylor1(inputE8 / 1e4 - 1e4);
    }

    /**
     * @notice Calculate an approximate value of the logarithm of input value by
     * Taylor expansion around 1.
     * @dev log(x + 1) = x - 1/2 x^2 + 1/3 x^3 - 1/4 x^4 + 1/5 x^5
     *                     - 1/6 x^6 + 1/7 x^7 - 1/8 x^8 + ...
     */
    function logTaylor1(int256 inputE4) internal pure returns (int256 outputE4) {
        outputE4 =
            inputE4 -
            inputE4**2 /
            (2 * 1e4) +
            inputE4**3 /
            (3 * 1e8) -
            inputE4**4 /
            (4 * 1e12) +
            inputE4**5 /
            (5 * 1e16) -
            inputE4**6 /
            (6 * 1e20) +
            inputE4**7 /
            (7 * 1e24) -
            inputE4**8 /
            (8 * 1e28);
    }

    /**
     * @notice Calculate the cumulative distribution function of standard normal
     * distribution.
     * @dev Abramowitz and Stegun, Handbook of Mathematical Functions (1964)
     * http://people.math.sfu.ca/~cbm/aands/
     * errors are less than 0.7% at -3.2
     */
    function calStandardNormalCDF(int256 inputE4) internal pure returns (int256 outputE8) {
        require(inputE4 < 440 * 1e4 && inputE4 > -440 * 1e4, "input is too large");
        int256 _inputE4 = inputE4 > 0 ? inputE4 : inputE4 * (-1);
        int256 t = 1e16 / (1e8 + (p * _inputE4) / 1e4);
        int256 X2 = (inputE4 * inputE4) / 2;
        int256 X3 = (X2 * X2) / 1e8;
        int256 X4 = (X3 * X2) / 1e8;
        int256 exp2X2 = 1e8 +
            X2 +
            (X3 / 2) +
            (X4 / 6) +
            ((X3 * X3) / (24 * 1e8)) +
            ((X2 * (X3 * X3)) / (120 * 1e16)) +
            ((X4 * X4) / (720 * 1e8)) +
            ((X2 * (X4 * X4)) / (5040 * 1e16)) +
            ((X3 * (X4 * X4)) / (40320 * 1e16)) +
            ((X4 * X4 * X4) / (362880 * 1e16)) +
            ((X2 * (X4 * X4 * X4)) / (3628800 * 1e24)) +
            ((X3 * (X4 * X4 * X4)) / (39916800 * 1e24));

        int256 Z = (1e24 / exp2X2) / SQRT_2PI_E8;
        int256 y = (b5 * t) / 1e8;
        y = ((y + b4) * t) / 1e8;
        y = ((y + b3) * t) / 1e8;
        y = ((y + b2) * t) / 1e8;
        y = 1e8 - (Z * ((y + b1) * t)) / 1e16;
        return inputE4 > 0 ? y : 1e8 - y;
    }
}
