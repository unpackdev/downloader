// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SafeERC20.sol";
import "./AccessControl.sol";


contract Staking is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant SPONSOR = keccak256("SPONSOR");
    uint256 public constant PERCENTS_BASE = 100;
    uint256 public constant MULTIPLIER = 10**19;
    uint256 public constant YEAR = 365 days;

    IERC20 public immutable KON;
    uint256 public immutable deployTime;
    
    IERC20 public rewardToken;
    uint256 public maxPool = 20 * (10**6) * (10**18);
    uint256 public inactiveTokensInPool;
    uint256 public globalKoeffUSDTFW;
    uint256 public globalKoeffKONFW;
    uint256 public globalKoeffUSDTRW;
    uint256 public globalKoeffKONRW;
    uint256 public poolFullWeight;
    uint256 public poolReducedWeight;
    uint256 public penalty;
    uint256 public penaltyInKONAfterChange;
    uint256 public excessOfRewards;
    uint256 public capacity = 10;
    
    uint256[3] public percents = [15, 20, 25];
    uint256[3] public totalStaked;
    uint256[4] public updateIndexes;
    uint256[4] public lastUpdate;
    uint256[] public weight;
    DepositInfo[] public allDeposits;
    uint256 private _lock;

    mapping(address => uint256[]) public indexForUser;
    mapping(uint256 => uint256) public weightForDeposit;
    mapping(address => WhiteListInfo) public whiteListForUser;
    mapping(uint256 => RewardPool_3) public reward3Info;
    mapping(uint256 => uint256) public lockOwnersDeposits; 

    struct WhiteListInfo {
        uint256 index;
        uint256 enteredAt;
        uint256 amount;
        uint256 lockUpWL;
    }

    struct DepositInfo {
        Koeff varKoeff;
        address user;
        uint256 lockUp;
        uint256 sumInLock;
        uint256 enteredAt;
        uint256 pool;
        uint256 countHarvest;
        bool gotFixed;
    }

    struct Koeff {
        uint256 koeffBeforeDepositKON;
        uint256 koeffBeforeDepositUSDT;
        uint256 unreceivedRewardKON;
        uint256 unreceivedRewardUSDT;
        uint256 receivedRewardKON;
        uint256 receivedRewardUSDT;
    }

    struct RewardPool_3 {
        uint256 variableRewardTaken;
        uint256 part;
    }

    // to prevent too deep stack
    struct IntVars {
        uint256 rewardsUSDT;
        uint256 rewardsKON;
        uint256 amountPenalty;
        uint256 amountKON;
        uint256 amountUSDT;
    }

    event Deposit(address user, uint256 amount, uint256 lockUp, uint256 index);
    event Withdraw(address user, uint256 index);
    event Harvest(
        address user,
        uint256 amountKON,
        uint256 amountUSDT,
        uint256 index
    );
    event Reward(uint256 amount, uint256 time);

    modifier update() {
        updatePool();
        _;
    }

    modifier creator(uint256 index) {
        require(allDeposits[index].user == _msgSender(), "10");
        _;
    }

    modifier depositeIndex(uint256 index) {
        require(index < allDeposits.length, "0");
        _;
    }

    modifier nonReentrant() {
        require(_lock != 1, "1_");
        _lock = 1;
        _;
        _lock = 0;
    }

    constructor(
        address _kon,
        address _owner,
        address _sponsor
    ) {
        require(_kon != address(0) && _owner != address(0), "1");
        KON = IERC20(_kon);
        rewardToken = IERC20(_kon);
        weight.push(PERCENTS_BASE);
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(SPONSOR, _sponsor);
        deployTime = block.timestamp;
    }

    function indexes(address user) external view returns (uint256[] memory) {
        return indexForUser[user];
    }

    /**
     * @param _maxPool set new amount for the cap of the entire pool
     * @param _capacity set new amount for the capacity
     * @param _weight set new amount for the weight
     */
    function changeInternalVariables(
        uint256 _maxPool,
        uint256 _capacity,
        uint256 _weight
    ) external update onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_maxPool != maxPool) {
            require(_maxPool > 0 && _maxPool >= stakedSum(), "1");
            maxPool = _maxPool;
        }
        if (_capacity != capacity) {
            require(_capacity > 0, "2");
            capacity = _capacity;
        }
        if (_weight != weight[weight.length - 1]) {
            require(_weight <= PERCENTS_BASE, "3");
            weight.push(_weight);
        }
    }

    /**
     * @param reward amounts of reward for variable parts
     */
    function updateAmountsOfRewards(uint256 reward)
        external
        update
        onlyRole(SPONSOR)
        nonReentrant
    {
        require(reward > 0, "1");
        uint256 timestamp = block.timestamp;
        for (uint256 j = 0; j < 4; j += 1) {
            require(timestamp == lastUpdate[j], "2");
        }
        uint256 pool = stakedSum();
        require(pool > 0, "3");
        uint256 amount = reward;
        if (penalty > 0) {
            amount += penalty;
            penalty = 0;
        }
        uint256 rewardRW = (amount * poolReducedWeight) / pool;
        uint256 rewardFW = amount - rewardRW;
        if (poolFullWeight == 0 && rewardFW != 0) excessOfRewards += rewardFW;
        if (rewardToken == KON) {
            if (rewardFW > 0 && poolFullWeight != 0)
                globalKoeffKONFW += ((rewardFW * MULTIPLIER) / poolFullWeight);
            if (rewardRW > 0)
                globalKoeffKONRW += (rewardRW * MULTIPLIER) / poolReducedWeight;
        } else {
            if (rewardFW > 0 && poolFullWeight != 0)
                globalKoeffUSDTFW += (rewardFW * MULTIPLIER) / poolFullWeight;
            if (rewardRW > 0)
                globalKoeffUSDTRW +=
                    (rewardRW * MULTIPLIER) /
                    poolReducedWeight;
        }
        rewardToken.safeTransferFrom(_msgSender(), address(this), reward);
        emit Reward(reward, timestamp);
    }

    /**
     * @param usdt address of new token for rewards
     */
    function setNewRewardToken(address usdt)
        external
        update
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(usdt != address(0) && rewardToken == KON, "1");
        uint256 timestamp = block.timestamp;
        for (uint256 j = 0; j < 4; j += 1) {
            require(timestamp == lastUpdate[j], "2");
        }
        uint256 pool = stakedSum();
        if (penalty > 0 && pool > 0) {
            uint256 rewardRW = (penalty * poolReducedWeight) / pool;
            uint256 rewardFW = penalty - rewardRW;
            if (rewardFW > 0 && poolFullWeight != 0)
                globalKoeffKONFW += (rewardFW * MULTIPLIER) / poolFullWeight;
            if (rewardRW > 0)
                globalKoeffKONRW += (rewardRW * MULTIPLIER) / poolReducedWeight;
            penalty = 0;
        } else if(penalty > 0 && pool == 0) {
            KON.safeTransfer(_msgSender(), penalty);
            penalty = 0;
        }
        rewardToken = IERC20(usdt);
    }

    function getExcessToken()
        external
        update
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        require(penaltyInKONAfterChange > 0 || excessOfRewards > 0, "1");
        if (penaltyInKONAfterChange > 0) {
            KON.safeTransfer(_msgSender(), penaltyInKONAfterChange);
            penaltyInKONAfterChange = 0;
        }
        if (excessOfRewards > 0) {
            rewardToken.safeTransfer(_msgSender(), excessOfRewards);
            excessOfRewards = 0;
        }
    }

    /**
     * @param enteredAt start
     * @param amount deposits
     * @param addresses users
     * @param lockUp lockUp
     * @param isActualDeposit true if the element is deposit but not white list
     */
    function depositOrWLFromOwner(
        uint256[] memory enteredAt,
        uint256[] memory amount,
        address[] memory addresses,
        uint256[] memory lockUp,
        bool[] memory isActualDeposit
    ) external update onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        uint256 timestamp = block.timestamp;
        require((timestamp - deployTime) / 1 days <= 3, "0");
        uint256 len = addresses.length;
        require(
            len == amount.length &&
                len == lockUp.length &&
                len == enteredAt.length &&
                len == isActualDeposit.length,
            "1"
        );
        uint256 debt;
        uint256 previousEnteredAt_;
        address user;
        WhiteListInfo memory wl;
        Koeff memory koeff;
        for (uint256 i = 0; i < len; i += 1) {
            wl = WhiteListInfo(
                allDeposits.length,
                enteredAt[i],
                amount[i],
                lockUp[i]
            );
            user = addresses[i];
            require(wl.amount > 0, "2");
            require(wl.lockUpWL <= 2, "3");
            require(user != address(0), "4");
            require(
                timestamp >= wl.enteredAt && wl.enteredAt >= previousEnteredAt_,
                "5"
            );
            previousEnteredAt_ = wl.enteredAt;
            indexForUser[user].push(wl.index);
            weightForDeposit[wl.index] = 0;
            if (!isActualDeposit[i]) {
                whiteListForUser[user] = WhiteListInfo(
                    wl.index,
                    wl.enteredAt,
                    wl.amount,
                    wl.lockUpWL
                );
                koeff = Koeff(0, 0, 0, 0, 0, 0);
                wl = WhiteListInfo(0, 0, 0, 0);
            } else {
                koeff = Koeff(globalKoeffKONFW, globalKoeffUSDTFW, 0, 0, 0, 0);
                totalStaked[wl.lockUpWL] += wl.amount;
                poolFullWeight += wl.amount;
                debt += wl.amount;
            }
            allDeposits.push(
                DepositInfo(
                    koeff,
                    user,
                    wl.lockUpWL,
                    wl.amount,
                    wl.enteredAt,
                    0,
                    0,
                    false
                )
            );
        }

        if (debt > 0) KON.safeTransferFrom(_msgSender(), address(this), debt);
    }

    function setLocks(uint256[] memory lockPeriod, uint256[] memory index) external onlyRole(DEFAULT_ADMIN_ROLE)  { 
        require((block.timestamp - deployTime) / 1 days <= 3, "0");
        uint256 len = index.length;
        for (uint256 i = 0; i < len; i += 1) {
            lockOwnersDeposits[index[i]] = lockPeriod[i];
        }
    }

    /**
     * @param amount for deposit
     * @param lockUp for deposit
     */
    function deposit(uint256 amount, uint256 lockUp)
        external
        update
        nonReentrant
    {
        require(amount > 0, "1");
        require(lockUp < 3, "2");
        require(stakedSum() + amount <= maxPool, "3");
        address user = _msgSender();
        uint256 depLen = allDeposits.length;
        uint256 weiLen = weight.length;
        uint256 timestamp = block.timestamp;
        uint256 globKon;
        uint256 globUSDT;

        WhiteListInfo memory whiteList_ = whiteListForUser[user];
        if (
            whiteList_.amount == amount &&
            whiteList_.lockUpWL == lockUp &&
            (timestamp - deployTime) / 14 days < 1
        ) {
            timestamp = whiteList_.enteredAt;
            depLen = whiteList_.index;
            weightForDeposit[depLen] = 0;
        } else {
            weightForDeposit[depLen] = weiLen - 1;
        }

        if (weight[weightForDeposit[depLen]] == PERCENTS_BASE) {
            poolFullWeight += amount;
            globKon = globalKoeffKONFW;
            globUSDT = globalKoeffUSDTFW;
        } else {
            poolReducedWeight += ((amount * weight[weiLen - 1]) /
                PERCENTS_BASE);
            globKon = globalKoeffKONRW;
            globUSDT = globalKoeffUSDTRW;
        }

        totalStaked[lockUp] += amount;

        DepositInfo memory dep = DepositInfo(
            Koeff(globKon, globUSDT, 0, 0, 0, 0),
            user,
            lockUp,
            amount,
            timestamp,
            0,
            0,
            false
        );

        if (depLen == allDeposits.length) {
            indexForUser[user].push(depLen);
            allDeposits.push(dep);
        } else {
            allDeposits[depLen] = dep;
            delete whiteListForUser[user];
        }

        KON.safeTransferFrom(user, address(this), amount);
        emit Deposit(user, amount, lockUp, depLen);
    }

    /**
     * @param index for deposit
     */
    function harvest(uint256 index)
        public
        update
        depositeIndex(index)
        creator(index)
        nonReentrant
    {
        (uint256 kon, uint256 usdt) = _harvest(index);
        address user = _msgSender();
        _transfers(user, kon, usdt);
        emit Harvest(user, kon, usdt, index);
    }

    /**
     * @param index for lockUp
     */
    function withdraw(uint256 index)
        external
        update
        depositeIndex(index)
        creator(index)
        nonReentrant
    {
        DepositInfo storage stake = allDeposits[index];
        if(lockOwnersDeposits[index] != 0) {
            require(block.timestamp >= lockOwnersDeposits[index], "00");
        }
        require(stake.sumInLock > 0, "1");
        (uint256 year, uint256 months) = _amountOfYears(stake.enteredAt);
        IntVars memory vars;
        vars.rewardsKON = stake.sumInLock;

        if (year <= stake.lockUp) {
            uint256 rewKON;
            if (
                (stake.lockUp < 2 && year == stake.pool) ||
                (stake.lockUp == 2 && year == stake.pool)
            ) {
                vars.rewardsUSDT = stake.varKoeff.unreceivedRewardUSDT;
                rewKON = stake.varKoeff.unreceivedRewardKON;
                stake.varKoeff.receivedRewardKON += stake
                    .varKoeff
                    .unreceivedRewardKON;
                stake.varKoeff.receivedRewardUSDT += stake
                    .varKoeff
                    .unreceivedRewardUSDT;
                (vars.amountKON, vars.amountUSDT) = varPart(index);
            } else {
                (rewKON, vars.rewardsUSDT) = varPart(index);
            }

            vars.rewardsKON += currentFixedPart(index);
            vars.amountPenalty = fixedPart(index) / 2;

            vars.rewardsKON -= vars.amountPenalty;
            vars.rewardsKON += rewKON;

            if (rewardToken == KON) {
                penalty += vars.amountKON;
                penalty += vars.amountPenalty;
            } else {
                penaltyInKONAfterChange += vars.amountKON;
                penaltyInKONAfterChange += vars.amountPenalty;
                penalty += vars.amountUSDT;
            }
        } else if (
            (!stake.gotFixed &&
                (stake.lockUp < 2 ||
                    months >= reward3Info[index].variableRewardTaken))
        ) {
            (vars.amountKON, vars.rewardsUSDT) = _harvest(index);
            vars.rewardsKON += vars.amountKON;
        }

        if (
            (stake.lockUp == 2 && stake.pool != 4) ||
            (stake.lockUp < 2 && stake.pool < stake.lockUp + 1)
        ) _updateTotalStaked(stake.sumInLock, stake.lockUp, index);
        else inactiveTokensInPool -= stake.sumInLock;

        _transfers(stake.user, vars.rewardsKON, vars.rewardsUSDT);

        emit Withdraw(stake.user, index);

        delete allDeposits[index];
    }

    function stakedSum() public view returns (uint256 amount) {
        for (uint256 i = 0; i < 3; i += 1) {
            amount += totalStaked[i];
        }
    }

    /**
     * @dev calculate fixed part for now
     * @param index index of deposit
     */
    function currentFixedPart(uint256 index)
        public
        view
        returns (uint256 amount)
    {
        DepositInfo memory stake = allDeposits[index];
        (uint256 year, ) = _amountOfYears(stake.enteredAt);
        uint256 i;
        for (i; i < year && i <= stake.lockUp; i += 1) {
            amount += percents[i];
        }
        amount += (amount * stake.sumInLock) / PERCENTS_BASE; // фикс награда
        if (year < stake.lockUp + 1)
            amount += (((15 + (5 * i)) *
                stake.sumInLock * //
                (block.timestamp - (stake.enteredAt + YEAR * year))) / //
                (PERCENTS_BASE * YEAR));
    }

    /**
     * @dev calculate fixed part for stake for the entire period
     * @param index index of deposit
     */
    function fixedPart(uint256 index) public view returns (uint256 amount) {
        DepositInfo memory stake = allDeposits[index];
        for (uint256 i = 0; i < 3 && i <= stake.lockUp; i += 1) {
            amount += percents[i];
        }
        amount = (amount * stake.sumInLock) / PERCENTS_BASE;
    }

    /**
     * @dev calculate var part for now
     * @param index for deposit
     */
    function varPart(uint256 index)
        public
        view
        returns (uint256 inKON, uint256 inUSDT)
    {
        DepositInfo memory stake = allDeposits[index];
        uint256 weight_ = weight[weightForDeposit[index]];
        if (
            (stake.lockUp < 2 && stake.pool != stake.lockUp + 1) ||
            (stake.lockUp == 2 && stake.pool != 4)
        ) {
            if (weight_ == PERCENTS_BASE) {
                inKON = ((stake.sumInLock *
                    (globalKoeffKONFW - stake.varKoeff.koeffBeforeDepositKON)) /
                    MULTIPLIER -
                    stake.varKoeff.receivedRewardKON);
                if (globalKoeffUSDTFW != 0)
                    inUSDT = ((stake.sumInLock *
                        (globalKoeffUSDTFW -
                            stake.varKoeff.koeffBeforeDepositUSDT)) /
                        MULTIPLIER -
                        stake.varKoeff.receivedRewardUSDT);
            } else {
                uint256 amount = (stake.sumInLock * weight_) / PERCENTS_BASE;
                inKON = ((amount *
                    (globalKoeffKONRW - stake.varKoeff.koeffBeforeDepositKON)) /
                    MULTIPLIER -
                    stake.varKoeff.receivedRewardKON);
                if (globalKoeffUSDTRW != 0)
                    inUSDT = ((amount *
                        (globalKoeffUSDTRW -
                            stake.varKoeff.koeffBeforeDepositUSDT)) /
                        MULTIPLIER -
                        stake.varKoeff.receivedRewardUSDT);
            }
        } else
            return (
                stake.varKoeff.unreceivedRewardKON,
                stake.varKoeff.unreceivedRewardUSDT
            );
    }

    function updatePool() public {
        uint256 len = allDeposits.length;
        uint256 year;
        DepositInfo storage stake;

        uint256 i;
        uint256 limit;
        for (uint256 j = 0; j < 4; j += 1) {
            i = updateIndexes[j];
            limit = (i + capacity > len) ? len : i + capacity;
            for (i; i < limit; i += 1) {
                stake = allDeposits[i];
                (year, ) = _amountOfYears(stake.enteredAt);
                if (year > j) {
                    if (
                        stake.sumInLock > 0 &&
                        ((stake.lockUp < 2 && stake.pool <= stake.lockUp) ||
                            (stake.lockUp == 2 && stake.pool < 4))
                    ) {
                        (
                            stake.varKoeff.unreceivedRewardKON,
                            stake.varKoeff.unreceivedRewardUSDT
                        ) = varPart(i);
                        if (
                            (j < 2 && stake.lockUp == j) ||
                            (j == 3 && stake.lockUp == 2)
                        ) {
                            _updateTotalStaked(
                                stake.sumInLock,
                                stake.lockUp,
                                i
                            );
                            inactiveTokensInPool += stake.sumInLock;
                        }
                        stake.pool += 1;
                    }
                    updateIndexes[j] = i + 1;
                } else {
                    lastUpdate[j] = block.timestamp;
                    break;
                }
            }
            if (i == len) lastUpdate[j] = block.timestamp;
        }
    }

    function _amountOfYears(uint256 start)
        private
        view
        returns (uint256 amount, uint256 months)
    {
        amount = (block.timestamp - start) / YEAR;
        if (amount >= 3)
            months = (block.timestamp - (start + (3 * YEAR))) / 30 days;
    }

    function _transfers(
        address user,
        uint256 toTransferKON,
        uint256 toTransferUSDT
    ) private {
        require(toTransferKON > 0 || toTransferUSDT > 0, "01");
        if (toTransferKON > 0) {
            require(
                KON.balanceOf(address(this)) -
                    stakedSum() -
                    inactiveTokensInPool >=
                    toTransferKON,
                "02"
            );
            KON.safeTransfer(user, toTransferKON);
        }

        if (toTransferUSDT > 0) {
            require(
                rewardToken.balanceOf(address(this)) >= toTransferUSDT,
                "03"
            );
            rewardToken.safeTransfer(user, toTransferUSDT);
        }
    }

    function _updateTotalStaked(
        uint256 amount,
        uint256 lockUp,
        uint256 index
    ) private {
        totalStaked[lockUp] -= amount;
        if (weight[weightForDeposit[index]] == PERCENTS_BASE)
            poolFullWeight -= amount;
        else
            poolReducedWeight -= ((amount * weight[weightForDeposit[index]]) /
                PERCENTS_BASE);
    }

    function _harvest(uint256 index) private returns (uint256, uint256) {
        DepositInfo storage stake = allDeposits[index];
        RewardPool_3 storage reward = reward3Info[index];
        require(stake.sumInLock != 0, "1");
        (uint256 year, uint256 months) = _amountOfYears(stake.enteredAt);
        IntVars memory vars;
        if (stake.lockUp == 2 && year >= 3) {
            require(months >= reward.variableRewardTaken, "2");
            if (reward.part == 0) reward.part = fixedPart(index) / 6;
            if (reward.variableRewardTaken < 6) {
                if (months > 5) {
                    vars.amountKON =
                        reward.part *
                        (6 - reward.variableRewardTaken);
                } else
                    vars.amountKON =
                        reward.part *
                        (months + 1 - reward.variableRewardTaken);
            }
            reward.variableRewardTaken = months + 1;
        }
        if (
            (stake.lockUp < 2 &&
                (stake.pool >= stake.lockUp + 1 || year == stake.pool)) ||
            (stake.lockUp == 2 &&
                ((year < 3 && year == stake.pool) || stake.pool == 4))
        ) {
            vars.rewardsKON += stake.varKoeff.unreceivedRewardKON;
            vars.rewardsUSDT += stake.varKoeff.unreceivedRewardUSDT;
        } else {
            (vars.rewardsKON, vars.rewardsUSDT) = varPart(index);
            if (
                stake.lockUp < 2 ||
                (stake.lockUp == 2 && months > 11 && stake.pool != 4)
            ) stake.pool += 1;

            if (
                (stake.lockUp < 2 && stake.lockUp + 1 == stake.pool) ||
                (stake.lockUp == 2 && stake.pool == 4)
            ) {
                _updateTotalStaked(stake.sumInLock, stake.lockUp, index);
                inactiveTokensInPool += stake.sumInLock;
            }
        }
        if (
            stake.lockUp < 2 &&
            stake.pool >= stake.lockUp + 1 &&
            !stake.gotFixed
        ) {
            vars.amountKON = fixedPart(index);
            stake.gotFixed = true;
        }

        stake.varKoeff.receivedRewardKON += vars.rewardsKON;
        stake.varKoeff.receivedRewardUSDT += vars.rewardsUSDT;
        stake.varKoeff.unreceivedRewardKON = 0;
        stake.varKoeff.unreceivedRewardUSDT = 0;
        if (year <= stake.lockUp + 1) stake.countHarvest = year;
        else stake.countHarvest = stake.lockUp + 1;
        vars.rewardsKON += vars.amountKON;

        return (vars.rewardsKON, vars.rewardsUSDT);
    }
}