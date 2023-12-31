// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./Constants.sol";
import "./SpoolAccessControllable.sol";

/// @notice Used when manual yield is more than allowed.
error ManualYieldTooBig(int256 manualYield);

/// @notice Used when manual yield is less than allowed.
error ManualYieldTooSmall(int256 manualYield);

abstract contract StrategyManualYieldVerifier is SpoolAccessControllable {
    /// @notice Positive manual yield limit.
    int128 public positiveLimit;

    /// @notice Negative manual yield limit.
    int128 public negativeLimit;

    /**
     * @notice Sets positive yield limit.
     * @param positiveLimit_ New positive yield limit.
     */
    function setPositiveYieldLimit(int128 positiveLimit_) external onlyRole(ROLE_SPOOL_ADMIN, msg.sender) {
        _setPositiveYieldLimit(positiveLimit_);
    }

    /**
     * @notice Sets negative yield limit.
     * @param negativeLimit_ New negative yield limit.
     */
    function setNegativeYieldLimit(int128 negativeLimit_) external onlyRole(ROLE_SPOOL_ADMIN, msg.sender) {
        _setNegativeYieldLimit(negativeLimit_);
    }

    function _setPositiveYieldLimit(int128 positiveLimit_) internal {
        if (positiveLimit_ < 0) revert InvalidConfiguration();
        positiveLimit = positiveLimit_;
    }

    function _setNegativeYieldLimit(int128 negativeLimit_) internal {
        if (negativeLimit_ > 0 || negativeLimit_ < -YIELD_FULL_PERCENT_INT) revert InvalidConfiguration();
        negativeLimit = negativeLimit_;
    }

    /**
     * @notice Verify manual yield is inside set parameters.
     * @param manualYield Manual yiedl value to verify.
     */
    function _verifyManualYieldPercentage(int256 manualYield) internal view virtual {
        if (manualYield > positiveLimit) {
            revert ManualYieldTooBig(manualYield);
        } else if (manualYield < negativeLimit) {
            revert ManualYieldTooSmall(manualYield);
        }
    }
}
