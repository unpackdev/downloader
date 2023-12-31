/* 
    - Stake up to X mushrooms per user (dao can change)
    - Reward mushroom yield rate for lifespan
    - When dead, burn mushroom erc721
    - Distribute 5% of ENOKI rewards to Chefs
*/
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";

import "./TokenPool.sol";
import "./Defensible.sol";
import "./MushroomNFT.sol";
import "./MushroomLib.sol";

import "./MushroomMetadata.sol";

/**
 * @title Enoki Geyser
 * @dev A smart-contract based mechanism to distribute tokens over time, inspired loosely by
 *      Compound and Uniswap.
 *
 *      Distribution tokens are added to a locked pool in the contract and become unlocked over time
 *      according to a once-configurable unlock schedule. Once unlocked, they are available to be
 *      claimed by users.
 *
 *      A user may deposit tokens to accrue ownership share over the unlocked pool. This owner share
 *      is a function of the number of tokens deposited as well as the length of time deposited.
 *      Specifically, a user's share of the currently-unlocked pool equals their "deposit-seconds"
 *      divided by the global "deposit-seconds". This aligns the new token distribution with long
 *      term supporters of the project, addressing one of the major drawbacks of simple airdrops.
 *
 *      More background and motivation available at:
 *      https://github.com/ampleforth/RFCs/blob/master/RFCs/rfc-1.md
 */
