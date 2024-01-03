// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Math.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./TwoStageOwnable.sol";

contract IntervalEscrow is TwoStageOwnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct NominatedStrategy {
        bool nominated;
        uint256 applicableAt;
        uint256 firstIntervalPerBlockReleaseAmount;
        uint256[] intervals;
    }

    struct Strategy {
        uint256 currentIntervalIndex;
        uint256 currentIntervalStartedAt;
        uint256 lastReleasedAt;
        uint256 perBlockReleaseAmount;
        uint256[] intervals;
    }

    function getBlockNumber() internal virtual view returns (uint256) {
        return block.number;
    }

    function getTimestamp() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    uint256 public exitApplicableAt = 0;
    uint256 public exitTimeout;
    uint256 public strategyChangeTimeout;
    NominatedStrategy public nominatedStrategy;
    Strategy public currentStrategy;

    uint256 private _pool = 0;
    uint256 private _released = 0;
    IERC20 private _token;

    function pool() public view returns (uint256) {
        return _pool;
    }

    function released() public view returns (uint256) {
        return _released;
    }

    function token() public view returns (IERC20) {
        return _token;
    }

    function calculateUpdates(uint256 limit)
        public
        view
        returns (Strategy memory updatedStrategy, uint256 releasedAmount)
    {
        uint256 currentBlockNumber = getBlockNumber();
        updatedStrategy = currentStrategy;
        uint256 intervalsCount = updatedStrategy.intervals.length;
        while (limit > 0 && updatedStrategy.lastReleasedAt < currentBlockNumber) {
            uint256 releaseBlockNumber;
            uint256 perBlockReleaseAmount = updatedStrategy.perBlockReleaseAmount;
            if (updatedStrategy.currentIntervalIndex >= intervalsCount) releaseBlockNumber = currentBlockNumber;
            else {
                uint256 currentIntervalLength = updatedStrategy.intervals[updatedStrategy.currentIntervalIndex];
                uint256 currentIntervalStartedAt = updatedStrategy.currentIntervalStartedAt;
                uint256 currentIntervalEndsAt = currentIntervalStartedAt.add(currentIntervalLength);
                if (currentBlockNumber >= currentIntervalEndsAt) {
                    releaseBlockNumber = currentIntervalEndsAt;
                    updatedStrategy.currentIntervalIndex = updatedStrategy.currentIntervalIndex.add(1);
                    updatedStrategy.currentIntervalStartedAt = currentIntervalEndsAt;
                    updatedStrategy.perBlockReleaseAmount /= 2;
                } else releaseBlockNumber = currentBlockNumber;
            }
            uint256 blockDiff = releaseBlockNumber.sub(updatedStrategy.lastReleasedAt);
            uint256 intervalReleasedAmount = blockDiff.mul(perBlockReleaseAmount);
            releasedAmount = releasedAmount.add(intervalReleasedAmount);
            updatedStrategy.lastReleasedAt = releaseBlockNumber;
            limit -= 1;
        }
        releasedAmount = Math.min(releasedAmount, _pool);
    }

    function getReleasableAmountWithLimit(uint256 limit) public view returns (uint256) {
        (, uint256 result) = calculateUpdates(limit);
        return result;
    }

    function getReleasableAmount() public view returns (uint256) {
        return getReleasableAmountWithLimit(uint256(-1));
    }

    event Claimed(uint256 amount);
    event ExitInitialized(uint256 applicableAt);
    event Exited(uint256 amount);
    event PoolIncreased(address indexed payer, uint256 amount);
    event Released(uint256 amount);
    event StrategyNominated(uint256 firstIntervalPerBlockReleaseAmount, uint256[] intervals, uint256 applicableAt);
    event StrategyUpdated(uint256 firstIntervalPerBlockReleaseAmount, uint256[] intervals);

    constructor(
        uint256 exitTimeout_,
        uint256 firstIntervalPerBlockReleaseAmount,
        uint256 strategyChangeTimeout_,
        address owner_,
        uint256[] memory intervals,
        IERC20 token_
    ) public TwoStageOwnable(owner_) {
        exitTimeout = exitTimeout_;
        strategyChangeTimeout = strategyChangeTimeout_;
        _token = token_;
        _setup(firstIntervalPerBlockReleaseAmount, intervals);
    }

    function releaseWithLimit(uint256 limit) public returns (bool success, uint256 releasedAmount) {
        (currentStrategy, releasedAmount) = calculateUpdates(limit);
        _pool = _pool.sub(releasedAmount);
        _released = _released.add(releasedAmount);
        emit Released(releasedAmount);
        success = true;
    }

    function release() public returns (bool success, uint256 _releasedAmount) {
        return releaseWithLimit(uint256(-1));
    }

    function applyExit() public onlyOwner returns (bool success) {
        require(exitApplicableAt > 0, "Exit not initialized");
        require(getTimestamp() >= exitApplicableAt, "Exit timeout not passed");
        exitApplicableAt = 0;
        _released = _released.add(_pool);
        _pool = 0;
        emit Exited(_released);
        _claim(_released);
        return true;
    }

    function applyNominatedStrategy() public onlyOwner returns (bool success) {
        require(nominatedStrategy.nominated, "No nominated strategy");
        require(getTimestamp() >= nominatedStrategy.applicableAt, "Nominating timeout not passed");
        release();
        _setup(nominatedStrategy.firstIntervalPerBlockReleaseAmount, nominatedStrategy.intervals);
        nominatedStrategy.nominated = false;
        return true;
    }

    function exit() public onlyOwner returns (bool success) {
        require(exitApplicableAt == 0, "Exit initilized");
        exitApplicableAt = getTimestamp().add(exitTimeout);
        emit ExitInitialized(exitApplicableAt);
        return true;
    }

    function increasePool(uint256 amount) external returns (bool success) {
        release();
        _increasePool(msg.sender, amount);
        return true;
    }

    function nominateNewStrategy(uint256 firstIntervalPerBlockReleaseAmount, uint256[] memory intervals)
        external
        onlyOwner
        returns (uint256 applicableAt)
    {
        applicableAt = getTimestamp().add(strategyChangeTimeout);
        nominatedStrategy = NominatedStrategy({
            nominated: true,
            applicableAt: applicableAt,
            firstIntervalPerBlockReleaseAmount: firstIntervalPerBlockReleaseAmount,
            intervals: intervals
        });
        emit StrategyNominated(firstIntervalPerBlockReleaseAmount, intervals, applicableAt);
    }

    function claim(uint256 amount) external onlyOwner returns (bool success) {
        release();
        _claim(amount);
        return true;
    }

    function claimAll() external onlyOwner returns (bool success) {
        release();
        _claim(_released);
        return true;
    }

    function _claim(uint256 amount) internal {
        require(_released >= amount, "No enough released tokens");
        _released -= amount;
        emit Claimed(amount);
        _token.safeTransfer(owner, amount);
    }

    function _increasePool(address payer, uint256 amount) internal {
        _pool = _pool.add(amount);
        emit PoolIncreased(payer, amount);
        _token.safeTransferFrom(payer, address(this), amount);
    }

    function _setup(uint256 firstIntervalPerBlockReleaseAmount, uint256[] memory intervals) internal {
        uint256 currentBlockNumber = getBlockNumber();
        currentStrategy = Strategy({
            currentIntervalIndex: 0,
            currentIntervalStartedAt: currentBlockNumber,
            lastReleasedAt: currentBlockNumber,
            perBlockReleaseAmount: firstIntervalPerBlockReleaseAmount,
            intervals: intervals
        });
        emit StrategyUpdated(firstIntervalPerBlockReleaseAmount, intervals);
    }
}
