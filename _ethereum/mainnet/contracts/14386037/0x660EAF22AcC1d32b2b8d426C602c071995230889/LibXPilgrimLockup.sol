// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./LibAppStorage.sol";
import "./LibDiamond.sol";

/// @title  XPILLockup
///
/// @author rn.ermaid
///
/// @notice A contract that queues lock-ups.
///
library LibXPilgrimLockup {

    function isEmpty(address _holder) internal view returns (bool) {
        XPILLockupPositionQueue storage queue = LibAppStorage._diamondStorage().queues[_holder];
        if (queue.head == 0) return true;
        return queue.head > queue.tail;
    }

    function size(address _holder) internal view returns (uint128) {
        XPILLockupPositionQueue storage queue = LibAppStorage._diamondStorage().queues[_holder];
        return isEmpty(_holder) ? 0 : queue.tail - queue.head + 1;
    }

    function enqueue(address _holder, uint128 _amount) internal returns (uint64 _expiry) {
        XPILLockupPositionQueue storage queue = LibAppStorage._diamondStorage().queues[_holder];

        XPILLockupPosition memory position;
        position.amount = _amount;
        position.expiryDateTimestamp = uint64(block.timestamp) + LibAppStorage._diamondStorage().lockupPeriod;

        if (queue.head == 0) {
            queue.head = 1;
            queue.tail = 1;
            queue.positions[1] = position;
        } else {
            queue.positions[++queue.tail] = position;
        }

        return position.expiryDateTimestamp;
    }

    function dequeue(address _holder) internal {
        require(!isEmpty(_holder), "Pilgrim: EMPTY_QUEUE");
        XPILLockupPositionQueue storage queue = LibAppStorage._diamondStorage().queues[_holder];
        delete queue.positions[queue.head++];
    }

    function peek(address _holder) internal view returns (uint128 _amount, uint64 _expiryDateTimestamp) {
        require(!isEmpty(_holder), "Pilgrim: EMPTY_QUEUE");
        XPILLockupPositionQueue storage queue = LibAppStorage._diamondStorage().queues[_holder];
        (_amount, _expiryDateTimestamp) = (queue.positions[queue.head].amount, queue.positions[queue.head].expiryDateTimestamp);
    }

    function get(address _holder, uint128 _index) internal view returns (uint128 _amount, uint64 _expiryDateTimestamp) {
        require(_index < size(_holder), "Pilgrim: OUT_OF_BOUND");
        XPILLockupPositionQueue storage queue = LibAppStorage._diamondStorage().queues[_holder];
        (_amount, _expiryDateTimestamp) = (queue.positions[queue.head + _index].amount, queue.positions[queue.head + _index].expiryDateTimestamp);
    }

    /// @notice This method can be used to get current claimable xPIL shares for each holder
    ///
    /// @return _unlockedAmount Unlocked & non-claimed xPIL shares
    ///
    function getUnlockedAmount(address _holder) internal view returns (uint128 _unlockedAmount) {
        XPILLockupPositionQueue storage queue = LibAppStorage._diamondStorage().queues[_holder];
        _unlockedAmount = 0;
        for (uint128 i = queue.head; i <= queue.tail; i++) {
            if (queue.positions[i].expiryDateTimestamp <= block.timestamp) {
                _unlockedAmount += queue.positions[i].amount;
            }
        }
    }

    /// @notice This method can be used to get extra claimable xPIL shares in the future
    ///
    /// @return _lockedAmount   Locked xPIL shares
    ///
    function getLockedAmount(address _holder) internal view returns (uint128 _lockedAmount) {
        XPILLockupPositionQueue storage queue = LibAppStorage._diamondStorage().queues[_holder];
        _lockedAmount = 0;
        for (uint128 i = queue.head; i <= queue.tail; i++) {
            if (queue.positions[i].expiryDateTimestamp <= block.timestamp) {
                continue;
            }
            _lockedAmount += queue.positions[i].amount;
        }
    }

    /// @notice Forcibly reduces unlocked amount of xPIL by deleting lockup position item or reducing lockup position amounts
    ///
    /// @dev    This method must be called whenever xPIL holders claim their PIL and burn their xPILs.
    ///         Fails if given amount is bigger than holder's current unlocked amount
    ///
    /// @param  amount  xPIL Amount to reduce holder's unlocked xPIL share
    ///
    function reduceUnlockedAmount(address _holder, uint128 amount) internal {
        XPILLockupPositionQueue storage queue = LibAppStorage._diamondStorage().queues[_holder];

        uint128 _remainingAmount = amount;
        for (uint128 i = queue.head; i <= queue.tail; i++) {
            // Holder's current unlocked amount is less than input amount
            // If holder's current unlocked amount is big enough, for loop should've been escaped earlier
            require(queue.positions[i].expiryDateTimestamp <= block.timestamp);
            if (queue.positions[i].amount > _remainingAmount) {
                queue.positions[i].amount -= _remainingAmount;
                _remainingAmount = 0;
            } else {
                _remainingAmount -= queue.positions[i].amount;
                delete queue.positions[i];
                queue.head++;
            }

            if (_remainingAmount == 0) {
                break;
            }
        }
        // Holder's current unlocked amount is less than input amount
        // Cleared all positions but reduced amount is less then given amount
        require(_remainingAmount == 0);
    }
}
