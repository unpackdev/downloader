// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;
pragma abicoder v2;

import "./ERC20.sol";
import "./SafeERC20.sol";

import "./PendleStakingBaseUpg.sol";
import "./IPVotingEscrowMainchain.sol";
import "./IPFeeDistributorV2.sol";
import "./IPVoteController.sol";

import "./IConvertor.sol";
import "./ERC20FactoryLib.sol";
import "./WeekMath.sol";

/// @title PendleStaking
/// @notice PendleStaking is the main contract that holds vePendle position on behalf on user to get boosted yield and vote.
///         PendleStaking is the main contract interacting with Pendle Finance side
/// @author Magpie Team

contract PendleStaking is PendleStakingBaseUpg {
    using SafeERC20 for IERC20;

    uint256 public lockPeriod;

    /* ============ Events ============ */
    event SetLockDays(uint256 _oldLockDays, uint256 _newLockDays);

    constructor() {_disableInitializers();}

    function __PendleStaking_init(
        address _pendle,
        address _WETH,
        address _vePendle,
        address _distributorETH,
        address _pendleRouter,
        address _masterPenpie
    ) public initializer {
        __PendleStakingBaseUpg_init(
            _pendle,
            _WETH,
            _vePendle,
            _distributorETH,
            _pendleRouter,
            _masterPenpie
        );
        lockPeriod = 720 * 86400;
    }

    /// @notice get the penpie claimable revenue share in ETH
    function totalUnclaimedETH() external view returns (uint256) {
        return distributorETH.getProtocolTotalAccrued(address(this));
    }

    /* ============ VePendle Related Functions ============ */

    function vote(
        address[] calldata _pools,
        uint64[] calldata _weights
    ) external override {
        if (msg.sender != voteManager) revert OnlyVoteManager();
        if (_pools.length != _weights.length) revert LengthMismatch();

        IPVoteController(pendleVote).vote(_pools, _weights);
    }

    function bootstrapVePendle(uint256[] calldata chainId) payable external onlyOwner returns( uint256 ) {
        uint256 amount = IERC20(PENDLE).balanceOf(address(this));
        IERC20(PENDLE).safeApprove(address(vePendle), amount);
        uint128 lockTime = _getIncreaseLockTime();
        return IPVotingEscrowMainchain(vePendle).increaseLockPositionAndBroadcast{value:msg.value}(uint128(amount), lockTime, chainId);
    }

    /// @notice convert PENDLE to mPendle
    /// @param _amount the number of Pendle to convert
    /// @dev the Pendle must already be in the contract
    function convertPendle(
        uint256 _amount,
        uint256[] calldata chainId
    ) public payable override whenNotPaused returns (uint256) {
        uint256 preVePendleAmount = accumulatedVePendle();
        if (_amount == 0) revert ZeroNotAllowed();

        IERC20(PENDLE).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(PENDLE).safeApprove(address(vePendle), _amount);

        uint128 unlockTime = _getIncreaseLockTime();
        IPVotingEscrowMainchain(vePendle).increaseLockPositionAndBroadcast{value:msg.value}(uint128(_amount), unlockTime, chainId);

        uint256 mintedVePendleAmount = accumulatedVePendle() -
            preVePendleAmount;
        emit PendleLocked(_amount, lockPeriod, mintedVePendleAmount);

        return mintedVePendleAmount;
    }

    function increaseLockTime(uint256 _unlockTime) external {
        uint128 unlockTime = WeekMath.getWeekStartTimestamp(
            uint128(block.timestamp + _unlockTime)
        );
        IPVotingEscrowMainchain(vePendle).increaseLockPosition(0, unlockTime);
    }

    function harvestVePendleReward(address[] calldata _pools) external {
        if (this.totalUnclaimedETH() == 0) {
            revert NoVePendleReward();
        }

        if (
            (protocolFee != 0 && feeCollector == address(0)) ||
            bribeManagerEOA == address(0)
        ) revert InvalidFeeDestination();

        (uint256 totalAmountOut, uint256[] memory amountsOut) = distributorETH
            .claimProtocol(address(this), _pools);
        // for protocol
        uint256 fee = (totalAmountOut * protocolFee) / DENOMINATOR;
        IERC20(WETH).safeTransfer(feeCollector, fee);

        // for caller
        uint256 callerFeeAmount = (totalAmountOut * vePendleHarvestCallerFee) /
            DENOMINATOR;
        IERC20(WETH).safeTransfer(msg.sender, callerFeeAmount);

        uint256 left = totalAmountOut - fee - callerFeeAmount;
        IERC20(WETH).safeTransfer(bribeManagerEOA, left);

        emit VePendleHarvested(
            totalAmountOut,
            _pools,
            amountsOut,
            fee,
            callerFeeAmount,
            left
        );
    }

    /* ============ Admin Functions ============ */

    function setLockDays(uint256 _newLockPeriod) external onlyOwner {
        uint256 oldLockPeriod = lockPeriod;
        lockPeriod = _newLockPeriod;

        emit SetLockDays(oldLockPeriod, lockPeriod);
    }

    function forceVote(
        address[] calldata _pools,
        uint64[] calldata _weights
    ) external onlyOwner {
        if (_pools.length != _weights.length) revert LengthMismatch();

        IPVoteController(pendleVote).vote(_pools, _weights);
    }    

    /* ============ Internal Functions ============ */

    function _getIncreaseLockTime() internal view returns (uint128) {
        return
            WeekMath.getWeekStartTimestamp(
                uint128(block.timestamp + lockPeriod)
            );
    }
}
