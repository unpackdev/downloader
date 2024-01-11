// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;

import "./IBLXMRewardProvider.sol";
import "./BLXMTreasuryManager.sol";
import "./BLXMMultiOwnable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./SafeMath.sol";
import "./Math.sol";
import "./BLXMLibrary.sol";


contract BLXMRewardProvider is ReentrancyGuardUpgradeable, BLXMMultiOwnable, BLXMTreasuryManager, IBLXMRewardProvider {

    using SafeMath for uint;

    struct Field {
        uint32 syncHour; // at most sync once an hour
        uint totalLiquidity; // exclude extra liquidity
        uint pendingRewards;
        uint32 initialHour;
        uint16 lastSession;

        // days => session
        mapping(uint32 => uint16) daysToSession;

        // session => Period struct
        mapping(uint16 => Period) periods;

        // hours from the epoch => statistics
        mapping(uint32 => Statistics) dailyStatistics;
    }

    struct Period {
        uint amountPerHours;
        uint32 startHour; // include, timestamp in hour from initial hour
        uint32 endHour; // exclude, timestamp in hour from initial hour
    }

    struct Statistics {
        uint liquidityIn; // include extra liquidity
        uint liquidityOut;
        uint aggregatedRewards; // rewards / (liquidityIn - liquidityOut)
        uint32 next;
    }

    struct Position {
        address token; // (another pair from blxm)
        uint liquidity;
        uint extraLiquidity;
        uint32 startHour; // include, hour from epoch, time to start calculating rewards
        uint32 endLocking; // exclude, hour from epoch, locked until this hour
    }

    // token (another pair from blxm) => Field
    mapping(address => Field) private treasuryFields;

    // user address => idx => position
    mapping(address => Position[]) public override allPosition;

    // locked days => factor
    mapping(uint16 => uint) internal rewardFactor;


    function updateRewardFactor(uint16 lockedDays, uint factor) public override onlyOwner returns (bool) {
        require(lockedDays != 0, 'ZERO_DAYS');
        rewardFactor[lockedDays] = factor.sub(10 ** 18);
        return true;
    }

    function getRewardFactor(uint16 lockedDays) external override view returns (uint factor) {
        factor = rewardFactor[lockedDays];
        factor = factor.add(10 ** 18);
    }

    function allPositionLength(address investor) public override view returns (uint) {
        return allPosition[investor].length;
    }

    function _addRewards(address token, uint totalAmount, uint16 supplyDays) internal nonReentrant onlyOwner returns (uint amountPerHours) {
        require(totalAmount > 0 && supplyDays > 0, 'ZERO_REWARDS');
        _syncStatistics(token);

        Field storage field = treasuryFields[token];

        uint16 lastSession = field.lastSession;
        if (lastSession == 0) {
            field.initialHour = BLXMLibrary.currentHour();
        }

        uint32 startHour = field.periods[lastSession].endHour;
        uint32 endHour = startHour + (supplyDays * 24);

        lastSession += 1;
        field.lastSession = lastSession;

        uint32 target = startHour / 24;
        uint32 i = endHour / 24;
        unchecked {
            while (i --> target) {
                // reverse mapping
                field.daysToSession[i] = lastSession;
            }
        }

        amountPerHours = totalAmount / (supplyDays * 24);
        field.periods[lastSession] = Period(amountPerHours, startHour, endHour);

        if (field.pendingRewards != 0) {
            uint pendingRewards = field.pendingRewards;
            field.pendingRewards = 0;
            _arrangeFailedRewards(token, pendingRewards);
        }

        uint32 initialHour = field.initialHour;
        emit AddRewards(msg.sender, initialHour + startHour, initialHour + endHour, amountPerHours);
    }

    // ** DO NOT CALL THIS FUNCTION AS A WRITE FUNCTION **
    function calcRewards(address investor, uint idx) external override returns (uint amount, bool isLocked) {
        require(idx < allPositionLength(investor), 'NO_POSITION');
        Position memory position = allPosition[investor][idx];
        _syncStatistics(position.token);
        (amount, isLocked) = _calcRewards(position);
    }

    function syncStatistics(address token) public override {
        getTreasury(token);
        _syncStatistics(token);
    }

    function decimals() public override pure returns (uint8) {
        return 18;
    }

    function getDailyStatistics(address token, uint32 hourFromEpoch) external view override returns (uint liquidityIn, uint liquidityOut, uint aggregatedRewards, uint32 next) {
        Statistics memory statistics = treasuryFields[token].dailyStatistics[hourFromEpoch];
        liquidityIn = statistics.liquidityIn;
        liquidityOut = statistics.liquidityOut;
        aggregatedRewards = statistics.aggregatedRewards;
        next = statistics.next;
    }

    function hoursToSession(address token, uint32 hourFromEpoch) external override view returns (uint16 session) {
        Field storage field = treasuryFields[token];
        uint32 initialHour = field.initialHour;
        if (hourFromEpoch >= initialHour) {
            uint32 hour = hourFromEpoch - initialHour;
            session = field.daysToSession[hour / 24];
        }
    }

    function getPeriods(address token, uint16 session) external override view returns (uint amountPerHours, uint32 startHour, uint32 endHour) {
        Field storage field = treasuryFields[token];

        Period storage period = field.periods[session];
        amountPerHours = period.amountPerHours;

        uint32 initialHour = field.initialHour;
        startHour = period.startHour;
        endHour = period.endHour;
        
        if (startHour != 0 || endHour != 0) {
            startHour += initialHour;
            endHour += initialHour;
        }
    }

    function getTreasuryFields(address token) external view override returns(uint32 syncHour, uint totalLiquidity, uint pendingRewards, uint32 initialHour, uint16 lastSession) {
        Field storage fields = treasuryFields[token];
        syncHour = fields.syncHour;
        totalLiquidity = fields.totalLiquidity;
        pendingRewards = fields.pendingRewards;
        initialHour = fields.initialHour;
        lastSession = fields.lastSession;
    }

    // if (is locked) {
    //     (liquidity + extra liquidity) * (agg now - agg hour in)
    // } else {
    //     liquidity * (agg now - agg hour in)
    //     extra liquidity * (agg end locking - agg hour in)
    // }
    function _calcRewards(Position memory position) internal view returns (uint amount, bool isLocked) {

        uint32 currentHour = BLXMLibrary.currentHour();
        require(treasuryFields[position.token].syncHour == currentHour, 'NOT_SYNC');

        if (currentHour < position.startHour) {
            return (0, true);
        }

        if (currentHour < position.endLocking) {
            isLocked = true;
        }

        uint liquidity = position.liquidity;
        uint extraLiquidity = position.extraLiquidity;
        
        Field storage field = treasuryFields[position.token];
        uint aggNow = field.dailyStatistics[currentHour].aggregatedRewards;
        uint aggStart = field.dailyStatistics[position.startHour].aggregatedRewards;
        if (isLocked) {
            amount = liquidity.add(extraLiquidity).wmul(aggNow.sub(aggStart));
        } else {
            uint aggEnd = field.dailyStatistics[position.endLocking].aggregatedRewards;
            amount = extraLiquidity.wmul(aggEnd.sub(aggStart));
            amount = amount.add(liquidity.wmul(aggNow.sub(aggStart)));
        }
    }

    function _mint(address to, address token, uint amountBlxm, uint amountToken, uint16 lockedDays) internal nonReentrant returns (uint liquidity) {
        liquidity = Math.sqrt(amountBlxm.mul(amountToken));
        require(liquidity != 0, 'INSUFFICIENT_LIQUIDITY');
        _syncStatistics(token);

        uint factor = rewardFactor[lockedDays];
        uint extraLiquidity = liquidity.wmul(factor);

        uint32 startHour = BLXMLibrary.currentHour() + 1;
        uint32 endLocking = factor != 0 ? startHour + (lockedDays * 24) : startHour;

        allPosition[to].push(Position(token, liquidity, extraLiquidity, startHour, endLocking));
        
        _updateLiquidity(token, startHour, liquidity.add(extraLiquidity), 0);
        if (extraLiquidity != 0) {
            _updateLiquidity(token, endLocking, 0, extraLiquidity);
        }

        treasuryFields[token].totalLiquidity = liquidity.add(treasuryFields[token].totalLiquidity);

        _notify(token, amountBlxm, amountToken, to);
        emit Mint(msg.sender, amountBlxm, amountToken);
        _emitAllPosition(to, allPositionLength(to) - 1);
    }

    function _burn(address to, uint liquidity, uint idx) internal nonReentrant returns (uint amountBlxm, uint amountToken, uint rewardAmount) {
        require(idx < allPositionLength(msg.sender), 'NO_POSITION');
        Position memory position = allPosition[msg.sender][idx];
        require(liquidity > 0 && liquidity <= position.liquidity, 'INSUFFICIENT_LIQUIDITY');
        _syncStatistics(position.token);

        // The start hour must be a full hour, 
        // when add and remove on the same hour, 
        // the next hour's liquidity should be subtracted.
        uint32 hour = BLXMLibrary.currentHour();
        hour = hour >= position.startHour ? hour : position.startHour;
        _updateLiquidity(position.token, hour, 0, liquidity);

        uint extraLiquidity = position.extraLiquidity * liquidity / position.liquidity;

        bool isLocked;
        (rewardAmount, isLocked) = _calcRewards(position);
        rewardAmount = rewardAmount * liquidity / position.liquidity;
        if (isLocked) {
            _arrangeFailedRewards(position.token, rewardAmount);
            rewardAmount = 0;
            _updateLiquidity(position.token, hour, 0, extraLiquidity);
            _updateLiquidity(position.token, position.endLocking, extraLiquidity, 0);
        }

        allPosition[msg.sender][idx].liquidity = position.liquidity.sub(liquidity);
        allPosition[msg.sender][idx].extraLiquidity = position.extraLiquidity.sub(extraLiquidity);
        
        uint _totalLiquidity = treasuryFields[position.token].totalLiquidity;
        treasuryFields[position.token].totalLiquidity = _totalLiquidity.sub(liquidity);

        (amountBlxm, amountToken) = _withdraw(position.token, rewardAmount, liquidity, to);
        emit Burn(msg.sender, amountBlxm, amountToken, rewardAmount, to);
        _emitAllPosition(msg.sender, idx);
    }

    function _emitAllPosition(address owner, uint idx) internal {
        Position memory position = allPosition[owner][idx];
        emit AllPosition(owner, position.token, position.liquidity, position.extraLiquidity, position.startHour, position.endLocking, idx);
    }

    function _arrangeFailedRewards(address token, uint rewardAmount) internal {
        if (rewardAmount == 0) {
            return;
        }
        Field storage field = treasuryFields[token];
        uint32 initialHour = field.initialHour;
        uint32 startHour = BLXMLibrary.currentHour() - initialHour;
        uint16 session = field.daysToSession[startHour / 24];
        if (session == 0) {
            field.pendingRewards += rewardAmount; 
            return;
        }

        uint32 endHour = field.periods[session].endHour;
        uint32 leftHour = endHour - startHour;
        uint amountPerHours = rewardAmount / leftHour;
        field.periods[session].amountPerHours += amountPerHours;

        emit ArrangeFailedRewards(msg.sender, initialHour + startHour, initialHour + endHour, amountPerHours);
    }

    function _updateLiquidity(address token, uint32 hour, uint liquidityIn, uint liquidityOut) internal {
        require(hour >= BLXMLibrary.currentHour(), 'DATA_FIXED');
        Field storage field = treasuryFields[token];
        Statistics memory statistics = field.dailyStatistics[hour];
        statistics.liquidityIn = statistics.liquidityIn.add(liquidityIn);
        statistics.liquidityOut = statistics.liquidityOut.add(liquidityOut);
        field.dailyStatistics[hour] = statistics;
    }

    // should sync statistics every time before liquidity or rewards change
    function _syncStatistics(address token) internal {
        uint32 currentHour = BLXMLibrary.currentHour();
        uint32 syncHour = treasuryFields[token].syncHour;

        if (syncHour < currentHour) {
            if (syncHour != 0) {
                _updateStatistics(token, syncHour, currentHour);
            }
            treasuryFields[token].syncHour = currentHour;
        }
    }

    function _updateStatistics(address token, uint32 fromHour, uint32 toHour) internal {
        Field storage field = treasuryFields[token];
        Statistics storage statistics = field.dailyStatistics[fromHour];
        uint liquidityIn = statistics.liquidityIn;
        uint liquidityOut = statistics.liquidityOut;
        uint aggregatedRewards = statistics.aggregatedRewards;
        uint32 prev = fromHour; // point to previous statistics
        while (fromHour < toHour) {
            uint liquidity = liquidityIn.sub(liquidityOut);
            uint rewards = field.periods[field.daysToSession[(fromHour - field.initialHour) / 24]].amountPerHours;

            if (liquidity != 0) {
                aggregatedRewards = aggregatedRewards.add(rewards.wdiv(liquidity));
            }

            fromHour += 1;
            statistics = field.dailyStatistics[fromHour];

            if (statistics.liquidityIn != 0 || statistics.liquidityOut != 0 || fromHour == toHour) {
                statistics.aggregatedRewards = aggregatedRewards;
                statistics.liquidityIn = liquidityIn = liquidityIn.add(statistics.liquidityIn);
                statistics.liquidityOut = liquidityOut = liquidityOut.add(statistics.liquidityOut);
                field.dailyStatistics[prev].next = fromHour;
                prev = fromHour;

                emit SyncStatistics(msg.sender, token, liquidityIn, liquidityOut, aggregatedRewards, fromHour);
            }
        }
    }

    /**
    * This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}