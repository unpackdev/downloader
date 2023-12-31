// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
pragma abicoder v2;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

import "./IMultiFeeDistribution.sol";
import "./ILockerList.sol";
import "./LockedBalance.sol";
import "./IWETH.sol";
import "./console2.sol";

/// @title Multi Fee Distribution Contract
/// @author Gamma
/// @dev All function calls are currently implemented without side effects

contract MultiFeeDistribution is
    IMultiFeeDistribution,
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /********************** Constants ***********************/

    /// @notice Default lock index
    uint256 public constant DEFAULT_LOCK_INDEX = 1;

    /// @notice Duration of lock/earned penalty period, used for earnings
    uint256 public defaultLockDuration;

    uint256 public basePenaltyPercentage; //  25%
    uint256 public timePenaltyFraction; //  65%
    uint256 public constant WHOLE = 100000; // 100%

    /********************** Contract Addresses ***********************/

    /// @notice Address of LP token
    address public override stakingToken;

    address public treasury;

    /// @notice weth address
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    /********************** Lock & Earn Info ***********************/

    // Private mappings for balance data
    mapping(address => Balances) private balances;
    mapping(address => LockedBalance[]) internal userLocks;
    mapping(address => uint256) public lastAutocompound;

    /// @notice Total locked value
    uint256 public lockedSupply;

    /// @notice Total locked value in multipliers
    uint256 public lockedSupplyWithMultiplier;

    // Time lengths
    uint256[] internal lockPeriod;

    // Multipliers
    uint256[] internal rewardMultipliers;

    /********************** Reward Info ***********************/

    /// @notice Reward tokens being distributed
    address[] public rewardTokens;

    /// @notice Reward data per token
    mapping(address => Reward) public rewardData;

    /// @notice user -> reward token -> rpt; RPT for paid amount
    mapping(address => mapping(address => uint256))
        public userRewardPerTokenPaid;

    /// @notice user -> reward token -> amount; used to store reward amount
    mapping(address => mapping(address => uint256)) public rewards;

    /********************** Other Info ***********************/

    /// @notice treasury wallet
    address public startfleetTreasury;

    /// @notice Addresses approved to call mint
    mapping(address => bool) public minters;

    // Addresses to relock
    mapping(address => bool) public override autoRelockDisabled;

    // Default lock index for relock
    mapping(address => uint256) public override defaultLockIndex;

    /// @notice Flag to prevent more minter addings
    bool public mintersAreSet;

    /// @notice Users list
    ILockerList public userlist;

    /// @notice Last claim time of the user
    mapping(address => uint256) public lastClaimTime;

    /// @notice Bounty manager contract
    address public bountyManager;

    // to prevent unbounded lock length iteration during withdraw/clean

    /********************** Events ***********************/

    // event Staked(address indexed user, uint256 amount, bool locked);
    event Locked(
        address indexed user,
        uint256 amount,
        uint256 lockedBalance
    );
    event Withdrawn(
        address indexed user,
        uint256 receivedAmount,
        uint256 lockedBalance,
        uint256 penalty,
        uint256 burn
    );
    event RewardPaid(
        address indexed user,
        address indexed rewardToken,
        uint256 reward
    );
    event Recovered(address indexed token, uint256 amount);
    event Relocked(address indexed user, uint256 amount, uint256 lockIndex);

    /********************** Errors ***********************/
    error AddressZero();
    error AmountZero();
    error InvalidBurn();
    error InvalidLookback();
    error MintersSet();
    error InvalidLockPeriod();
    error InsufficientPermission();
    error AlreadyAdded();
    error InvalidType();
    error ActiveReward();
    error InvalidAmount();
    error InvalidPeriod();

    /**
     * @dev Constructor
     */
    function initialize(
        address _userlist,
        uint128 _basePenaltyPercentage,
        uint128 _timePenaltyFraction
    ) public initializer {
        __Ownable_init();
        if (_userlist == address(0)) revert AddressZero();

        userlist = ILockerList(_userlist);
        basePenaltyPercentage = _basePenaltyPercentage;
        timePenaltyFraction = _timePenaltyFraction;
    }

    /********************** Setters ***********************/

    /**
     * @notice Set basePenaltyPercentage
     * @dev Only owner can call
     */

    function setPenaltyCalcAttributes(uint256 _basePenaltyPercentage, uint256 _timePenaltyFraction) external onlyOwner {
        basePenaltyPercentage = _basePenaltyPercentage;
        timePenaltyFraction = _timePenaltyFraction;
    }

    /**
     * @notice Set minters
     * @dev Can be called only once
     * @param _minters array of address
     */
    function setMinters(address[] calldata _minters) external onlyOwner {
        if (mintersAreSet) revert MintersSet();
        uint256 length = _minters.length;
        for (uint256 i; i < length; ) {
            if (_minters[i] == address(0)) revert AddressZero();
            minters[_minters[i]] = true;
            unchecked {
                i++;
            }
        }
        mintersAreSet = true;
    }

    /**
     * @notice Add a new reward token to be distributed to stakers.
     * @param _lockPeriod lock period array
     * @param _rewardMultipliers multipliers per lock period
     */
    function setLockTypeInfo(
        uint256[] calldata _lockPeriod,
        uint256[] calldata _rewardMultipliers
    ) external onlyOwner {
        if (_lockPeriod.length != _rewardMultipliers.length)
            revert InvalidLockPeriod();
        delete lockPeriod;
        delete rewardMultipliers;
        uint256 length = _lockPeriod.length;
        for (uint256 i; i < length; ) {
            lockPeriod.push(_lockPeriod[i]);
            rewardMultipliers.push(_rewardMultipliers[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Set staking token.
     * @param _stakingToken staking token address
     */
    function setStakingToken(address _stakingToken) external onlyOwner {
        if (_stakingToken == address(0)) revert AddressZero();
        if (stakingToken != address(0)) revert AddressZero();
        stakingToken = _stakingToken;
    }

    /**
     * @notice Set relock status
     * @param _status true if auto relock is enabled.
     */
    function setRelock(bool _status) external virtual {
        autoRelockDisabled[msg.sender] = !_status;
    }

    /**
     * @notice Set treasury address
     * @param _treasury treasury address
     */
    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    /**
     * @notice Add a new reward token to be distributed to stakers.
     * @param _rewardToken address
     */
    function addReward(address _rewardToken) external override {
        if (_rewardToken == address(0)) revert InvalidBurn();
        if (!minters[msg.sender]) revert InsufficientPermission();
        if (rewardData[_rewardToken].lastUpdateTime != 0) revert AlreadyAdded();
        rewardTokens.push(_rewardToken);

        Reward storage reward = rewardData[_rewardToken];
        reward.lastUpdateTime = block.timestamp;
    }

    /********************** View functions ***********************/

    /**
     * @notice Set default lock type index for user relock.
     * @param _index of default lock length
     */
    function setDefaultRelockTypeIndex(uint256 _index) external override {
        if (_index >= lockPeriod.length) revert InvalidType();
        defaultLockIndex[msg.sender] = _index;
    }

    /**
     * @notice Return lock duration.
     */
    function getLockDurations() external view returns (uint256[] memory) {
        return lockPeriod;
    }

    /**
     * @notice Return reward multipliers.
     */
    function getLockMultipliers() external view returns (uint256[] memory) {
        return rewardMultipliers;
    }

    /**
     * @notice Returns all locks of a user.
     * @param user address.
     * @return lockInfo of the user.
     */
    function lockInfo(
        address user
    ) external view override returns (LockedBalance[] memory) {
        return userLocks[user];
    }

    /**
     * @notice Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders.
     * @param tokenAddress to recover.
     * @param tokenAmount to recover.
     */
    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount
    ) external onlyOwner {
        if (rewardData[tokenAddress].lastUpdateTime != 0) revert ActiveReward();
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
     * @notice Withdraw and restake assets.
     */
    function relock() external virtual {
        uint256 amount = _withdrawExpiredLocksFor(
            msg.sender,
            true,
            true,
            userLocks[msg.sender].length
        );
        _stake(amount, msg.sender, defaultLockIndex[msg.sender], false);
        emit Relocked(msg.sender, amount, defaultLockIndex[msg.sender]);
    }

    /**
     * @notice Total balance of an account, including unlocked, locked and earned tokens.
     * @param user address.
     */
    function totalBalance(
        address user
    ) external view override returns (uint256) {
        return balances[user].locked;
    }

    /**
     * @notice Information on a user's lockings
     * @return total balance of locks
     * @return unlockable balance
     * @return locked balance
     * @return lockedWithMultiplier
     * @return lockData which is an array of locks
     */
    function lockedBalances(
        address user
    )
        public
        view
        override
        returns (
            uint256,
            uint256 unlockable,
            uint256 locked,
            uint256 lockedWithMultiplier,
            LockedBalance[] memory lockData
        )
    {
        LockedBalance[] storage locks = userLocks[user];
        uint256 idx;
        uint256 length = locks.length;
        for (uint256 i; i < length; ) {
            if (locks[i].unlockTime > block.timestamp) {
                if (idx == 0) {
                    lockData = new LockedBalance[](locks.length - i);
                }
                lockData[idx] = locks[i];
                idx++;
                locked = locked.add(locks[i].amount);
                lockedWithMultiplier = lockedWithMultiplier.add(
                    locks[i].amount.mul(locks[i].multiplier)
                );
            } else {
                unlockable = unlockable.add(locks[i].amount);
            }
            unchecked {
                i++;
            }
        }
        return (
            balances[user].locked,
            unlockable,
            locked,
            lockedWithMultiplier,
            lockData
        );
    }

    /**
     * @notice Reward locked amount of the user.
     * @param user address
     * @return locked amount
     */
    function lockedBalance(
        address user
    ) public view returns (uint256 locked) {
        LockedBalance[] storage locks = userLocks[user];
        uint256 length = locks.length;
        for (uint i; i < length; ) {
            if (locks[i].unlockTime > block.timestamp) {
                locked = locked.add(locks[i].amount);
            }
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Total balance of an account, including unlocked, locked and earned tokens.
     */
    function getBalances(
        address _user
    ) external view returns (Balances memory) {
        return balances[_user];
    }

    /********************** Reward functions ***********************/

    /**
     * @notice Address and claimable amount of all reward tokens for the given account.
     * @param account for rewards
     * @return rewardsData array of rewards
     */
    function claimableRewards(
        address account
    )
        public
        view
        override
        returns (IFeeDistribution.RewardData[] memory rewardsData)
    {
        rewardsData = new IFeeDistribution.RewardData[](rewardTokens.length);

        uint256 length = rewardTokens.length;
        for (uint256 i; i < length; ) {
            rewardsData[i].token = rewardTokens[i];
            Reward storage r = rewardData[rewardTokens[i]];

            rewardsData[i].amount = _earned(
                account,
                rewardsData[i].token,
                balances[account].lockedWithMultiplier,
                r.rewardPerTokenStored
            ).div(1e12);
            unchecked {
                i++;
            }
        }
        return rewardsData;
    }

    /********************** Operate functions ***********************/

    /**
     * @notice Stake tokens to receive rewards.
     * @dev Locked tokens cannot be withdrawn for defaultLockDuration and are eligible to receive rewards.
     * @param amount to stake.
     * @param onBehalfOf address for staking.
     * @param typeIndex lock type index.
     */
    function stake(
        uint256 amount,
        address onBehalfOf,
        uint256 typeIndex
    ) external override {
        _stake(amount, onBehalfOf, typeIndex, false);
    }

    /**
     * @notice Stake tokens to receive rewards.
     * @dev Locked tokens cannot be withdrawn for defaultLockDuration and are eligible to receive rewards.
     * @param amount to stake.
     * @param onBehalfOf address for staking.
     * @param typeIndex lock type index.
     * @param isRelock true if this is with relock enabled.
     */
    function _stake(
        uint256 amount,
        address onBehalfOf,
        uint256 typeIndex,
        bool isRelock
    ) internal whenNotPaused {
        if (amount == 0) return;
        if (typeIndex >= lockPeriod.length) revert InvalidAmount();

        _updateReward(onBehalfOf);

        uint256 transferAmount = amount;
        if (userLocks[onBehalfOf].length != 0) {
            //if user has any locks
            if (userLocks[onBehalfOf][0].unlockTime <= block.timestamp) {
                //if users soonest unlock has already elapsed
                if (onBehalfOf == msg.sender) {
                    uint256 withdrawnAmt;
                    if (!autoRelockDisabled[onBehalfOf]) {
                        withdrawnAmt = _withdrawExpiredLocksFor(
                            onBehalfOf,
                            true,
                            false,
                            userLocks[onBehalfOf].length
                        );
                        amount = amount.add(withdrawnAmt);
                    } else {
                        _withdrawExpiredLocksFor(
                            onBehalfOf,
                            true,
                            true,
                            userLocks[onBehalfOf].length
                        );
                    }
                }
            }
        }
        Balances storage bal = balances[onBehalfOf];
        bal.total = bal.total.add(amount);

        bal.locked = bal.locked.add(amount);
        lockedSupply = lockedSupply.add(amount);

        bal.lockedWithMultiplier = bal.lockedWithMultiplier.add(
            amount.mul(rewardMultipliers[typeIndex])
        );
        lockedSupplyWithMultiplier = lockedSupplyWithMultiplier.add(
            amount.mul(rewardMultipliers[typeIndex])
        );
        _insertLock(
            onBehalfOf,
            LockedBalance({
                amount: amount,
                unlockTime: block.timestamp.add(lockPeriod[typeIndex]),
                multiplier: rewardMultipliers[typeIndex],
                duration: lockPeriod[typeIndex]
            })
        );

        userlist.addToList(onBehalfOf);

        if (!isRelock) {
            IERC20(stakingToken).safeTransferFrom(
                msg.sender,
                address(this),
                transferAmount
            );
        }

        emit Locked(
            onBehalfOf,
            amount,
            balances[onBehalfOf].locked
        );
    }

    /**
     * @notice Add new lockings
     * @dev We keep the array to be sorted by unlock time.
     * @param _user address of locker.
     * @param newLock new lock info.
     */
    function _insertLock(address _user, LockedBalance memory newLock) internal {
        LockedBalance[] storage locks = userLocks[_user];
        uint256 length = locks.length;
        uint256 i = _binarySearch(locks, length, newLock.unlockTime);
        locks.push();
        for (uint256 j = length; j > i; j--) {
            locks[j] = locks[j - 1];
        }
        locks[i] = newLock;
    }

    function _binarySearch(
        LockedBalance[] storage locks,
        uint256 length,
        uint256 unlockTime
    ) private view returns (uint256) {
        uint256 low = 0;
        uint256 high = length;
        while (low < high) {
            uint256 mid = (low + high) / 2;
            if (locks[mid].unlockTime < unlockTime) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return low;
    }



    /**
     * @notice Claim all pending staking rewards.
     * @param _rewardTokens array of reward tokens
     */
    function getReward(address[] memory _rewardTokens) public nonReentrant {
        _updateReward(msg.sender);
        _getReward(msg.sender, _rewardTokens);
    }

    function notifyUnseenReward() external {
        uint256 length = rewardTokens.length;
        for (uint256 i; i < length; ) {
            address token = rewardTokens[i];
            _notifyUnseenReward(token);
            unchecked {
                i++;
            }
        }
    }
    /**
     * @notice Claim all pending staking rewards.
     */
    function getAllRewards() external {
        return getReward(rewardTokens);
    }

    /**
     * @notice Withdraw full unlocked balance and earnings.
     */
    function earlyExit() external {
        _updateReward(msg.sender);
        uint256 penaltyAmount = calcPenaltyReward(msg.sender);

        Balances storage bal = balances[msg.sender];
        uint256 total = bal.total;
        bal.total = 0;
        bal.lockedWithMultiplier = 0;
        bal.locked = 0;

        delete userLocks[msg.sender];
        userlist.removeFromList(msg.sender);

        IERC20(stakingToken).safeTransfer(msg.sender, total - penaltyAmount);
        IERC20(stakingToken).safeTransfer(treasury, penaltyAmount);
    }

    /**
     * @notice Withdraw full unlocked balance and earnings by index.
     */
    function earlyExitByIndex(uint256 index) external {
        console2.log('index', userLocks[msg.sender].length, index);
        _updateReward(msg.sender);
        uint256 penaltyAmount = calcPenaltyRewardByIndex(msg.sender, index);

        LockedBalance[] storage userLock = userLocks[msg.sender];
        Balances storage bal = balances[msg.sender];
        bal.total -= penaltyAmount;
        bal.lockedWithMultiplier -= userLock[index].multiplier;
        bal.locked = 0;
        uint256 withdrawAmount = userLock[index].amount;

        userLock[index].amount = 0;
        userLock[index].unlockTime = 0;
        userLock[index].multiplier = 0;
        userLock[index].duration = 0;

        IERC20(stakingToken).safeTransfer(msg.sender, withdrawAmount - penaltyAmount);
        IERC20(stakingToken).safeTransfer(treasury, penaltyAmount);
    }

    /**
     * @notice Calculate earnings.
     * @param _user address of earning owner
     * @param _rewardToken address
     * @param _balance of the user
     * @param _currentRewardPerToken current RPT
     * @return earnings amount
     */
    function _earned(
        address _user,
        address _rewardToken,
        uint256 _balance,
        uint256 _currentRewardPerToken
    ) internal view returns (uint256 earnings) {
        earnings = rewards[_user][_rewardToken];
        uint256 realRPT = _currentRewardPerToken.sub(
            userRewardPerTokenPaid[_user][_rewardToken]
        );
        if (_balance > 0 && realRPT > 0)
            earnings = earnings.add(_balance.mul(realRPT).div(1e12));
    }

    /**
     * @notice Update user reward info.
     * @param account address
     */
    function _updateReward(address account) internal {
        uint256 balance = balances[account].lockedWithMultiplier;
        uint256 length = rewardTokens.length;
        for (uint256 i = 0; i < length; ) {
            address token = rewardTokens[i];

            Reward storage r = rewardData[token];
            if (account != address(this)) {
                rewards[account][token] = _earned(account, token, balance, r.rewardPerTokenStored);
                userRewardPerTokenPaid[account][token] = r.rewardPerTokenStored;
            }
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Add new reward.
     * @dev If prev reward period is not done, then it resets `rewardPerSecond` and restarts period
     * @param _rewardToken address
     * @param reward amount
     */
    function _notifyReward(address _rewardToken, uint256 reward) internal {
        Reward storage r = rewardData[_rewardToken];
        r.rewardPerTokenStored += reward.mul(1e12).div(lockedSupplyWithMultiplier);
        r.lastUpdateTime = block.timestamp;
        r.balance = r.balance.add(reward);
    }

    /**
     * @notice Notify unseen rewards.
     * @dev for rewards other than stakingToken, every 24 hours we check if new
     *  rewards were sent to the contract or accrued via aToken interest.
     * @param token address
     */
    function _notifyUnseenReward(address token) internal {
        if (token == address(0)) revert AddressZero();
        Reward storage r = rewardData[token];
        uint256 unseen;
        if (token == ETH_ADDRESS) {
            unseen = address(this).balance - r.balance;
        } else {
            unseen = IERC20(token).balanceOf(address(this)).sub(
                r.balance
            );
        }
        if (unseen > 0) {
            _notifyReward(token, unseen);
        }
    }

    function onUpgrade() public {}

    /**
     * @notice User gets reward
     * @param _user address
     * @param _rewardTokens array of reward tokens
     */
    function _getReward(
        address _user,
        address[] memory _rewardTokens
    ) internal whenNotPaused {
        uint256 length = _rewardTokens.length;
        for (uint256 i; i < length; ) {
            address token = _rewardTokens[i];
            _notifyUnseenReward(token);
            uint256 reward = rewards[_user][token];
            if (reward > 0) {
                rewards[_user][token] = 0;
                rewardData[token].balance = rewardData[token].balance.sub(
                    reward
                );

                // wrap eth for reward
                // TODO: release native ETH
                if (token == ETH_ADDRESS) {
                    IWETH(WETH).deposit{value: reward}();
                    IWETH(WETH).transfer(_user, reward);
                } else {
                    IERC20(token).safeTransfer(_user, reward);
                }
                // TODO: ask if bulk event is possible. Roughly 50% cheaper
                emit RewardPaid(_user, token, reward);
            }
            unchecked {
                i++;
            }
        }
    }

    /********************** Eligibility + Disqualification ***********************/

    /**
     * @notice Withdraw all lockings tokens where the unlock time has passed
     * @param user address
     * @param totalLock total lock amount
     * @param totalLockWithMultiplier total lock amount that is multiplied
     * @param limit limit for looping operation
     * @return lockAmount withdrawable lock amount
     * @return lockAmountWithMultiplier withdraw amount with multiplier
     */
    function _cleanWithdrawableLocks(
        address user,
        uint256 totalLock,
        uint256 totalLockWithMultiplier,
        uint256 limit
    ) internal returns (uint256 lockAmount, uint256 lockAmountWithMultiplier) {
        LockedBalance[] storage locks = userLocks[user];

        if (locks.length != 0) {
            uint256 length = locks.length <= limit ? locks.length : limit;
            uint256 i;
            while (i < length && locks[i].unlockTime <= block.timestamp) {
                lockAmount = lockAmount.add(locks[i].amount);
                lockAmountWithMultiplier = lockAmountWithMultiplier.add(
                    locks[i].amount.mul(locks[i].multiplier)
                );
                i = i + 1;
            }
            for (uint256 j = i; j < locks.length; j = j + 1) {
                locks[j - i] = locks[j];
            }
            for (uint256 j = 0; j < i; j = j + 1) {
                locks.pop();
            }
            if (locks.length == 0) {
                lockAmount = totalLock;
                lockAmountWithMultiplier = totalLockWithMultiplier;
                delete userLocks[user];

                userlist.removeFromList(user);
            }
        }
    }
    
    /**
     * @notice Final balance received and penalty balance paid by user upon calling exit.
     * @dev This is earnings, not locks.
     */
    function calcPenaltyReward(address user)
        public
        view
        returns (
            uint256 penaltyAmount
        )
    {
        uint256 locked = balances[user].locked;
        if (locked > 0) {
            uint256 length = userLocks[user].length;
            for (uint256 i; i < length; i++) {
                uint256 penaltyAmountByIndex = calcPenaltyRewardByIndex(user, i);

                penaltyAmount += penaltyAmountByIndex;
            }
        }
    }

    function calcPenaltyRewardByIndex(address user, uint256 index) internal view returns (uint256 penaltyAmount) {
        LockedBalance memory userLock = userLocks[user][index];
        if (userLock.amount == 0) return 0;
        uint256 unlockTime = userLock.unlockTime;
        uint256 penaltyFactor;
        if (unlockTime > block.timestamp) {
            // 90% on day 1, decays to 25% on last day
            penaltyFactor = unlockTime
                .sub(block.timestamp)
                .mul(timePenaltyFraction)
                .div(userLock.duration)
                .add(basePenaltyPercentage); // 15% + timeLeft/duration * 35%
        }

        penaltyAmount = userLock.amount.mul(penaltyFactor).div(WHOLE);        
    }

    /**
     * @notice Withdraw all currently locked tokens where the unlock time has passed.
     * @param _address of the user.
     * @param isRelockAction true if withdraw with relock
     * @param doTransfer true to transfer tokens to user
     * @param limit limit for looping operation
     * @return amount for withdraw
     */
    function _withdrawExpiredLocksFor(
        address _address,
        bool isRelockAction,
        bool doTransfer,
        uint256 limit
    ) internal whenNotPaused returns (uint256 amount) {
        require(
            isRelockAction == false ||
                _address == msg.sender
        );
        _updateReward(_address);
        uint256 amountWithMultiplier;
        Balances storage bal = balances[_address];

        (amount, amountWithMultiplier) = _cleanWithdrawableLocks(
            _address,
            bal.locked,
            bal.lockedWithMultiplier,
            limit
        );
        bal.locked = bal.locked.sub(amount);
        bal.lockedWithMultiplier = bal.lockedWithMultiplier.sub(
            amountWithMultiplier
        );
        bal.total = bal.total.sub(amount);
        lockedSupply = lockedSupply.sub(amount);
        lockedSupplyWithMultiplier = lockedSupplyWithMultiplier.sub(
            amountWithMultiplier
        );

        if (!isRelockAction && !autoRelockDisabled[_address]) {
            _stake(amount, _address, defaultLockIndex[_address], true);
        } else {
            if (doTransfer) {
                IERC20(stakingToken).safeTransfer(_address, amount);
                emit Withdrawn(
                    _address,
                    amount,
                    balances[_address].locked,
                    0,
                    0
                );
            }
        }

        return amount;
    }
    
    /**
     * @notice Withdraw all currently locked tokens where the unlock time has passed.
     * @param _address of the user
     * @return withdraw amount
     */
    function withdrawExpiredLocksFor(
        address _address
    ) external override returns (uint256) {
        return
            _withdrawExpiredLocksFor(
                _address,
                false,
                true,
                userLocks[_address].length
            );
    }

    /**
     * @notice Withdraw expired locks with options
     * @param _address for withdraw
     * @param _limit of lock length for withdraw
     * @param _ignoreRelock option to ignore relock
     * @return withdraw amount
     */
    function withdrawExpiredLocksForWithOptions(
        address _address,
        uint256 _limit,
        bool _ignoreRelock
    ) external returns (uint256) {
        if (_limit == 0) _limit = userLocks[_address].length;

        return _withdrawExpiredLocksFor(_address, _ignoreRelock, true, _limit);
    }

    /**
     * @notice Pause MFD functionalities
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Resume MFD functionalities
     */
    function unpause() public onlyOwner {
        _unpause();
    }

        // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
