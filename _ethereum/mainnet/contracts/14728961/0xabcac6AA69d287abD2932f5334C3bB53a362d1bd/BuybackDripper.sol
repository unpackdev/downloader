// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "./AccessControl.sol";
import "./Math.sol";
import "./Buyback.sol";

/// @title Buyback drip Contract
/// @notice Distributes a token to a buyback at a fixed rate.
/// @dev This contract must be poked via the `drip()` function every so often.
/// @author Minterest
contract BuybackDripper is AccessControl {
    /// @dev Value is the Keccak-256 hash of "TIMELOCK"
    bytes32 public constant TIMELOCK = bytes32(0xaefebe170cbaff0af052a32795af0e1b8afff9850f946ad2869be14f35534371);

    uint256 private constant RATE_SCALE = 1e18;

    /// @notice Buyback to receive dripped tokens
    Buyback public immutable buyback;

    /// @notice Duration in hours that will be used at next period start
    /// @dev 168 is the average amount of hours in a week
    uint256 public nextPeriodDuration = 168;

    /// @notice Drip rate that will be used at next period start
    uint256 public nextPeriodRate = 1e18;

    /// @notice Timestamp in hours of current period start
    uint256 public periodStart;

    /// @notice Duration in hours of current period
    uint256 public periodDuration;

    /// @notice Tokens that should go to buyback per hour during current period
    uint256 public dripPerHour;

    /// @notice Timestamp in hours when last drip to buyback occurred
    uint256 public previousDripTime;

    event PeriodDurationChanged(uint256 duration);
    event PeriodRateChanged(uint256 rate);
    event NewPeriod(uint256 start, uint256 duration, uint256 dripPerHour);

    /// @notice Constructs a BuybackDripper
    /// @param buyback_ The target Buyback contract
    /// @param admin_ The address of DEFAULT_ADMIN_ROLE and TIMELOCK
    constructor(Buyback buyback_, address admin_) {
        buyback = buyback_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(TIMELOCK, admin_);
        require(buyback_.mnt().approve(address(buyback_), type(uint256).max), ErrorCodes.MNT_APPROVE_FAILS);
    }

    /// @notice Sets duration for the next period
    /// @param duration in hours
    function setPeriodDuration(uint256 duration) external onlyRole(TIMELOCK) {
        require(duration > 0, ErrorCodes.INVALID_DURATION);
        nextPeriodDuration = duration;
        emit PeriodDurationChanged(duration);
    }

    /// @notice Sets rate for the next period
    /// @param rate percents scaled with precision of 1e18. Should be in range (0; 1].
    function setPeriodRate(uint256 rate) external onlyRole(TIMELOCK) {
        require(rate > 0 && rate <= 1e18, ErrorCodes.INVALID_PERIOD_RATE);
        nextPeriodRate = rate;
        emit PeriodRateChanged(rate);
    }

    /// @notice Drips tokens to buyback with defined drip rate. Cannot be called more than once per hour.
    function drip() external {
        uint256 timeUnits = getTime();
        uint256 timeSinceDrip = timeUnits - previousDripTime;
        require(timeSinceDrip > 0, ErrorCodes.TOO_EARLY_TO_DRIP);

        // Reset period if last drip was older than period duration
        if (timeSinceDrip >= periodDuration) {
            previousDripTime = timeUnits;
            resetPeriod(timeUnits);
            return;
        }

        uint256 nextPeriodStart = periodStart + periodDuration;

        uint256 dripUntil = Math.min(timeUnits, nextPeriodStart);
        uint256 dripDuration = dripUntil - previousDripTime;
        uint256 toDrip = dripDuration * dripPerHour;
        previousDripTime = dripUntil;

        if (dripUntil >= nextPeriodStart) {
            resetPeriod(nextPeriodStart);
        }

        buyback.buyback(toDrip);
    }

    /// @dev Starts new Period with pending parameters
    /// @param newStart timestamp of new period start
    function resetPeriod(uint256 newStart) private {
        uint256 selfBalance = buyback.mnt().balanceOf(address(this));
        uint256 newDripPerHour = (selfBalance * nextPeriodRate) / RATE_SCALE / nextPeriodDuration;
        periodStart = newStart;
        periodDuration = nextPeriodDuration;
        dripPerHour = newDripPerHour;
        emit NewPeriod(newStart, nextPeriodDuration, newDripPerHour);
    }

    /// @return timestamp truncated to hours
    function getTime() private view returns (uint256) {
        //solhint-disable-next-line not-rely-on-time
        return block.timestamp / 1 hours;
    }
}
