// SPDX-License-Identifier: MIT

/* 
    - Stake up to X mushrooms per user (dao can change)
    - Reward mushroom yield rate for lifespan
    - When dead, burn mushroom erc721
    - Distribute 5% of ENOKI rewards to Chefs
*/
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";

import "./TokenPool.sol";
import "./Defensible.sol";
import "./MushroomNFT.sol";
import "./MushroomLib.sol";
import "./MetadataResolver.sol";

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
contract EnokiGeyser is Initializable, OwnableUpgradeSafe, AccessControlUpgradeSafe, ReentrancyGuardUpgradeSafe, Defensible {
    using SafeMath for uint256;
    using MushroomLib for MushroomLib.MushroomData;
    using MushroomLib for MushroomLib.MushroomType;

    event Staked(address indexed user, address nftContract, uint256 nftId, uint256 total, bytes data);
    event Unstaked(address indexed user, address nftContract, uint256 nftId, uint256 total, uint256 indexed stakeIndex, bytes data);
    event TokensClaimed(address indexed user, uint256 amount, uint256 userReward, uint256 devReward);
    event TokensLocked(uint256 amount, uint256 total);
    event TokensLockedAirdrop(uint256 amount, uint256 total);

    event LifespanUsed(address nftContract, uint256 nftIndex, uint256 lifespanUsed, uint256 lifespan);
    event NewLifespan(address nftContract, uint256 nftIndex, uint256 lifespan);

    // amount: Unlocked tokens, total: Total locked tokens
    event TokensUnlocked(uint256 amount, uint256 total);

    event MaxStakesPerAddressSet(uint256 maxStakesPerAddress);
    event MetadataResolverSet(address metadataResolver);
    event BurnedMushroom(address nftContract, uint256 nftIndex);

    TokenPool public _unlockedPool;
    TokenPool public _lockedPool;

    MetadataResolver public metadataResolver;

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
    BannedContractList public bannedContractList;

    //
    // User accounting state
    //
    // Represents a single stake for a user. A user may have multiple.
    struct Stake {
        address nftContract;
        uint256 nftIndex;
        uint256 strength;
        uint256 stakedAt;
    }

    // Caches aggregated values from the User->Stake[] map to save computation.
    // If lastAccountingTimestampSec is 0, there's no entry for that user.
    struct UserTotals {
        uint256 userStrengthStaked;
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

    bool public initializeComplete;
    uint256 public constant SECONDS_PER_WEEK = 604800;

    uint256 public usedAirdropPool;
    uint256 public maxAirdropPool;
    address internal constant INITIALIZER_ADDRESS = 0xe9673e2806305557Daa67E3207c123Af9F95F9d2;

    IERC20 public enokiToken;

    uint256 public stakingEnabledTime;

    /**
     * @param enokiToken_ The token users receive as they unstake.
     * @param maxStakesPerAddress_ Maximum number of NFTs stakeable by a given account.
     * @param devRewardAddress_ Recipient address of dev rewards.
     * @param devRewardPercentage_ Pecentage of rewards claimed to be distributed for dev address.
     */

    function initialize(
        IERC20 enokiToken_,
        uint256 maxStakesPerAddress_,
        address devRewardAddress_,
        uint256 devRewardPercentage_,
        address bannedContractList_,
        uint256 stakingEnabledTime_,
        uint256 maxAirdropPool_,
        address resolver_
    ) public {
        require(msg.sender == INITIALIZER_ADDRESS, "Only deployer can reinitialize");
        require(admin == address(0), "Admin has already been initialized");
        require(initializeComplete == false, "Initialization already complete");

        // The dev reward must be some fraction of the max. (i.e. <= 100%)
        require(devRewardPercentage_ <= MAX_PERCENTAGE, "EnokiGeyser: dev reward too high");

        enokiToken = enokiToken_;

        maxStakesPerAddress = maxStakesPerAddress_;
        emit MaxStakesPerAddressSet(maxStakesPerAddress);

        devRewardPercentage = devRewardPercentage_;
        devRewardAddress = devRewardAddress_;

        stakingEnabledTime = stakingEnabledTime_;

        maxAirdropPool = maxAirdropPool_;

        metadataResolver = MetadataResolver(resolver_);
        emit MetadataResolverSet(address(metadataResolver));

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        bannedContractList = BannedContractList(bannedContractList_);

        initializeComplete = true;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "EnokiGeyser: Only Admin");
        _;
    }

    /* ========== ADMIN FUNCTIONALITY ========== */

    // Only effects future stakes
    function setMaxStakesPerAddress(uint256 maxStakes) public onlyAdmin {
        maxStakesPerAddress = maxStakes;
        emit MaxStakesPerAddressSet(maxStakesPerAddress);
    }

    function setMetadataResolver(address resolver_) public onlyAdmin {
        metadataResolver = MetadataResolver(resolver_);
        emit MetadataResolverSet(address(metadataResolver));
    }

    /**
     * @return The token users receive as they unstake.
     */
    function getDistributionToken() public view returns (IERC20) {
        return enokiToken;
    }

    function getNumStakes(address user) external view returns (uint256) {
        return _userStakes[user].length;
    }

    function getStakes(address user) external view returns (Stake[] memory) {
        uint256 numStakes = _userStakes[user].length;
        Stake[] memory stakes = new Stake[](numStakes);

        for (uint256 i = 0; i < _userStakes[user].length; i++) {
            stakes[i] = _userStakes[user][i];
        }
        return stakes;
    }

    function getStake(address user, uint256 stakeIndex) external view returns (Stake memory stake) {
        Stake storage _userStake = _userStakes[user][stakeIndex];
        stake = _userStake;
    }

    /**
     * @dev Transfers amount of deposit tokens from the user.
     * @param data Not used.
     */
    function stake(
        address nftContract,
        uint256 nftIndex,
        bytes calldata data
    ) external defend(bannedContractList) {
        require(now > stakingEnabledTime, "staking-too-early");
        require(metadataResolver.isStakeable(nftContract, nftIndex), "EnokiGeyser: nft not stakeable");
        _stakeFor(msg.sender, msg.sender, nftContract, nftIndex);
    }

    // /**
    //  * @dev Transfers amount of deposit tokens from the user.
    //  * @param data Not used.
    //  */
    // function stakeBulk(
    //     address[] memory nftContracts,
    //     uint256[] memory nftIndicies,
    //     bytes calldata data
    // ) external defend(bannedContractList) {
    //     require(now > stakingEnabledTime, "staking-too-early");
    //     require(nftContracts.length == nftIndicies.length, "args length mismatch");

    //     for (uint256 i = 0; i < nftContracts.length; i++) {
    //         require(metadataResolver.isStakeable(nftContracts[i], nftIndicies[i]), "EnokiGeyser: nft not stakeable");
    //         _stakeFor(msg.sender, msg.sender, nftContracts[i], nftIndicies[i]);
    //     }
    // }

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
        require(metadataResolver.isStakeable(nftContract, nftIndex), "EnokiGeyser: Nft specified not stakeable");

        // Shares is determined by NFT mushroom rate

        MushroomLib.MushroomData memory metadata = metadataResolver.getMushroomData(nftContract, nftIndex, "");

        // 1. User Accounting
        UserTotals storage totals = _userTotals[beneficiary];

        Stake memory newStake = Stake(nftContract, nftIndex, metadata.strength, now);
        _userStakes[beneficiary].push(newStake);

        require(_userStakes[beneficiary].length <= maxStakesPerAddress, "EnokiGeyser: Stake would exceed maximum stakes for address");

        totals.userStrengthStaked = totals.userStrengthStaked.add(metadata.strength);
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
    function unstake(uint256[] calldata stakes, bytes calldata data)
        external
        returns (
            uint256 totalReward,
            uint256 userReward,
            uint256 devReward
        )
    {
        require(stakes.length == 1, "Can only unstake one nft at once");
        return _unstake(stakes[0]);
    }


    function _unstake(uint256 stakeIndex)
        private
        returns (
            uint256 totalReward,
            uint256 userReward,
            uint256 devReward
        )
    {
        // 1. User Accounting
        UserTotals storage totals = _userTotals[msg.sender];
        Stake[] storage accountStakes = _userStakes[msg.sender];

        // Redeem from most recent stake and go backwards in time.
        uint256 rewardAmount = 0;

        Stake storage currentStake = accountStakes[stakeIndex];

        MushroomLib.MushroomData memory metadata = metadataResolver.getMushroomData(currentStake.nftContract, currentStake.nftIndex, "");

        uint256 lifespanUsed = now.sub(currentStake.stakedAt);
        bool deadMushroom = false;

        // Effective lifespan used is capped at mushroom lifespan

        if (lifespanUsed >= metadata.lifespan) {
            lifespanUsed = metadata.lifespan;
            deadMushroom = true;
        }

        emit LifespanUsed(currentStake.nftContract, currentStake.nftIndex, lifespanUsed, metadata.lifespan);

        rewardAmount = computeNewReward(rewardAmount, metadata.strength, lifespanUsed);

        // Update global aomunt staked
        totalStrengthStaked = totalStrengthStaked.sub(metadata.strength);
        totals.userStrengthStaked = totals.userStrengthStaked.sub(metadata.strength);

        // Burn dead mushrooms, if they can be burnt. Otherwise, they can still be withdrawn with 0 lifespan.
        if (deadMushroom && metadataResolver.isBurnable(currentStake.nftContract, currentStake.nftIndex)) {
            MushroomNFT(currentStake.nftContract).burn(currentStake.nftIndex);
            emit BurnedMushroom(currentStake.nftContract, currentStake.nftIndex);
        } else {
            // If still alive, reduce lifespan of mushroom and return to user. If not burnable, return with 0 lifespan.
            metadataResolver.setMushroomLifespan(currentStake.nftContract, currentStake.nftIndex, metadata.lifespan.sub(lifespanUsed), "");
            IERC721(currentStake.nftContract).transferFrom(address(this), msg.sender, currentStake.nftIndex);

            // TODO: Test
            MushroomLib.MushroomData memory metadata2 = metadataResolver.getMushroomData(currentStake.nftContract, currentStake.nftIndex, "");
            emit NewLifespan(currentStake.nftContract, currentStake.nftIndex, metadata2.lifespan);
        }

        uint256 finalStakeIndex = accountStakes.length - 1;

        // Delete current stake
        if (stakeIndex == finalStakeIndex) {
            accountStakes.pop(); // Remove if end
        } else {
            // Move last stake to it's spot
            accountStakes[stakeIndex] = accountStakes[finalStakeIndex];
            // Pop last stake, which is now duplicated
            accountStakes.pop();
        }

        emit Unstaked(msg.sender, currentStake.nftContract, currentStake.nftIndex, totalStakedFor(msg.sender), stakeIndex, "");

        // Already set in updateAccounting
        // _lastAccountingTimestampSec = now;

        // interactions
        totalReward = rewardAmount;
        (userReward, devReward) = computeDevReward(totalReward);
        if (userReward > 0) {
            require(enokiToken.transfer(msg.sender, userReward), "EnokiGeyser: transfer to user out of unlocked pool failed");
        }

        if (devReward > 0) {
            require(enokiToken.transfer(devRewardAddress, devReward), "EnokiGeyser: transfer to dev out of unlocked pool failed");
        }

        emit TokensClaimed(msg.sender, rewardAmount, userReward, devReward);

        require(totalStakingShares == 0 || totalStaked() > 0, "EnokiGeyser: Error unstaking. Staking shares exist, but no staking tokens do");
    }

    function computeNewReward(
        uint256 currentReward,
        uint256 strength,
        uint256 timeStaked
    ) private view returns (uint256) {
        uint256 newReward = strength.mul(timeStaked).div(SECONDS_PER_WEEK);
        return currentReward.add(newReward);
    }

    function updateStake(
        address staker,
        uint256 stakeIndex,
        address nftContract,
        uint256 nftIndex,
        uint256 strength,
        uint256 stakedAt
    ) external onlyAdmin {
        _userStakes[staker][stakeIndex] = Stake(nftContract, nftIndex, strength, stakedAt);
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
        return _userTotals[addr].userStrengthStaked;
    }

    /**
     * @return The total number of deposit tokens staked globally, by all users.
     */
    function totalStaked() public view returns (uint256) {
        return totalStrengthStaked;
    }

    /**
     * @return Total number of locked distribution tokens.
     */
    function totalLocked() public view returns (uint256) {
        return enokiToken.balanceOf(address(this));
    }

    /**
     * @dev This funcion allows the contract owner to add more locked distribution tokens, along
     *      with the associated "unlock schedule". These locked tokens immediately begin unlocking
     *      linearly over the duraction of durationSec timeframe.
     * @param amount Number of distribution tokens to lock. These are transferred from the caller.
     * @param durationSec Length of time to linear unlock the tokens.
     */
    function lockTokens(uint256 amount, uint256 durationSec) external onlyOwner {
        require(enokiToken.transferFrom(msg.sender, address(this), amount), "EnokiGeyser: transfer failed");
        emit TokensLocked(amount, totalLocked());
    }

    function lockTokensAirdrop(address airdrop, uint256 amount) external onlyAdmin {
        require(usedAirdropPool.add(amount) <= maxAirdropPool, "Exceeds maximum airdrop tokens");
        usedAirdropPool = usedAirdropPool.add(amount);

        require(enokiToken.transfer(address(airdrop), amount), "EnokiGeyser: transfer into airdrop pool failed");

        emit TokensLockedAirdrop(amount, totalLocked());
    }
}