contract EnokiGeyser is Initializable, OwnableUpgradeSafe, Defensible {
    using SafeMath for uint256;
    using MushroomLib for MushroomLib.MushroomData;
    using MushroomLib for MushroomLib.MushroomType;

    event Staked(address indexed user, address nftContract, uint256 nftId, uint256 total, bytes data);
    event Unstaked(address indexed user, address nftContract, uint256 nftId, uint256 total, bytes data);
    event TokensClaimed(address indexed user, uint256 amount);
    event TokensLocked(uint256 amount, uint256 durationSec, uint256 total);
    // amount: Unlocked tokens, total: Total locked tokens
    event TokensUnlocked(uint256 amount, uint256 total);

    TokenPool private _unlockedPool;
    TokenPool private _lockedPool;

    MushroomMetadata public mushroomMetadata;

    //
    // Time-bonus params
    //
    uint256 public constant BONUS_DECIMALS = 2;
    uint256 public startBonus = 0;
    uint256 public bonusPeriodSec = 0;

    uint256 public maxStakesPerAddress = 0;

    //
    // Global accounting state
    //
    uint256 public totalLockedShares = 0;
    uint256 public totalStakingShares = 0;
    uint256 public totalStrengthStaked = 0;
    uint256 private _totalStakingShareSeconds = 0;
    uint256 private _lastAccountingTimestampSec = now;
    uint256 private _maxUnlockSchedules = 0;
    uint256 private _initialSharesPerToken = 0;

    //
    // Dev reward state
    //
    uint256 public constant MAX_PERCENTAGE = 100;
    uint256 public devRewardPercentage = 0; //0% - 100%
    address public devRewardAddress;

    address public admin;
    ApprovedContractList public approvedContractList;

    //
    // User accounting state
    //
    // Represents a single stake for a user. A user may have multiple.
    struct Stake {
        address nftContract;
        uint256 nftIndex;
        uint256 stakingShares;
        uint256 timestampSec;
    }

    // Caches aggregated values from the User->Stake[] map to save computation.
    // If lastAccountingTimestampSec is 0, there's no entry for that user.
    struct UserTotals {
        uint256 stakingShares;
        uint256 stakingShareSeconds;
        uint256 lastAccountingTimestampSec;
    }

    // Aggregated staking values per user
    mapping(address => UserTotals) private _userTotals;

    // The collection of stakes for each user. Ordered by timestamp, earliest to latest.
    mapping(address => Stake[]) private _userStakes;

    //
    // Locked/Unlocked Accounting state
    //
    struct UnlockSchedule {
        uint256 initialLockedShares;
        uint256 unlockedShares;
        uint256 lastUnlockTimestampSec;
        uint256 endAtSec;
        uint256 durationSec;
    }

    UnlockSchedule[] public unlockSchedules;

    /**
     * @param distributionToken The token users receive as they unstake.
     * @param maxUnlockSchedules Max number of unlock stages, to guard against hitting gas limit.
     * @param startBonus_ Starting time bonus, BONUS_DECIMALS fixed point.
     *                    e.g. 25% means user gets 25% of max distribution tokens.
     * @param bonusPeriodSec_ Length of time for bonus to increase linearly to max.
     * @param initialSharesPerToken Number of shares to mint per staking token on first stake.
     * @param maxStakesPerAddress_ Maximum number of NFTs stakeable by a given account.
     * @param devRewardAddress_ Recipient address of dev rewards.
     * @param devRewardPercentage_ Pecentage of rewards claimed to be distributed for dev address.

     */
    function initialize(
        IERC20 distributionToken,
        uint256 maxUnlockSchedules,
        uint256 startBonus_,
        uint256 bonusPeriodSec_,
        uint256 initialSharesPerToken,
        uint256 maxStakesPerAddress_,
        address devRewardAddress_,
        uint256 devRewardPercentage_,
        address approvedContractList_,
        address admin_
    ) public initializer {
        // The start bonus must be some fraction of the max. (i.e. <= 100%)
        require(startBonus_ <= 10**BONUS_DECIMALS, "EnokiGeyser: start bonus too high");
        // If no period is desired, instead set startBonus = 100%
        // and bonusPeriod to a small value like 1sec.
        require(bonusPeriodSec_ != 0, "EnokiGeyser: bonus period is zero");
        require(initialSharesPerToken > 0, "EnokiGeyser: initialSharesPerToken is zero");

        // The dev reward must be some fraction of the max. (i.e. <= 100%)
        require(devRewardPercentage_ <= MAX_PERCENTAGE, "EnokiGeyser: dev reward too high");
        
        __Ownable_init();

        _unlockedPool = new TokenPool(distributionToken);
        _lockedPool = new TokenPool(distributionToken);
        startBonus = startBonus_;
        bonusPeriodSec = bonusPeriodSec_;
        _maxUnlockSchedules = maxUnlockSchedules;
        _initialSharesPerToken = initialSharesPerToken;
        maxStakesPerAddress = maxStakesPerAddress_;

        devRewardPercentage = devRewardPercentage_;
        devRewardAddress = devRewardAddress_;

        admin = admin_;

        approvedContractList = ApprovedContractList(approvedContractList_);
    }

    // TODO: Add a method for per-index staking access
    function isNftStakeable(address nftContract) public view returns (bool) {
        return mushroomMetadata.hasMetadataResolver(nftContract);
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, "EnokiGeyser: Only Admin");
        _;
    }

    // Only effects future stakes
    function setMaxStakesPerAddress(uint256 maxStakes) public onlyAdmin {
        maxStakesPerAddress = maxStakes;
    }

    function setMushroomMetadata(address mushroomMetadata_) public onlyAdmin {
        mushroomMetadata = MushroomMetadata(mushroomMetadata_);
    }

    /**
     * @return The token users receive as they unstake.
     */
    function getDistributionToken() public view returns (IERC20) {
        assert(_unlockedPool.token() == _lockedPool.token());
        return _unlockedPool.token();
    }

    /**
     * @dev Transfers amount of deposit tokens from the user.
     * @param data Not used.
     */
    function stake(
        address nftContract,
        uint256 nftIndex,
        bytes calldata data
    ) external defend(approvedContractList) {
        require(isNftStakeable(nftContract), "EnokiGeyser: nft not stakeable");
        _stakeFor(msg.sender, msg.sender, nftContract, nftIndex);
    }

    /**
     * @dev Private implementation of staking methods.
     * @param staker User address who deposits tokens to stake.
     * @param beneficiary User address who gains credit for this stake operation.
     */
    function _stakeFor(
        address staker,
        address beneficiary,
        address nftContract,
        uint256 nftIndex
    ) private {
        require(beneficiary != address(0), "EnokiGeyser: beneficiary is zero address");
        require(totalStakingShares == 0 || totalStaked() > 0, "EnokiGeyser: Invalid state. Staking shares exist, but no staking tokens do");
        require(isNftStakeable(nftContract), "EnokiGeyser: Nft contract specified not stakeable");

        // Shares is determined by NFT mushroom rate

        MushroomLib.MushroomData memory metadata = mushroomMetadata.getMushroomData(nftContract, nftIndex, "");

        uint256 mintedStakingShares = (totalStakingShares > 0)
            ? totalStakingShares.mul(metadata.strength).div(totalStaked())
            : metadata.strength.mul(_initialSharesPerToken);
        require(mintedStakingShares > 0, "EnokiGeyser: Stake amount is too small");

        updateAccounting();

        // 1. User Accounting
        UserTotals storage totals = _userTotals[beneficiary];
        totals.stakingShares = totals.stakingShares.add(mintedStakingShares);
        totals.lastAccountingTimestampSec = now;

        Stake memory newStake = Stake(nftContract, nftIndex, mintedStakingShares, now);
        _userStakes[beneficiary].push(newStake);

        require(_userStakes[beneficiary].length <= maxStakesPerAddress, "EnokiGeyser: Stake would exceed maximum stakes for address");

        // 2. Global Accounting
        totalStakingShares = totalStakingShares.add(mintedStakingShares);
        // Already set in updateAccounting()
        // _lastAccountingTimestampSec = now;

        // interactions - rather than taking staking tokens, we take the NFT and track the amount staked locally
        // require(_stakingPool.token().transferFrom(staker, address(_stakingPool), amount), "EnokiGeyser: transfer into staking pool failed");

        totalStrengthStaked = totalStrengthStaked.add(metadata.strength);
        IERC721(nftContract).transferFrom(staker, address(this), nftIndex);

        emit Staked(beneficiary, nftContract, nftIndex, totalStakedFor(beneficiary), "");
    }

    /**
     * @dev Unstakes a certain amount of previously deposited tokens. User also receives their
     * alotted number of distribution tokens.
     * @param stakes Mushrooms to unstake.
     * @param data Not used.
     */
    function unstake(uint256[] calldata stakes, bytes calldata data) external {
        _unstake(stakes);
    }

    /**
     * @param stakes Mushrooms to unstake.
     */
    function unstakeQuery(uint256[] memory stakes)
        public
        returns (
            uint256 totalReward,
            uint256 userReward,
            uint256 devReward
        )
    {
        return _unstake(stakes);
    }

    /**
     * @dev Unstakes a certain amount of previously deposited tokens. User also receives their
     * alotted number of distribution tokens.
     * @param stakes Mushrooms to unstake.
     */
    function _unstake(uint256[] memory stakes)
        private
        returns (
            uint256 totalReward,
            uint256 userReward,
            uint256 devReward
        )
    {
        updateAccounting();

        // 1. User Accounting
        UserTotals storage totals = _userTotals[msg.sender];
        Stake[] storage accountStakes = _userStakes[msg.sender];

        // Redeem from most recent stake and go backwards in time.
        uint256 rewardAmount = 0;

        for (uint256 i = 0; i < stakes.length; i++) {
            Stake storage lastStake = accountStakes[i];

            MushroomLib.MushroomData memory metadata = mushroomMetadata.getMushroomData(lastStake.nftContract, lastStake.nftIndex, "");
            uint256 lifespanUsed = now.sub(lastStake.timestampSec);

            // fully redeem a past stake
            uint256 stakingShareSecondsToBurn = lastStake.stakingShares.mul(lifespanUsed);
            rewardAmount = computeNewReward(rewardAmount, stakingShareSecondsToBurn, lifespanUsed);

            bool toBurn = false;

            if (metadata.lifespan <= lifespanUsed) {
                lifespanUsed = metadata.lifespan;
                toBurn = true;
            }

            // Update global aomunt staked
            totalStrengthStaked = totalStrengthStaked.sub(metadata.strength);

            if (toBurn) {
                // Burn dead mushrooms
                MushroomNFT(lastStake.nftContract).burn(lastStake.nftIndex);
            } else {
                // If still alive, reduce lifespan of mushroom and return to user
                mushroomMetadata.setMushroomLifespan(lastStake.nftContract, lastStake.nftIndex, metadata.lifespan.sub(lifespanUsed), "");
                IERC721(lastStake.nftContract).transferFrom(address(this), msg.sender, lastStake.nftIndex);
            }

            totals.stakingShareSeconds = totals.stakingShareSeconds.sub(stakingShareSecondsToBurn);
            totals.stakingShares = totals.stakingShares.sub(lastStake.stakingShares);

            // 2. Global Accounting
            _totalStakingShareSeconds = _totalStakingShareSeconds.sub(stakingShareSecondsToBurn);
            totalStakingShares = totalStakingShares.sub(lastStake.stakingShares);

            accountStakes.pop();
            emit Unstaked(msg.sender, lastStake.nftContract, lastStake.nftIndex, totalStakedFor(msg.sender), "");
        }

        // Already set in updateAccounting
        // _lastAccountingTimestampSec = now;

        // interactions
        totalReward = rewardAmount;
        (userReward, devReward) = computeDevReward(totalReward);
        if (userReward > 0) {
            require(_unlockedPool.transfer(msg.sender, userReward), "EnokiGeyser: transfer to user out of unlocked pool failed");
        }

        if (devReward > 0) {
            require(_unlockedPool.transfer(devRewardAddress, devReward), "EnokiGeyser: transfer to dev out of unlocked pool failed");
        }

        emit TokensClaimed(msg.sender, rewardAmount);

        require(totalStakingShares == 0 || totalStaked() > 0, "EnokiGeyser: Error unstaking. Staking shares exist, but no staking tokens do");
    }

    /**
     * @dev Applies an additional time-bonus to a distribution amount. This is necessary to
     *      encourage long-term deposits instead of constant unstake/restakes.
     *      The bonus-multiplier is the result of a linear function that starts at startBonus and
     *      ends at 100% over bonusPeriodSec, then stays at 100% thereafter.
     * @param currentRewardTokens The current number of distribution tokens already alotted for this
     *                            unstake op. Any bonuses are already applied.
     * @param stakingShareSeconds The stakingShare-seconds that are being burned for new
     *                            distribution tokens.
     * @param stakeTimeSec Length of time for which the tokens were staked. Needed to calculate
     *                     the time-bonus.
     * @return Updated amount of distribution tokens to award, with any bonus included on the
     *         newly added tokens.
     */
    function computeNewReward(
        uint256 currentRewardTokens,
        uint256 stakingShareSeconds,
        uint256 stakeTimeSec
    ) private view returns (uint256) {
        uint256 newRewardTokens = totalUnlocked().mul(stakingShareSeconds).div(_totalStakingShareSeconds);

        if (stakeTimeSec >= bonusPeriodSec) {
            return currentRewardTokens.add(newRewardTokens);
        }

        uint256 oneHundredPct = 10**BONUS_DECIMALS;
        uint256 bonusedReward = startBonus.add(oneHundredPct.sub(startBonus).mul(stakeTimeSec).div(bonusPeriodSec)).mul(newRewardTokens).div(
            oneHundredPct
        );
        return currentRewardTokens.add(bonusedReward);
    }

    /**
     * @dev Determines split of specified reward amount between user and dev.
     * @param totalReward Amount of reward to split.
     * @return userReward Reward amounts for user and dev.
     * @return devReward Reward amounts for user and dev.
     */
    function computeDevReward(uint256 totalReward) public view returns (uint256 userReward, uint256 devReward) {
        if (devRewardPercentage == 0) {
            userReward = totalReward;
            devReward = 0;
        } else if (devRewardPercentage == MAX_PERCENTAGE) {
            userReward = 0;
            devReward = totalReward;
        } else {
            devReward = totalReward.mul(devRewardPercentage).div(MAX_PERCENTAGE);
            userReward = totalReward.sub(devReward); // Extra dust due to truncated rounding goes to user
        }
    }

    /**
     * @param addr The user to look up staking information for.
     * @return The number of staking tokens deposited for addr.
     */
    function totalStakedFor(address addr) public view returns (uint256) {
        return totalStakingShares > 0 ? totalStaked().mul(_userTotals[addr].stakingShares).div(totalStakingShares) : 0;
    }

    /**
     * @return The total number of deposit tokens staked globally, by all users.
     */
    function totalStaked() public view returns (uint256) {
        return totalStrengthStaked;
    }

    /**
     * @dev A globally callable function to update the accounting state of the system.
     *      Global state and state for the caller are updated.
     * @return [0] balance of the locked pool
     * @return [1] balance of the unlocked pool
     * @return [2] caller's staking share seconds
     * @return [3] global staking share seconds
     * @return [4] Rewards caller has accumulated, optimistically assumes max time-bonus.
     * @return [5] block timestamp
     */
    function updateAccounting()
        public
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        unlockTokens();

        // Global accounting
        uint256 newStakingShareSeconds = now.sub(_lastAccountingTimestampSec).mul(totalStakingShares);
        _totalStakingShareSeconds = _totalStakingShareSeconds.add(newStakingShareSeconds);
        _lastAccountingTimestampSec = now;

        // User Accounting
        UserTotals storage totals = _userTotals[msg.sender];
        uint256 newUserStakingShareSeconds = now.sub(totals.lastAccountingTimestampSec).mul(totals.stakingShares);
        totals.stakingShareSeconds = totals.stakingShareSeconds.add(newUserStakingShareSeconds);
        totals.lastAccountingTimestampSec = now;

        uint256 totalUserRewards = (_totalStakingShareSeconds > 0)
            ? totalUnlocked().mul(totals.stakingShareSeconds).div(_totalStakingShareSeconds)
            : 0;

        return (totalLocked(), totalUnlocked(), totals.stakingShareSeconds, _totalStakingShareSeconds, totalUserRewards, now);
    }

    /**
     * @return Total number of locked distribution tokens.
     */
    function totalLocked() public view returns (uint256) {
        return _lockedPool.balance();
    }

    /**
     * @return Total number of unlocked distribution tokens.
     */
    function totalUnlocked() public view returns (uint256) {
        return _unlockedPool.balance();
    }

    /**
     * @return Number of unlock schedules.
     */
    function unlockScheduleCount() public view returns (uint256) {
        return unlockSchedules.length;
    }

    /**
     * @dev This funcion allows the contract owner to add more locked distribution tokens, along
     *      with the associated "unlock schedule". These locked tokens immediately begin unlocking
     *      linearly over the duraction of durationSec timeframe.
     * @param amount Number of distribution tokens to lock. These are transferred from the caller.
     * @param durationSec Length of time to linear unlock the tokens.
     */
    function lockTokens(uint256 amount, uint256 durationSec) external onlyOwner {
        require(unlockSchedules.length < _maxUnlockSchedules, "EnokiGeyser: reached maximum unlock schedules");

        // Update lockedTokens amount before using it in computations after.
        updateAccounting();

        uint256 lockedTokens = totalLocked();
        uint256 mintedLockedShares = (lockedTokens > 0) ? totalLockedShares.mul(amount).div(lockedTokens) : amount.mul(_initialSharesPerToken);

        UnlockSchedule memory schedule;
        schedule.initialLockedShares = mintedLockedShares;
        schedule.lastUnlockTimestampSec = now;
        schedule.endAtSec = now.add(durationSec);
        schedule.durationSec = durationSec;
        unlockSchedules.push(schedule);

        totalLockedShares = totalLockedShares.add(mintedLockedShares);

        require(_lockedPool.token().transferFrom(msg.sender, address(_lockedPool), amount), "EnokiGeyser: transfer into locked pool failed");
        emit TokensLocked(amount, durationSec, totalLocked());
    }

    /**
     * @dev Moves distribution tokens from the locked pool to the unlocked pool, according to the
     *      previously defined unlock schedules. Publicly callable.
     * @return Number of newly unlocked distribution tokens.
     */
    function unlockTokens() public returns (uint256) {
        uint256 unlockedTokens = 0;
        uint256 lockedTokens = totalLocked();

        if (totalLockedShares == 0) {
            unlockedTokens = lockedTokens;
        } else {
            uint256 unlockedShares = 0;
            for (uint256 s = 0; s < unlockSchedules.length; s++) {
                unlockedShares = unlockedShares.add(unlockScheduleShares(s));
            }
            unlockedTokens = unlockedShares.mul(lockedTokens).div(totalLockedShares);
            totalLockedShares = totalLockedShares.sub(unlockedShares);
        }

        if (unlockedTokens > 0) {
            require(_lockedPool.transfer(address(_unlockedPool), unlockedTokens), "EnokiGeyser: transfer out of locked pool failed");
            emit TokensUnlocked(unlockedTokens, totalLocked());
        }

        return unlockedTokens;
    }

    /**
     * @dev Returns the number of unlockable shares from a given schedule. The returned value
     *      depends on the time since the last unlock. This function updates schedule accounting,
     *      but does not actually transfer any tokens.
     * @param s Index of the unlock schedule.
     * @return The number of unlocked shares.
     */
    function unlockScheduleShares(uint256 s) private returns (uint256) {
        UnlockSchedule storage schedule = unlockSchedules[s];

        if (schedule.unlockedShares >= schedule.initialLockedShares) {
            return 0;
        }

        uint256 sharesToUnlock = 0;
        // Special case to handle any leftover dust from integer division
        if (now >= schedule.endAtSec) {
            sharesToUnlock = (schedule.initialLockedShares.sub(schedule.unlockedShares));
            schedule.lastUnlockTimestampSec = schedule.endAtSec;
        } else {
            sharesToUnlock = now.sub(schedule.lastUnlockTimestampSec).mul(schedule.initialLockedShares).div(schedule.durationSec);
            schedule.lastUnlockTimestampSec = now;
        }

        schedule.unlockedShares = schedule.unlockedShares.add(sharesToUnlock);
        return sharesToUnlock;
    }
}
