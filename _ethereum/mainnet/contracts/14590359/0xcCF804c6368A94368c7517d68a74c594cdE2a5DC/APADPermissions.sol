// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";

import "./IPermissions.sol";
import "./TimeLockedStaking.sol";

contract APADPermissions is IPermissions, Ownable {
    using SafeMath for uint256;

    TimeLockedStaking public immutable s1;
    TimeLockedStaking public immutable s2;
    TimeLockedStaking public immutable s3;
    /// @notice Threshold balance to clear the whitelist.
    uint256 public whitelistThreshold;

    /// @notice Buy limit thresholds.
    uint256[3] public buyLimitThresholds;

    /// @notice Buy limits.
    uint256[3] public buyLimits;

    event WhitelistThresholdChanged(
        uint256 prevThreshold,
        uint256 nextThreshold
    );
    event BuyLimitThresholdsChanged(
        uint256[3] prevThresholds,
        uint256[3] nextThresholds
    );
    event BuyLimitsChanged(uint256[3] prevLimits, uint256[3] nextLimits);

    constructor(
        TimeLockedStaking[3] memory _stakings,
        uint256 _initialWhitelistThreshold,
        uint256[3] memory _initialBuyLimitThresholds,
        uint256[3] memory _initialBuyLimits
    ) {
        s1 = _stakings[0];
        s2 = _stakings[1];
        s3 = _stakings[2];
        whitelistThreshold = _initialWhitelistThreshold;
        setBuyLimitThresholds(_initialBuyLimitThresholds);
        setBuyLimits(_initialBuyLimits);
    }

    /// @notice Admin-only function to update the whitelistThreshold
    /// @param _whitelistThreshold New whitelistThreshold
    function setWhitelistThreshold(uint256 _whitelistThreshold)
        external
        onlyOwner
    {
        emit WhitelistThresholdChanged(whitelistThreshold, _whitelistThreshold);
        whitelistThreshold = _whitelistThreshold;
    }

    /// @notice Admin-only function to update the buyLimitThresholds
    /// @param _buyLimitThresholds New buyLimitThresholds
    function setBuyLimitThresholds(uint256[3] memory _buyLimitThresholds)
        public
        onlyOwner
    {
        require(
            _buyLimitThresholds[0] <= _buyLimitThresholds[1] &&
                _buyLimitThresholds[1] <= _buyLimitThresholds[2],
            "Buy limit threshold invariants failed"
        );
        emit BuyLimitThresholdsChanged(buyLimitThresholds, _buyLimitThresholds);
        buyLimitThresholds = _buyLimitThresholds;
    }

    /// @notice Admin-only function to update the buyLimits
    /// @param _buyLimits New buyLimits
    function setBuyLimits(uint256[3] memory _buyLimits) public onlyOwner {
        require(
            _buyLimits[0] <= _buyLimits[1] && _buyLimits[1] <= _buyLimits[2],
            "Buy limit invariants failed"
        );
        emit BuyLimitsChanged(buyLimits, _buyLimits);
        buyLimits = _buyLimits;
    }

    function userStakeBalance(address user) public view returns (uint256) {
        return
            s1.balanceOf(user).add(s2.balanceOf(user)).add(s3.balanceOf(user));
    }

    function isWhitelisted(address user) external view override returns (bool) {
        return userStakeBalance(user) >= whitelistThreshold;
    }

    function buyLimit(address user) external view override returns (uint256) {
        uint256 userBalance = userStakeBalance(user);
        if (userBalance >= buyLimitThresholds[2]) {
            return buyLimits[2];
        } else if (userBalance >= buyLimitThresholds[1]) {
            return buyLimits[1];
        } else if (userBalance >= buyLimitThresholds[0]) {
            return buyLimits[0];
        }
        return 0;
    }
}
