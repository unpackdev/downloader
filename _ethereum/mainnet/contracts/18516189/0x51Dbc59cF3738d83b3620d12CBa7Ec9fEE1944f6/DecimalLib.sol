// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "./Math.sol";

/**
 * @title DecimalLib library to perform decimal math operations.
 */
library DecimalLib {
    /**
     * Converts int256 answer scaled at iDecimals to scale at oDecimals.
     * Source oracle adapters should pass 18 for oDecimals, while destination adapters should pass 18 for iDecimals.
     * Warning: When downscaling (i.e., when iDecimals > oDecimals), the conversion can lead to a loss of precision.
     * In the worst case, if the answer is small enough, the conversion can return zero.
     * Warning: When upscaling (i.e., when iDecimals < oDecimals), if answer * 10^(oDecimals - iDecimals) exceeds
     * the maximum int256 value, this function will revert. Ensure the provided values will not cause an overflow.
     */
    function convertDecimals(int256 answer, uint8 iDecimals, uint8 oDecimals) internal pure returns (int256) {
        if (iDecimals == oDecimals) return answer;
        if (iDecimals < oDecimals) return answer * int256(10 ** (oDecimals - iDecimals));
        return answer / int256(10 ** (iDecimals - oDecimals));
    }

    /**
     * Converts uint256 answer scaled at iDecimals to scale at oDecimals.
     * Source oracle adapters should pass 18 for oDecimals, while destination adapters should pass 18 for iDecimals.
     * Warning: When downscaling (i.e., when iDecimals > oDecimals), the conversion can lead to a loss of precision.
     * In the worst case, if the answer is small enough, the conversion can return zero.
     * Warning: When upscaling (i.e., when iDecimals < oDecimals), if answer * 10^(oDecimals - iDecimals) exceeds
     * the maximum uint256 value, this function will revert. Ensure the provided values will not cause an overflow.
     */
    function convertDecimals(uint256 answer, uint8 iDecimals, uint8 oDecimals) internal pure returns (uint256) {
        if (iDecimals == oDecimals) return answer;
        if (iDecimals < oDecimals) return answer * 10 ** (oDecimals - iDecimals);
        return answer / 10 ** (iDecimals - oDecimals);
    }

    // Derives token decimals from its scaling factor.
    function deriveDecimals(uint256 scalingFactor) internal pure returns (uint8) {
        uint256 decimals = Math.log10(scalingFactor);

        // Verify that the inverse operation yields the expected result.
        require(10 ** decimals == scalingFactor, "Invalid scalingFactor");

        // Note: decimals must fit within uint8 because:
        // 2^8 = 256, which is uint8 max.
        // This would imply an input scaling factor of 1e256. The max value of uint256 is \(2^{256} - 1\), which is approximately
        // 1.2e77, but not equal to 1e256. Therefore, decimals will always fit within uint8 or the check above will fail.
        return uint8(decimals);
    }
}
