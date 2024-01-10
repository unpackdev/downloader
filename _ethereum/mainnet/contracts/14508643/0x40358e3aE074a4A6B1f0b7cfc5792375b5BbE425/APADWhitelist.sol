// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";

import "./IWhitelist.sol";
import "./TimeLockedStaking.sol";

contract APADWhitelist is IWhitelist, Ownable {
    using SafeMath for uint256;

    TimeLockedStaking public immutable s1;
    TimeLockedStaking public immutable s2;
    TimeLockedStaking public immutable s3;

    /// @notice Threshold balance
    uint256 public threshold;

    event ThresholdChanged(uint256 prevThreshold, uint256 nextThreshold);

    constructor(
        TimeLockedStaking _s1,
        TimeLockedStaking _s2,
        TimeLockedStaking _s3,
        uint256 _initialThreshold
    ) {
        s1 = _s1;
        s2 = _s2;
        s3 = _s3;
        threshold = _initialThreshold;
    }

    /// @notice Admin-only function to update the threshold balance
    /// @param _threshold New threshold
    function setThreshold(uint256 _threshold) external onlyOwner {
        emit ThresholdChanged(threshold, _threshold);
        threshold = _threshold;
    }

    function isWhitelisted(address user) override external view returns (bool) {
        uint256 totalBalance = s1.balanceOf(user).add(s2.balanceOf(user)).add(
            s3.balanceOf(user)
        );
        return totalBalance >= threshold;
    }
}
