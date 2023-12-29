pragma solidity ^0.6.6;

library MathUtils {

    /**
     * @notice Returns the square root of an uint256 x
     * - Uses the Babylonian method, but using (x + 1) / 2 as initial guess in order to have decreasing guessing iterations
     * which allow to do z < y instead of checking that z*z is within a range of precision respect to x
     * @param x The number to calculate the sqrt from
     * @return The root
     */
    function sqrt(uint256 x) internal pure returns (uint256) {
        uint z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}