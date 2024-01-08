// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract Staking is Ownable, ReentrancyGuard {
    //STRUCTURES:--------------------------------------------------------
    struct AccountInfo {
        uint256 lessBalance;
        uint256 lpBalance;
        uint256 overallBalance;
    }

    struct StakeItem {
        uint256 startTime;
        uint256 stakedLp;
        uint256 stakedLess;
    }

    struct UserStakes {
        uint256[] ids;
        mapping(uint256 => uint256) indexes;
    }

    struct DepositReward {
        uint256 day;
        uint256 lpShares;
        uint256 lessShares;
        uint256 lpReward;
        uint256 lessReward;
    }

    //FIELDS:----------------------------------------------------
    ERC20 public lessToken;
    ERC20 public lpToken;

    uint256 public contractStart;
    uint256 public minStakeTime;
    uint256 public dayDuration;
    uint256 public participants;
    uint16 public penaltyDistributed = 25; //100% = PERCENT_FACTOR
    uint16 public penaltyBurned = 25; //100% = PERCENT_FACTOR
    uint256 private constant PERCENT_FACTOR = 1000;
    uint256 public lessPerLp = 300; //1 LP = 300 LESS

    uint256 public stakeIdLast;

    uint256 public allLp;
    uint256 public allLess;
    uint256 public totalLpRewards;
    uint256 public totalLessRewards;

    mapping(address => AccountInfo) private accountInfos;
    mapping(address => UserStakes) private userStakes;
    mapping(uint256 => StakeItem) public stakes;
    mapping(uint256 => DepositReward) public rewardDeposits;
    mapping(uint256 => uint256) private _dayIndexies;
    mapping(uint256 => bool) private _firstTransactionPerDay;

    uint8[4] public poolPercentages;
    uint256[5] public stakingTiers;

    uint256 private _todayPenaltyLp;
    uint256 private _todayPenaltyLess;
    uint256 private _lastDayPenalty;
    uint256 private _lastDayIndex;
    uint256[] private _depositDays;

    //CONSTRUCTOR-------------------------------------------------------
    constructor(
        ERC20 _lp,
        ERC20 _less,
        uint256 _dayDuration,
        uint256 _startTime
    ) {
        require(_dayDuration > 0 && _startTime > 0, "Error: wrong params");
        lessToken = _less;
        lpToken = _lp;

        dayDuration = _dayDuration;
        minStakeTime = _dayDuration * 30;
        contractStart = _startTime;

        poolPercentages[0] = 30; //tier 5
        poolPercentages[1] = 20; //tier 4
        poolPercentages[2] = 15; //tier 3
        poolPercentages[3] = 25; //tier 2

        stakingTiers[0] = 200000 ether; //tier 5
        stakingTiers[1] = 50000 ether; //tier 4
        stakingTiers[2] = 20000 ether; //tier 3
        stakingTiers[3] = 5000 ether; //tier 2
        stakingTiers[4] = 1000 ether; //tier 1

        _firstTransactionPerDay[0] = true;
    }

    //EVENTS:-----------------------------------------------------------------
    event Staked(
        address staker,
        uint256 stakeId,
        uint256 startTime,
        uint256 stakedLp,
        uint256 stakedLess
    );

    event Unstaked(
        address staker,
        uint256 stakeId,
        uint256 unstakeTime,
        bool isUnstakedEarlier
    );

    //MODIFIERS:---------------------------------------------------

    modifier onlyWhenOpen() {
        require(block.timestamp > contractStart, "Error: early");
        _;
    }

    //EXTERNAL AND PUBLIC WRITE FUNCTIONS:---------------------------------------------------

    /**
     * @dev stake tokens
     * @param lpAmount Amount of staked LP tokens
     * @param lessAmount Amount of staked Less tokens
     */

    function stake(uint256 lpAmount, uint256 lessAmount)
        external
        nonReentrant
        onlyWhenOpen
    {
        address sender = _msgSender();
        uint256 today = _currentDay();
        if(participants == 0 && totalLessRewards + totalLpRewards > 0){
            _todayPenaltyLp = totalLpRewards;
            _todayPenaltyLess = totalLessRewards;
            _lastDayPenalty = today;
        }
        _rewriteTodayVars();
        if (userStakes[sender].ids.length == 0) {
            participants++;
        }
        require(lpAmount > 0 || lessAmount > 0, "Error: zero staked tokens");

        if (lpAmount > 0) {
            require(
                lpToken.transferFrom(sender, address(this), lpAmount),
                "Error: LP token tranfer failed"
            );
            allLp += lpAmount;
        }
        if (lessAmount > 0) {
            require(
                lessToken.transferFrom(sender, address(this), lessAmount),
                "Error: Less token tranfer failed"
            );
            allLess += lessAmount;
        }

        AccountInfo storage account = accountInfos[sender];

        account.lpBalance += lpAmount;
        account.lessBalance += lessAmount;
        account.overallBalance += lessAmount + getLpInLess(lpAmount);

        StakeItem memory newStake = StakeItem(today, lpAmount, lessAmount);
        stakes[stakeIdLast] = newStake;
        userStakes[sender].ids.push(stakeIdLast);
        userStakes[sender].indexes[stakeIdLast] = userStakes[sender].ids.length;

        emit Staked(sender, stakeIdLast++, today, lpAmount, lessAmount);
    }

    /**
     * @dev unstake all tokens and rewards
     * @param _stakeId id of the unstaked pool
     */

    function unstake(uint256 _stakeId) public onlyWhenOpen {
        _unstake(_stakeId, false);
    }

    /**
     * @dev unstake all tokens and rewards without penalty. Only for owner
     * @param _stakeId id of the unstaked pool
     */

    function unstakeWithoutPenalty(uint256 _stakeId)
        external
        onlyOwner
        onlyWhenOpen
    {
        _unstake(_stakeId, true);
    }

    /**
     * @dev withdraw all of unsold reward tokens. Only for owner
     */
    
    function emergencyWithdraw() external onlyOwner onlyWhenOpen nonReentrant {
        require(participants == 0 && totalLpRewards + totalLessRewards > 0, "Error: owner's emergency rewards withdraw is not available");
        uint256 lessToTransfer = totalLessRewards;
        uint256 lpToTransfer = totalLpRewards;
        if(totalLessRewards > 0){
            totalLessRewards = 0;
            require(lessToken.transfer(owner(), lessToTransfer), "Error: can't send tokens");
        }
        if(totalLpRewards > 0){
            totalLpRewards = 0;
            require(lpToken.transfer(owner(), lpToTransfer), "Error: can't send tokens");
        }
    }

    /**
     * @dev set num of Less per one LP
     */

    function setLessInLP(uint256 amount) public onlyOwner {
        lessPerLp = amount;
    }

    /**
     * @dev set minimum days of stake for unstake without penalty
     */

    function setMinTimeToStake(uint256 _minTimeInDays) public onlyOwner {
        require(_minTimeInDays > 0, "Error: zero time");
        minStakeTime = _minTimeInDays * dayDuration;
    }

    /**
     * @dev set penalty percent
     */
    function setPenalty(uint16 distributed, uint16 burned) public onlyOwner {
        penaltyDistributed = distributed;
        penaltyBurned = burned;
    }

    function setLp(address _lp) external onlyOwner {
        lpToken = ERC20(_lp);
    }

    function setLess(address _less) external onlyOwner {
        lessToken = ERC20(_less);
    }

    function setStakingTiresSums(
        uint256 tier1,
        uint256 tier2,
        uint256 tier3,
        uint256 tier4,
        uint256 tier5
    ) external onlyOwner {
        stakingTiers[0] = tier5; //tier 5
        stakingTiers[1] = tier4; //tier 4
        stakingTiers[2] = tier3; //tier 3
        stakingTiers[3] = tier2; //tier 2
        stakingTiers[4] = tier1; //tier 1
    }

    function setPoolPercentages(
        uint8 tier2,
        uint8 tier3,
        uint8 tier4,
        uint8 tier5
    ) external onlyOwner {
        require(
            tier2 + tier3 + tier4 + tier5 < 100,
            "Percents sum should be less 100"
        );

        poolPercentages[0] = tier5; //tier 5
        poolPercentages[1] = tier4; //tier 4
        poolPercentages[2] = tier3; //tier 3
        poolPercentages[3] = tier2; //tier 2
    }

    function addRewards(uint256 lpAmount, uint256 lessAmount)
        external
        onlyOwner
        nonReentrant
    {
        _rewriteTodayVars();
        address sender = _msgSender();
        require(lpAmount + lessAmount > 0, "Error: add non zero amount");
        if (lpAmount > 0) {
            require(
                lpToken.transferFrom(sender, address(this), lpAmount),
                "Error: can't get your lp tokens"
            );
            totalLpRewards += lpAmount;
            _todayPenaltyLp += lpAmount;
        }
        if (lessAmount > 0) {
            require(
                lessToken.transferFrom(sender, address(this), lessAmount),
                "Error: can't get your less tokens"
            );
            totalLessRewards += lessAmount;
            _todayPenaltyLess += lessAmount;
        }
        _lastDayPenalty = _currentDay();
    }

    //EXTERNAL AND PUBLIC READ FUNCTIONS:--------------------------------------------------

    function getUserTier(address user) external view returns (uint8) {
        uint256 balance = accountInfos[user].overallBalance;
        for (uint8 i = 0; i < stakingTiers.length; i++) {
            if (balance >= stakingTiers[i])
                return uint8(stakingTiers.length - i);
        }
        return 0;
    }

    function getLpRewradsAmount(uint256 id)
        external
        view
        returns (uint256 lpRewards)
    {
        (lpRewards, ) = _rewards(id);
    }

    function getLessRewradsAmount(uint256 id)
        external
        view
        returns (uint256 lessRewards)
    {
        (, lessRewards) = _rewards(id);
    }

    function getLpBalanceByAddress(address user)
        external
        view
        returns (uint256 lp)
    {
        lp = accountInfos[user].lpBalance;
    }

    function getLessBalanceByAddress(address user)
        external
        view
        returns (uint256 less)
    {
        less = accountInfos[user].lessBalance;
    }

    function getOverallBalanceInLessByAddress(address user)
        external
        view
        returns (uint256 overall)
    {
        overall = accountInfos[user].overallBalance;
    }

    /**
     * @dev return sum of LP converted in Less
     * @param _amount amount of converted LP
     */
    function getLpInLess(uint256 _amount) private view returns (uint256) {
        return _amount * lessPerLp;
    }

    /**
     * @dev return full contract balance converted in Less
     */
    function getOverallBalanceInLess() public view returns (uint256) {
        return allLess + allLp * lessPerLp;
    }

    function getAmountOfUsersStakes(address user)
        external
        view
        returns (uint256)
    {
        return userStakes[user].ids.length;
    }

    function getUserStakeIds(address user)
        external
        view
        returns (uint256[] memory)
    {
        return userStakes[user].ids;
    }

    function currentDay() external view onlyWhenOpen returns (uint256) {
        return _currentDay();
    }

    //INTERNAL AND PRIVATE FUNCTIONS-------------------------------------------------------
    function _unstake(uint256 id, bool isWithoutPenalty) internal nonReentrant {
        address staker = _msgSender();
        uint256 today = _currentDay();
        _rewriteTodayVars();
        require(userStakes[staker].ids.length > 0, "Error: you haven't stakes");
        require(userStakes[staker].indexes[id] != 0, "Not ur stake");

        bool isUnstakedEarlier = (today - stakes[id].startTime) * dayDuration <
            minStakeTime;

        uint256 lpRewards;
        uint256 lessRewards;
        if (!isUnstakedEarlier) (lpRewards, lessRewards) = _rewards(id);

        uint256 lpAmount = stakes[id].stakedLp;
        uint256 lessAmount = stakes[id].stakedLess;

        allLp -= lpAmount;
        allLess -= lessAmount;
        AccountInfo storage account = accountInfos[staker];

        account.lpBalance -= lpAmount;
        account.lessBalance -= lessAmount;
        account.overallBalance -= lessAmount + getLpInLess(lpAmount);

        if (isUnstakedEarlier && !isWithoutPenalty) {
            (lpAmount, lessAmount) = payPenalty(lpAmount, lessAmount);
            (uint256 freeLp, uint256 freeLess) = _rewards(id);
            if (freeLp > 0) _todayPenaltyLp += freeLp;
            if (freeLess > 0) _todayPenaltyLess += freeLess;
            _lastDayPenalty = today;
        }

        if (lpAmount + lpRewards > 0) {
            require(
                lpToken.transfer(staker, lpAmount + lpRewards),
                "Error: LP transfer failed"
            );
        }
        if (lessAmount + lessRewards > 0) {
            require(
                lessToken.transfer(staker, lessAmount + lessRewards),
                "Error: Less transfer failed"
            );
        }

        totalLessRewards -= lessRewards;
        totalLpRewards -= lpRewards;
        if (userStakes[staker].ids.length == 1) {
            participants--;
        }

        removeStake(staker, id);

        emit Unstaked(staker, id, today, isUnstakedEarlier);
    }

    function payPenalty(uint256 lpAmount, uint256 lessAmount)
        private
        returns (uint256, uint256)
    {
        uint256 lpToBurn = (lpAmount * penaltyBurned) / PERCENT_FACTOR;
        uint256 lessToBurn = (lessAmount * penaltyBurned) / PERCENT_FACTOR;
        uint256 lpToDist = (lpAmount * penaltyDistributed) / PERCENT_FACTOR;
        uint256 lessToDist = (lessAmount * penaltyDistributed) / PERCENT_FACTOR;

        burnPenalty(lpToBurn, lessToBurn);
        distributePenalty(lpToDist, lessToDist);

        uint256 lpDecrease = lpToBurn + lpToDist;
        uint256 lessDecrease = lessToBurn + lessToDist;

        return (lpAmount - lpDecrease, lessAmount - lessDecrease);
    }

    function _rewards(uint256 id)
        private
        view
        returns (uint256 lpRewards, uint256 lessRewards)
    {
        StakeItem storage deposit = stakes[id];

        uint256 countStartIndex;
        uint256 countEndIndex = _depositDays.length;

        uint256 i;
        for (i = 0; i < _depositDays.length; i++) {
            if (deposit.startTime <= _depositDays[i]) {
                countStartIndex = i;
                break;
            }
        }
        if (countStartIndex == 0 && i == _depositDays.length) {
            return (0, 0);
        }
        uint256 curDay;
        for (i = countStartIndex; i < countEndIndex; i++) {
            curDay = _dayIndexies[i];
            if (rewardDeposits[curDay].lpShares > 0) {
                lpRewards +=
                    (deposit.stakedLp * rewardDeposits[curDay].lpReward) /
                    rewardDeposits[curDay].lpShares;
            }
            if (rewardDeposits[curDay].lessShares > 0) {
                lessRewards +=
                    (deposit.stakedLess * rewardDeposits[curDay].lessReward) /
                    rewardDeposits[curDay].lessShares;
            }
        }

        return (lpRewards, lessRewards);
    }

    /**
     * @dev destribute penalty among all stakers proportional their stake sum.
     * @param lp LP token penalty
     * @param less Less token penalty
     */

    function distributePenalty(uint256 lp, uint256 less) internal {
        _todayPenaltyLess += less;
        _todayPenaltyLp += lp;
        _lastDayPenalty = _currentDay();
        totalLpRewards += lp;
        totalLessRewards += less;
    }

    /**
     * @dev burn penalty.
     * @param lp LP token penalty
     * @param less Less token penalty
     */

    function burnPenalty(uint256 lp, uint256 less) internal {
        if (lp > 0) {
            require(lpToken.transfer(owner(), lp), "con't get ur tkns");
        }
        if (less > 0) {
            require(lessToken.transfer(owner(), less), "cont get ur tkns");
        }
    }

    /**
     * @dev remove stake from stakeList by index
     * @param staker staker address
     * @param id id of stake pool
     */

    function removeStake(address staker, uint256 id) internal {
        delete stakes[id];

        require(
            userStakes[staker].ids.length != 0,
            "Error: whitelist is empty"
        );

        if (userStakes[staker].ids.length > 1) {
            uint256 stakeIndex = userStakes[staker].indexes[id] - 1;
            uint256 lastIndex = userStakes[staker].ids.length - 1;
            uint256 lastStake = userStakes[staker].ids[lastIndex];
            userStakes[staker].ids[stakeIndex] = lastStake;
            userStakes[staker].indexes[lastStake] = stakeIndex + 1;
        }
        userStakes[staker].ids.pop();
        userStakes[staker].indexes[id] = 0;
    }

    function _currentDay() private view returns (uint256) {
        return (block.timestamp - contractStart) / dayDuration;
    }

    function _rewriteTodayVars() private {
        uint256 today = _currentDay();
        if (
            !_firstTransactionPerDay[today] &&
            _todayPenaltyLess + _todayPenaltyLp > 0 &&
            participants > 0
        ) {
            rewardDeposits[_lastDayPenalty] = DepositReward(
                _lastDayPenalty,
                allLp,
                allLess,
                _todayPenaltyLp,
                _todayPenaltyLess
            );
            _todayPenaltyLp = 0;
            _todayPenaltyLess = 0;
            _depositDays.push(_lastDayPenalty);
            _dayIndexies[_depositDays.length - 1] = _lastDayPenalty;
            _firstTransactionPerDay[today] = true;
        }
    }
}