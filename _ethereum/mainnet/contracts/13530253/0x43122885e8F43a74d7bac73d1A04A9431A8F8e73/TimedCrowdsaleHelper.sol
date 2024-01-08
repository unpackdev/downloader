// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;
pragma abicoder v2; // solhint-disable-line

import "./SafeMath.sol";

/**
 * @title TimedCrowdsaleHelper
 * @author Enjinstarter
 * @dev Helper for crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsaleHelper {
    using SafeMath for uint256;

    struct Timeframe {
        uint256 openingTime;
        uint256 closingTime;
    }

    Timeframe private _timeframe;

    /**
     * Event for crowdsale extending
     * @param prevClosingTime old closing time
     * @param newClosingTime new closing time
     */
    event TimedCrowdsaleExtended(
        uint256 prevClosingTime,
        uint256 newClosingTime
    );

    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen() {
        require(isOpen(), "TimedCrowdsaleHelper: not open");
        _;
    }

    /**
     * @dev Constructor, takes crowdsale opening and closing times.
     * @param timeframe Crowdsale opening and closing times
     */
    constructor(Timeframe memory timeframe) {
        require(
            timeframe.openingTime >= block.timestamp,
            "TimedCrowdsaleHelper: opening time is before current time"
        );
        require(
            timeframe.closingTime > timeframe.openingTime,
            "TimedCrowdsaleHelper: closing time is before opening time"
        );

        _timeframe.openingTime = timeframe.openingTime;
        _timeframe.closingTime = timeframe.closingTime;
    }

    /**
     * @return the crowdsale opening time.
     */
    function openingTime() external view returns (uint256) {
        return _timeframe.openingTime;
    }

    /**
     * @return the crowdsale closing time.
     */
    function closingTime() public view returns (uint256) {
        return _timeframe.closingTime;
    }

    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        return
            block.timestamp >= _timeframe.openingTime &&
            block.timestamp <= _timeframe.closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        return block.timestamp > _timeframe.closingTime;
    }

    /**
     * @dev Extend crowdsale.
     * @param newClosingTime Crowdsale closing time
     */
    // https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
    // slither-disable-next-line dead-code
    function _extendTime(uint256 newClosingTime) internal {
        require(!hasClosed(), "TimedCrowdsaleHelper: already closed");
        uint256 oldClosingTime = _timeframe.closingTime;
        require(
            newClosingTime > oldClosingTime,
            "TimedCrowdsaleHelper: before current closing time"
        );

        _timeframe.closingTime = newClosingTime;

        emit TimedCrowdsaleExtended(oldClosingTime, newClosingTime);
    }
}
