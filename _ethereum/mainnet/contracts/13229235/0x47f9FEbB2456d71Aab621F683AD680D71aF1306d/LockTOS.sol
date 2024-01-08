// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./AccessControl.sol";
import "./Math.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeCast.sol";
import "./SignedSafeMath.sol";

import "./ILockTOS.sol";
import "./ITOS.sol";
import "./LibLockTOS.sol";
import "./AccessibleCommon.sol";
import "./LockTOSStorage.sol";


contract LockTOS is LockTOSStorage, AccessibleCommon, ILockTOS {
    using SafeMath for uint256;
    using SafeCast for uint256;
    using SignedSafeMath for int256;

    event LockCreated(
        address account,
        uint256 lockId,
        uint256 value,
        uint256 unlockTime
    );
    event LockAmountIncreased(address account, uint256 lockId, uint256 value);
    event LockUnlockTimeIncreased(
        address account,
        uint256 lockId,
        uint256 unlockTime
    );
    event LockDeposited(address account, uint256 lockId, uint256 value);
    event LockWithdrawn(address account, uint256 lockId, uint256 value);

    /// @dev Check if a function is used or not
    modifier ifFree {
        require(free == 1, "LockId is already in use");
        free = 0;
        _;
        free = 1;
    }

    /// @inheritdoc ILockTOS
    function needCheckpoint() external override view returns (bool need) {
        uint256 len = pointHistory.length;
        if (len == 0) {
            return true;
        }
        need = (block.timestamp - pointHistory[len - 1].timestamp) > epochUnit; // if the last record was within a week
    }

    /// @inheritdoc ILockTOS
    function setMaxTime(uint256 _maxTime) external override onlyOwner {
        maxTime = _maxTime;
    }

    /// @inheritdoc ILockTOS
    function increaseAmount(uint256 _lockId, uint256 _value) external override {
        depositFor(msg.sender, _lockId, _value);
    }

    /// @inheritdoc ILockTOS
    function allHolders() external override view returns (address[] memory) {
        return uniqueUsers;
    }

    /// @inheritdoc ILockTOS
    function activeHolders() external override view returns (address[] memory) {
        bool[] memory activeCheck = new bool[](uniqueUsers.length);
        uint256 activeSize = 0;        
        for (uint256 i = 0; i < uniqueUsers.length; ++i) {
            uint256[] memory activeLocks = activeLocksOf(uniqueUsers[i]);
            if (activeLocks.length > 0) {
                activeSize++;
                activeCheck[i] = true;
            }
        }

        address[] memory activeUsers = new address[](activeSize);
        uint256 j = 0;
        for (uint256 i = 0; i < uniqueUsers.length; ++i) {
            if (activeCheck[i]) {
                activeUsers[j++] = uniqueUsers[i];
            }
        }
        return activeUsers;
    }

    /// @inheritdoc ILockTOS
    function createLockWithPermit(
        uint256 _value,
        uint256 _unlockWeeks,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override returns (uint256 lockId) {
        ITOS(tos).permit(
            msg.sender,
            address(this),
            _value,
            _deadline,
            _v,
            _r,
            _s
        );
        lockId = createLock(_value, _unlockWeeks);
    }

    /// @inheritdoc ILockTOS
    function increaseUnlockTime(uint256 _lockId, uint256 _unlockWeeks)
        external
        override
    {
        require(_unlockWeeks > 0, "Unlock period less than a week");
        cumulativeEpochUnit = cumulativeEpochUnit.add(_unlockWeeks);

        LibLockTOS.LockedBalance memory lock =
            lockedBalances[msg.sender][_lockId];
        uint256 unlockTime = lock.end.add(_unlockWeeks.mul(epochUnit));
        unlockTime = unlockTime.div(epochUnit).mul(epochUnit);
        require(
            unlockTime - block.timestamp < maxTime,
            "Max unlock time is 3 years"
        );
        require(lock.end > block.timestamp, "Lock time already finished");
        require(lock.end < unlockTime, "New lock time must be greater");
        require(lock.amount > 0, "No existing locked TOS");
        _deposit(msg.sender, _lockId, 0, unlockTime);

        emit LockUnlockTimeIncreased(msg.sender, _lockId, unlockTime);
    }

    /// @inheritdoc ILockTOS
    function withdrawAll() external override ifFree {
        uint256[] storage locks = userLocks[msg.sender];
        if (locks.length == 0) {
            return;
        }

        for (uint256 i = 0; i < locks.length; i++) {
            LibLockTOS.LockedBalance memory lock = allLocks[locks[i]];
            if (
                lock.withdrawn == false &&
                locks[i] > 0 &&
                lock.amount > 0 &&
                lock.start > 0 &&
                lock.end > 0 &&
                lock.end < block.timestamp
            ) {
                _withdraw(locks[i]);
            }
        }
    }

    /// @inheritdoc ILockTOS
    function globalCheckpoint() external override {
        _recordHistoryPoints();
    }

    /// @inheritdoc ILockTOS
    function withdraw(uint256 _lockId) public override ifFree {
        require(_lockId > 0, "_lockId is zero");
        _withdraw(_lockId);
    }

    /// @dev Send staked amount back to user
    function _withdraw(uint256 _lockId) internal {
        LibLockTOS.LockedBalance memory lockedOld =
            lockedBalances[msg.sender][_lockId];
        require(lockedOld.withdrawn == false, "Already withdrawn");
        require(lockedOld.start > 0, "Lock does not exist");
        require(lockedOld.end < block.timestamp, "Lock time not finished");
        require(lockedOld.amount > 0, "No amount to withdraw");

        LibLockTOS.LockedBalance memory lockedNew =
            LibLockTOS.LockedBalance({
                amount: 0,
                start: 0,
                end: 0,
                withdrawn: true
            });

        // Checkpoint
        _checkpoint(lockedNew, lockedOld);

        // Transfer TOS back
        uint256 amount = lockedOld.amount;
        lockedBalances[msg.sender][_lockId] = lockedNew;
        allLocks[_lockId] = lockedNew;

        IERC20(tos).transfer(msg.sender, amount);
        emit LockWithdrawn(msg.sender, _lockId, amount);
    }

    /// @inheritdoc ILockTOS
    function createLock(uint256 _value, uint256 _unlockWeeks)
        public
        override
        returns (uint256 lockId)
    {
        require(_value > 0, "Value locked should be non-zero");
        require(_unlockWeeks > 0, "Unlock period less than a week");

        cumulativeEpochUnit = cumulativeEpochUnit.add(_unlockWeeks);
        cumulativeTOSAmount = cumulativeTOSAmount.add(_value);
        uint256 unlockTime = block.timestamp.add(_unlockWeeks.mul(epochUnit));
        unlockTime = unlockTime.div(epochUnit).mul(epochUnit);
        require(
            unlockTime - block.timestamp <= maxTime,
            "Max unlock time is 3 years"
        );

        if (userLocks[msg.sender].length == 0) { // check if user for the first time
            uniqueUsers.push(msg.sender);
        }

        lockIdCounter = lockIdCounter.add(1);
        lockId = lockIdCounter;

        _deposit(msg.sender, lockId, _value, unlockTime);
        userLocks[msg.sender].push(lockId);

        emit LockCreated(msg.sender, lockId, _value, unlockTime);
    }

    /// @inheritdoc ILockTOS
    function depositFor(
        address _addr,
        uint256 _lockId,
        uint256 _value
    ) public override {
        require(_value > 0, "Value locked should be non-zero");
        LibLockTOS.LockedBalance memory lock = lockedBalances[_addr][_lockId];
        require(lock.withdrawn == false, "Lock is withdrawn");
        require(lock.start > 0, "Lock does not exist");
        require(lock.end > block.timestamp, "Lock time is finished");

        cumulativeTOSAmount = cumulativeTOSAmount.add(_value);
        _deposit(_addr, _lockId, _value, 0);
        emit LockDeposited(msg.sender, _lockId, _value);
    }

    /// @inheritdoc ILockTOS
    function totalSupplyAt(uint256 _timestamp)
        public
        view
        override
        returns (uint256)
    {
        if (pointHistory.length == 0) {
            return 0;
        }

        (bool success, LibLockTOS.Point memory point) =
            _findClosestPoint(pointHistory, _timestamp);
        if (!success) {
            return 0;
        }
        
        point = _fillRecordGaps(point, _timestamp);
        int256 currentBias =
            point.slope * (_timestamp.sub(point.timestamp).toInt256());
        return
            uint256(point.bias > currentBias ? point.bias - currentBias : 0)
                .div(MULTIPLIER);
    }

    /// @inheritdoc ILockTOS
    function totalLockedAmountOf(address _addr) external view override returns (uint256) {
        uint256 len = userLocks[_addr].length;
        uint256 stakedAmount = 0;
        for (uint256 i = 0; i < len; ++i) {
            uint256 lockId = userLocks[_addr][i];
            LibLockTOS.LockedBalance memory lock = lockedBalances[_addr][lockId];
            stakedAmount = stakedAmount.add(lock.amount);
        }
        return stakedAmount;
    }

    /// @inheritdoc ILockTOS
    function withdrawableAmountOf(address _addr) external view override returns (uint256) {
        uint256 len = userLocks[_addr].length;
        uint256 amount = 0;
        for(uint i = 0; i < len; i++){
            uint256 lockId = userLocks[_addr][i];
            LibLockTOS.LockedBalance memory lock = lockedBalances[_addr][lockId];
            if(lock.end <= block.timestamp && lock.amount > 0 && lock.withdrawn == false) {
                amount = amount.add(lock.amount);
            }
        }
        return amount;
    }

    /// @inheritdoc ILockTOS
    function totalSupply() external view override returns (uint256) {
        if (pointHistory.length == 0) {
            return 0;
        }

        LibLockTOS.Point memory point = _fillRecordGaps(
            pointHistory[pointHistory.length - 1],
            block.timestamp
        );

        int256 currentBias =
            point.slope.mul(block.timestamp.sub(point.timestamp).toInt256());
        return
            uint256(point.bias > currentBias ? point.bias.sub(currentBias) : 0)
                .div(MULTIPLIER);
    }

    /// @inheritdoc ILockTOS
    function balanceOfLockAt(uint256 _lockId, uint256 _timestamp)
        public
        view
        override
        returns (uint256)
    {
        (bool success, LibLockTOS.Point memory point) =
            _findClosestPoint(lockPointHistory[_lockId], _timestamp);
        if (!success) {
            return 0;
        }
        int256 currentBias =
            point.slope.mul(_timestamp.sub(point.timestamp).toInt256());
        return
            uint256(point.bias > currentBias ? point.bias.sub(currentBias) : 0)
                .div(MULTIPLIER);
    }

    /// @inheritdoc ILockTOS
    function balanceOfLock(uint256 _lockId)
        public
        view
        override
        returns (uint256)
    {
        uint256 len = lockPointHistory[_lockId].length;
        if (len == 0) {
            return 0;
        }

        LibLockTOS.Point memory point = lockPointHistory[_lockId][len - 1];
        int256 currentBias =
            point.slope.mul(block.timestamp.sub(point.timestamp).toInt256());
        return
            uint256(point.bias > currentBias ? point.bias.sub(currentBias) : 0)
                .div(MULTIPLIER);
    }

    /// @inheritdoc ILockTOS
    function balanceOfAt(address _addr, uint256 _timestamp)
        public
        view
        override
        returns (uint256 balance)
    {
        uint256[] memory locks = userLocks[_addr];
        if (locks.length == 0) return 0;
        for (uint256 i = 0; i < locks.length; ++i) {
            balance = balance.add(balanceOfLockAt(locks[i], _timestamp));
        }
    }

    /// @inheritdoc ILockTOS
    function balanceOf(address _addr)
        public
        view
        override
        returns (uint256 balance)
    {
        uint256[] memory locks = userLocks[_addr];
        if (locks.length == 0) return 0;
        for (uint256 i = 0; i < locks.length; ++i) {
            balance = balance.add(balanceOfLock(locks[i]));
        }
    }

    /// @inheritdoc ILockTOS
    function locksInfo(uint256 _lockId)
        public
        view
        override
        returns (
            uint256 start,
            uint256 end,
            uint256 amount
        )
    {
        return (
            allLocks[_lockId].start,
            allLocks[_lockId].end,
            allLocks[_lockId].amount
        );
    }

    /// @inheritdoc ILockTOS
    function locksOf(address _addr)
        public
        view
        override
        returns (uint256[] memory)
    {
        return userLocks[_addr];
    }

    /// @inheritdoc ILockTOS
    function withdrawableLocksOf(address _addr)  external view override returns (uint256[] memory) {
        uint256 len = userLocks[_addr].length;
        uint256 size = 0;
        for(uint i = 0; i < len; i++){
            uint256 lockId = userLocks[_addr][i];
            LibLockTOS.LockedBalance memory lock = lockedBalances[_addr][lockId];
            if(lock.end <= block.timestamp && lock.amount > 0 && lock.withdrawn == false) {
                size++;
            }
        }

        uint256[] memory withdrawable = new uint256[](size);
        size = 0;
        for(uint i = 0; i < len; i++) {
            uint256 lockId = userLocks[_addr][i];
            LibLockTOS.LockedBalance memory lock = lockedBalances[_addr][lockId];
            if(lock.end <= block.timestamp && lock.amount > 0 && lock.withdrawn == false) {
                withdrawable[size++] = lockId;
            }
        }
        return withdrawable;
    }

    /// @inheritdoc ILockTOS
    function activeLocksOf(address _addr)
        public
        view
        override
        returns (uint256[] memory)
    {
        uint256 len = userLocks[_addr].length;
        uint256 _size = 0;
        for(uint i = 0; i < len; i++){
            uint256 lockId = userLocks[_addr][i];
            LibLockTOS.LockedBalance memory lock = lockedBalances[_addr][lockId];
            if(lock.end > block.timestamp) {
                _size++;
            }
        }

        uint256[] memory activeLocks = new uint256[](_size);
        _size = 0;
        for(uint i = 0; i < len; i++) {
            uint256 lockId = userLocks[_addr][i];
            LibLockTOS.LockedBalance memory lock = lockedBalances[_addr][lockId];
            if(lock.end > block.timestamp) {
                activeLocks[_size++] = lockId;
            }
        }
        return activeLocks;
    }

    /// @inheritdoc ILockTOS
    function pointHistoryOf(uint256 _lockId)
        public
        view
        override
        returns (LibLockTOS.Point[] memory)
    {
        return lockPointHistory[_lockId];
    }

    /// @dev Finds closest point
    function _findClosestPoint(
        LibLockTOS.Point[] storage _history,
        uint256 _timestamp
    ) internal view returns (bool success, LibLockTOS.Point memory point) {
        if (_history.length == 0) {
            return (false, point);
        }
        
        uint256 left = 0;
        uint256 right = _history.length;
        while (left + 1 < right) {
            uint256 mid = left.add(right).div(2);
            if (_history[mid].timestamp <= _timestamp) {
                left = mid;
            } else {
                right = mid;
            }
        }

        if (_history[left].timestamp <= _timestamp) {
            return (true, _history[left]);
        }
        return (false, point);
    }

    /// @dev Deposit
    function _deposit(
        address _addr,
        uint256 _lockId,
        uint256 _value,
        uint256 _unlockTime
    ) internal ifFree {
        LibLockTOS.LockedBalance memory lockedOld =
            lockedBalances[_addr][_lockId];
        LibLockTOS.LockedBalance memory lockedNew =
            LibLockTOS.LockedBalance({
                amount: lockedOld.amount,
                start: lockedOld.start,
                end: lockedOld.end,
                withdrawn: false
            });

        // Make new lock
        lockedNew.amount = lockedNew.amount.add(_value);
        if (_unlockTime > 0) {
            lockedNew.end = _unlockTime;
        }
        if (lockedNew.start == 0) {
            lockedNew.start = block.timestamp;
        }

        // Checkpoint
        _checkpoint(lockedNew, lockedOld);

        // Save new lock
        lockedBalances[_addr][_lockId] = lockedNew;
        allLocks[_lockId] = lockedNew;

        // Save user point,
        int256 userSlope =
            lockedNew.amount.mul(MULTIPLIER).div(maxTime).toInt256();
        int256 userBias =
            userSlope.mul(lockedNew.end.sub(block.timestamp).toInt256());
        LibLockTOS.Point memory userPoint =
            LibLockTOS.Point({
                timestamp: block.timestamp,
                slope: userSlope,
                bias: userBias
            });
        lockPointHistory[_lockId].push(userPoint);

        // Transfer TOS
        require(
            IERC20(tos).transferFrom(msg.sender, address(this), _value),
            "LockTOS: fail transferFrom"
        );
    }

    /// @dev Checkpoint
    function _checkpoint(
        LibLockTOS.LockedBalance memory lockedNew,
        LibLockTOS.LockedBalance memory lockedOld
    ) internal {
        uint256 timestamp = block.timestamp;
        LibLockTOS.SlopeChange memory changeNew =
            LibLockTOS.SlopeChange({slope: 0, bias: 0, changeTime: 0});
        LibLockTOS.SlopeChange memory changeOld =
            LibLockTOS.SlopeChange({slope: 0, bias: 0, changeTime: 0});

        // Initialize slope changes
        if (lockedNew.end > timestamp && lockedNew.amount > 0) {
            changeNew.slope = lockedNew
                .amount
                .mul(MULTIPLIER)
                .div(maxTime)
                .toInt256();
            changeNew.bias = changeNew.slope
                .mul(lockedNew.end.sub(timestamp).toInt256());
            changeNew.changeTime = lockedNew.end;
        }
        if (lockedOld.end > timestamp && lockedOld.amount > 0) {
            changeOld.slope = lockedOld
                .amount
                .mul(MULTIPLIER)
                .div(maxTime)
                .toInt256();
            changeOld.bias = changeOld.slope
                .mul(lockedOld.end.sub(timestamp).toInt256());
            changeOld.changeTime = lockedOld.end;
        }

        // Record history gaps
        LibLockTOS.Point memory currentWeekPoint = _recordHistoryPoints();
        currentWeekPoint.bias = currentWeekPoint.bias.add(
            changeNew.bias.sub(changeOld.bias)
        );
        currentWeekPoint.slope = currentWeekPoint.slope.add(
            changeNew.slope.sub(changeOld.slope)
        );
        currentWeekPoint.bias = currentWeekPoint.bias > 0
            ? currentWeekPoint.bias
            : 0;
        currentWeekPoint.slope = currentWeekPoint.slope > 0
            ? currentWeekPoint.slope
            : 0;
        pointHistory[pointHistory.length - 1] = currentWeekPoint;

        // Update slope changes
        _updateSlopeChanges(changeNew, changeOld);
    }

    /// @dev Fill the gaps
    function _recordHistoryPoints()
        internal
        returns (LibLockTOS.Point memory lastWeek)
    {
        uint256 timestamp = block.timestamp;
        if (pointHistory.length > 0) {
            lastWeek = pointHistory[pointHistory.length - 1];
        } else {
            lastWeek = LibLockTOS.Point({
                bias: 0,
                slope: 0,
                timestamp: timestamp
            });
        }

        // Iterate through all past unrecoreded weeks and record
        uint256 pointTimestampIterator =
            lastWeek.timestamp.div(epochUnit).mul(epochUnit);
        while (pointTimestampIterator != timestamp) {
            pointTimestampIterator = Math.min(
                pointTimestampIterator.add(epochUnit),
                timestamp
            );
            int256 deltaSlope = slopeChanges[pointTimestampIterator];
            int256 deltaTime =
                Math.min(pointTimestampIterator.sub(lastWeek.timestamp), epochUnit).toInt256();
            lastWeek.bias = lastWeek.bias.sub(lastWeek.slope.mul(deltaTime));
            lastWeek.slope = lastWeek.slope.add(deltaSlope);
            lastWeek.bias = lastWeek.bias > 0 ? lastWeek.bias : 0;
            lastWeek.slope = lastWeek.slope > 0 ? lastWeek.slope : 0;
            lastWeek.timestamp = pointTimestampIterator;
            pointHistory.push(lastWeek);
        }
        return lastWeek;
    }

    /// @dev Fills the record gaps
    function _fillRecordGaps(LibLockTOS.Point memory week, uint256 timestamp)
        internal
        view
        returns (LibLockTOS.Point memory)
    {
        // Iterate through all past unrecoreded weeks
        uint256 pointTimestampIterator =
            week.timestamp.div(epochUnit).mul(epochUnit);
        while (pointTimestampIterator != timestamp) {
            pointTimestampIterator = Math.min(
                pointTimestampIterator.add(epochUnit),
                timestamp
            );
            int256 deltaSlope = slopeChanges[pointTimestampIterator];
            int256 deltaTime =
                Math.min(pointTimestampIterator.sub(week.timestamp), epochUnit).toInt256();
            week.bias = week.bias.sub(week.slope.mul(deltaTime));
            week.slope = week.slope.add(deltaSlope);
            week.bias = week.bias > 0 ? week.bias : 0;
            week.slope = week.slope > 0 ? week.slope : 0;
            week.timestamp = pointTimestampIterator;
        }
        return week;
    }

    /// @dev Update slope changes
    function _updateSlopeChanges(
        LibLockTOS.SlopeChange memory changeNew,
        LibLockTOS.SlopeChange memory changeOld
    ) internal {
        int256 deltaSlopeNew = slopeChanges[changeNew.changeTime];
        int256 deltaSlopeOld = slopeChanges[changeOld.changeTime];
        if (changeOld.changeTime > block.timestamp) {
            deltaSlopeOld = deltaSlopeOld.add(changeOld.slope);
            if (changeOld.changeTime == changeNew.changeTime) {
                deltaSlopeOld = deltaSlopeOld.sub(changeNew.slope);
            }
            slopeChanges[changeOld.changeTime] = deltaSlopeOld;
        }
        if (
            changeNew.changeTime > block.timestamp &&
            changeNew.changeTime > changeOld.changeTime
        ) {
            deltaSlopeNew = deltaSlopeNew.sub(changeNew.slope);
            slopeChanges[changeNew.changeTime] = deltaSlopeNew;
        }
    }

    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    function currentStakedTotalTOS() external view returns (uint256) {
        return IERC20(tos).balanceOf(address(this));
    }
}
