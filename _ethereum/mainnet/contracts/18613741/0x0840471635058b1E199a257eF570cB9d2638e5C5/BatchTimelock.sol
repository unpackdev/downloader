// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./EnumerableSet.sol";
import "./AccessControl.sol";
import "./IERC20.sol";

import "./TimelockRoles.sol";
import "./ITerminateable.sol";
import "./IBatchTimelock.sol";
import "./IVestingPool.sol";

contract BatchTimelock is ITerminateable, IBatchTimelock, IVestingPool, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice Token that will be vested (IQT).
     * @dev Link to IQT repository: https://github.com/iqlabsorg/iqt-eth
     */
    IERC20 internal _token;

    /**
     * @notice Address of the vesting pool.
     */
    address internal _vestingPool;

    /**
     * @notice Array of all receiver addresses.
     */
    EnumerableSet.AddressSet internal _allReceivers;

    /**
     * @notice Mapping of all timelocks.
     */
    mapping(address => Timelock) internal _timelocks;

    /**
     * @notice Checks if the timelock exists
     */
    modifier onlyReceiver() {
        if (_timelocks[_msgSender()].receiver != _msgSender()) {
            revert InvalidReceiverAddress();
        }
        _;
    }

    modifier onlyTimelockCreator() {
        if (!hasRole(TimelockRoles.TIMELOCK_CREATOR_ROLE, _msgSender()) && !hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert CallerIsNotATimelockCreator();
        }
        _;
    }

    modifier onlyTerminationAdmin() {
        if (!hasRole(TimelockRoles.TERMINATION_ADMIN_ROLE, _msgSender()) && !hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert CallerIsNotATerminationAdmin();
        }
        _;
    }

    /**
     * @notice Reverts if the timelock does not exist.
    */
    constructor(IERC20 token, address vestingPool) {
        _token = token;
        _vestingPool = vestingPool;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(TimelockRoles.TERMINATION_ADMIN_ROLE, _msgSender());
        _setupRole(TimelockRoles.TIMELOCK_CREATOR_ROLE, _msgSender());
    }

    /**
     * @inheritdoc ITerminateable
     */
    function terminate(address receiver, uint256 terminationFrom) external onlyTerminationAdmin {
        Timelock storage lock = _timelocks[receiver];

        if (lock.timelockFrom >= terminationFrom) {
            revert TerminationTimeMustBeAfterLockStart(terminationFrom, lock.timelockFrom);
        }

        lock.terminationFrom = terminationFrom;
        lock.isTerminated = true;

        emit TimelockTerminated(receiver, terminationFrom);
    }

    /**
     * @inheritdoc ITerminateable
     */
    function determinate(address receiver) external onlyTerminationAdmin {
        Timelock storage lock = _timelocks[receiver];
        lock.isTerminated = false;
        lock.terminationFrom = 0;

        emit TimelockDeterminated(receiver);
    }

    /**
     * @inheritdoc IBatchTimelock
    */
    function addTimelockBatch(Receiver[] memory receivers) external onlyTimelockCreator {
        if (receivers.length == 0) {
            revert EmptyReceiversArray();
        }

        uint256 receiversCount = receivers.length; // Caching the array length outside a loop
        unchecked {
            for (uint256 i = 0; i < receiversCount; ++i) {
                _addTimelock(
                    receivers[i].receiver,
                    receivers[i].totalAmount,
                    receivers[i].timelockFrom,
                    receivers[i].cliffDuration,
                    receivers[i].vestingDuration
                );
            }
        }
    }

    /**
     * @inheritdoc IBatchTimelock
    */
    function addTimelock(
        address receiver,
        uint256 totalAmount,
        uint256 timelockFrom,
        uint256 cliffDuration,
        uint256 vestingDuration
    ) external onlyTimelockCreator {
        _addTimelock(receiver, totalAmount, timelockFrom, cliffDuration, vestingDuration);
    }

    /**
     * @inheritdoc IBatchTimelock
     */
    function claim(uint256 amount) external onlyReceiver {
        if (amount == 0) {
            revert ZeroClaimAmount();
        }

        Timelock storage lock = _timelocks[_msgSender()];
        uint256 blockTimestamp = block.timestamp;

        if (blockTimestamp < lock.timelockFrom + lock.cliffDuration) {
            revert CliffPeriodNotEnded(blockTimestamp, lock.timelockFrom + lock.cliffDuration);
        }

        uint256 withdrawable = getClaimableBalance(_msgSender());

        if (amount > withdrawable) {
            revert AmountExceedsWithdrawableAllowance(amount, withdrawable);
        }

        lock.releasedAmount += amount;

        bool transferSuccess = _token.transferFrom(_vestingPool, _msgSender(), amount);

        if (!transferSuccess) revert TokenTransferFailed(_vestingPool, _msgSender(), amount);

        emit TokensClaimed(_msgSender(), amount);
    }

    /**
     * @inheritdoc IBatchTimelock
     */
    function setVestingPool(address vestingPool) external onlyTimelockCreator {
        _vestingPool = vestingPool;
    }

    /**
     * @inheritdoc IBatchTimelock
     */
    function getClaimableBalance(address receiver) public view returns (uint256) {
        Timelock storage lock = _timelocks[receiver];
        uint256 lockFromPlusCliff = lock.timelockFrom + lock.cliffDuration;
        uint256 blockTimestampNow = block.timestamp;

        if (blockTimestampNow < lockFromPlusCliff) {
            return 0;
        }

        uint256 vestedTime;
        if (lock.isTerminated) {
            uint256 effectiveTerminationTime = lock.terminationFrom < blockTimestampNow ? lock.terminationFrom : blockTimestampNow;
            vestedTime = effectiveTerminationTime > lockFromPlusCliff
                ? effectiveTerminationTime - lockFromPlusCliff
                : 0;
        } else {
            uint256 vestingEnd = lockFromPlusCliff + lock.vestingDuration;
            vestedTime = blockTimestampNow < vestingEnd
                ? blockTimestampNow - lockFromPlusCliff
                : lock.vestingDuration;
        }
        uint256 vestedPortion = (lock.totalAmount * vestedTime) / lock.vestingDuration;

        return vestedPortion > lock.releasedAmount
            ? vestedPortion - lock.releasedAmount
            : 0;
    }

    /**
     * @inheritdoc IBatchTimelock
    */
    function getTimelock(address receiver) public view returns (Timelock memory) {
        return _timelocks[receiver];
    }

    /**
     * @inheritdoc IBatchTimelock
    */
    function getTimelockReceivers(uint256 offset, uint256 limit) external view returns (address[] memory) {
        uint256 receiverCount = _allReceivers.length();
        if (offset >= receiverCount) {
            return new address[](0);
        }

        if (offset + limit > receiverCount) {
            limit = receiverCount - offset;
        }

        address[] memory receivers = new address[](limit);
        unchecked {
            for (uint256 i = 0; i < limit; ++i) {
                receivers[i] = _allReceivers.at(offset + i);
            }
        }
        return receivers;
    }

    /**
     * @inheritdoc IBatchTimelock
    */
    function getTimelockReceiversAmount() external view returns (uint256) {
        return _allReceivers.length();
   }

    /**
     * @inheritdoc IVestingPool
     */
    function getCurrentAllowance() public view returns (uint256) {
        return _token.allowance(_vestingPool, address(this));
    }

    /**
     * @inheritdoc IVestingPool
     */
    function getTotalTokensLocked() public view returns (uint256) {
        uint256 total = 0;
        uint256 receiverCount = _allReceivers.length(); // Caching the array length outside a loop
        unchecked {
            for (uint256 i = 0; i < receiverCount; ++i) {
                total += _timelocks[_allReceivers.at(i)].totalAmount;
            }
        }
        return total;
    }

    /**
     * @inheritdoc IVestingPool
     */
    function getVestingPoolAddress() public view returns (address) {
        return _vestingPool;
    }

    /**
     * @inheritdoc IVestingPool
     */
    function getTokenAddress() public view returns (address) {
        return address(_token);
    }

    /**
     * @notice Creates new timelock for the receiver.
     * @param receiver Address of the receiver.
     * @param totalAmount Total amount of tokens to be vested.
     * @param timelockFrom Timestamp from which the timelock will start.
     * @param cliffDuration Cliff time in seconds (6 months default).
     * @param vestingDuration Vesting duration in seconds (18/24 months).
    */
    function _addTimelock(address receiver, uint256 totalAmount, uint256 timelockFrom, uint256 cliffDuration, uint256 vestingDuration) internal onlyTimelockCreator {
        if (receiver == address(0)) revert InvalidReceiverAddress();
        if (totalAmount == 0) revert InvalidTimelockAmount();
        if (_allReceivers.contains(receiver)) revert ReceiverAlreadyHasATimelock(receiver);

        _timelocks[receiver] = Timelock({
            receiver: receiver,
            totalAmount: totalAmount,
            releasedAmount: 0,
            timelockFrom: timelockFrom,
            cliffDuration: cliffDuration,
            vestingDuration: vestingDuration,
            isTerminated: false,
            terminationFrom: 0
        });
        _allReceivers.add(receiver);

        emit TimelockCreated(receiver, totalAmount, timelockFrom, cliffDuration, vestingDuration);
    }
}