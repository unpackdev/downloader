//SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeERC20.sol";
import "./IERC20Metadata.sol";
import "./EnumerableSet.sol";

/**
 * @title Minting
 * @author gotbit
 * @notice Contract for staking tokens in order to earn rewards. Any user can make multiple stakes. Reward earn period is practically unlimited.
 */

contract Minting is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    // TYPES

    struct Stake {
        address owner;
        uint256 amount;
        uint256 rewardToUser;
        uint32 apy;
        uint32 unstakedAtBlockTimestamp;
        uint32 stakingPeriod;
        uint32 timestamp;
    }

    // STATE VARIABLES

    uint256 public constant ACCURACY = 1e18;
    uint256 public constant MIN_STAKING_PERIOD = 1 days; // 1 day
    uint256 public constant MAX_STAKING_PERIOD = YEAR * 5; // 5 year
    uint256 public constant RECEIVE_PERIOD = 14 days; // 14 days
    uint256 public constant ONE_HUNDRED = 100; // 100%
    uint256 public constant APY_4 = 4; // 4%
    uint256 public constant APY_7 = 7; // 7%
    uint256 public constant APY_15 = 15; // 15%
    uint256 public constant APY_34 = 34; // 34%
    uint256 public constant APY_53 = 53; // 53%
    uint256 public constant APY_67 = 67; // 67%
    uint256 public constant APY_75 = 75; // 75%
    uint256 public constant APY_84 = 84; // 84%
    uint256 public constant YEAR = 360 days; // 365 days = 1 year
    // uint256 ~ 10*77 => 10**77 ~ amount * 100 * 10**10 = amount * 10 ** 12 => amount < 10 ** (77 - 12)
    uint256 public constant MAX_STAKE_AMOUNT = 10 ** 54;

    IERC20 public immutable stakingToken;

    uint256 public totalSupply;

    uint256 public maxPotentialDebt;

    mapping(uint256 => Stake) public stakes;
    mapping(address => uint256[]) public userInactiveStakes;
    mapping(address => EnumerableSet.UintSet) private _idsByUser;
    mapping(address => uint256) public balanceOf;

    uint256 public globalId;

    // sum of all staking periods across all active stakes
    uint80 public sumOfActiveStakingPeriods;
    // number of currenlty active stakes
    uint80 public numOfActiveStakes;
    // sum of apy values over all active stakes
    uint80 public sumOfActiveAPY;

    event Staked(address indexed user, uint256 indexed id, uint256 amount);
    event Withdrawn(address user, uint256 indexed id, uint256 amount);

    constructor(IERC20 stakingToken_, address owner_) {
        require(address(stakingToken_) != address(0), 'Invalid address');
        require(owner_ != address(0), 'Invalid address');

        stakingToken = stakingToken_;
        _transferOwnership(owner_);
    }

    /// @dev Allows user to stake tokens
    /// @param amount of token to stake
    /// @param stakingPeriod period to hold staked tokens (in case of unstake too early or too late => penalties applied)
    function stake(uint256 amount, uint32 stakingPeriod) external whenNotPaused {
        require(amount > 0, 'Cannot stake 0');
        require(amount <= MAX_STAKE_AMOUNT, 'Stake amount exceeds limit');
        require(stakingPeriod >= MIN_STAKING_PERIOD, 'Staking period is too short');
        require(stakingPeriod <= MAX_STAKING_PERIOD, 'Staking period is too long');

        totalSupply += amount;
        sumOfActiveStakingPeriods += stakingPeriod;
        ++numOfActiveStakes;
        uint32 apy = uint32(getAPYforDuration(stakingPeriod));
        sumOfActiveAPY += apy;

        maxPotentialDebt +=
            _calculateRewardForDurationAndStakingPeriod(
                amount,
                stakingPeriod,
                stakingPeriod
            ) +
            amount;

        require(
            maxPotentialDebt <= contractBalance() + amount,
            'Max potential debt exceeds contract balance'
        );

        uint256 id = ++globalId;

        // address owner;
        // uint256 amount;
        // uint256 rewardToUser
        // uint32 apy;
        // uint32 unstakedAtBlockTimestamp;
        // uint32 stakingPeriod;
        // uint32 timestamp;
        stakes[id] = Stake(
            msg.sender,
            amount,
            0,
            apy,
            0,
            stakingPeriod,
            uint32(block.timestamp)
        );

        balanceOf[msg.sender] += amount;
        _idsByUser[msg.sender].add(id);

        emit Staked(msg.sender, id, amount);

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @dev Allows to calculate principal and rewards penalties (nominated in percents, multiplied by ACCURACY = 1e18) for a specific stake
    /// @param id Stake id
    /// @return principalPenaltyPercentage - principal fee, rewardPenaltyPercentage - rewards fee (multiplied by ACCURACY)
    function calculatePenalties(
        uint256 id
    )
        public
        view
        returns (uint256 principalPenaltyPercentage, uint256 rewardPenaltyPercentage)
    {
        uint128 timestamp = stakes[id].timestamp;
        uint128 stakingPeriod = stakes[id].stakingPeriod;
        uint256 actualStakingTime = block.timestamp - timestamp;

        if (actualStakingTime < stakingPeriod) {
            // EMERGENCY UNSTAKE
            if (actualStakingTime < (2 * stakingPeriod) / 10) {
                // 0 - 20 % hold time
                principalPenaltyPercentage = 80 * ACCURACY;
                rewardPenaltyPercentage = 100 * ACCURACY;
            } else if (actualStakingTime < (4 * stakingPeriod) / 10) {
                // 20 - 40 % hold time
                principalPenaltyPercentage = 40 * ACCURACY;
                rewardPenaltyPercentage = 100 * ACCURACY;
            } else if (actualStakingTime < (5 * stakingPeriod) / 10) {
                // 40 - 50 % hold time
                rewardPenaltyPercentage = 100 * ACCURACY;
            } else if (actualStakingTime < (7 * stakingPeriod) / 10) {
                // 50 - 70 % hold time
                rewardPenaltyPercentage = 50 * ACCURACY;
            } else {
                // 70 - 100 % hold time
                rewardPenaltyPercentage = 20 * ACCURACY;
            }
        } else if (actualStakingTime > stakingPeriod + RECEIVE_PERIOD) {
            // LATE UNSTAKE
            // principal penalty = 0

            uint256 extraPeriod = actualStakingTime - stakingPeriod;
            rewardPenaltyPercentage = (extraPeriod * 100 * ACCURACY) / actualStakingTime;
        }
        // else SAFE UNSTAKE (principal fee = 0, rewards fee = 0)
    }

    /// @dev Allows user to withdraw staked tokens + claim earned rewards - penalties
    /// @param id Stake id
    function withdraw(uint256 id) external {
        Stake memory _stake = stakes[id];
        uint256 amount = _stake.amount;
        require(_stake.unstakedAtBlockTimestamp == 0, 'Already unstaked');
        require(_stake.owner == msg.sender, 'Can`t be called not by stake owner');

        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;

        (
            uint256 principalPenaltyPercentage,
            uint256 rewardPenaltyPercentage
        ) = calculatePenalties(id);

        --numOfActiveStakes;
        sumOfActiveStakingPeriods -= _stake.stakingPeriod;
        sumOfActiveAPY -= _stake.apy;

        uint256 rewardAmountToContract;
        uint256 rewardAmountToUser;

        uint256 reward = earned(id);

        if (reward != 0) {
            // CLAIM ALL EARNED REWARDS
            rewardAmountToContract =
                (reward * rewardPenaltyPercentage) /
                (100 * ACCURACY);

            rewardAmountToUser = reward - rewardAmountToContract;

            stakes[id].rewardToUser = rewardAmountToUser;
        }

        // stake will no longer gain rewards => substract max possible stake amount + reward
        maxPotentialDebt -=
            _calculateRewardForDurationAndStakingPeriod(
                _stake.amount,
                _stake.stakingPeriod,
                _stake.stakingPeriod
            ) +
            _stake.amount;

        _idsByUser[msg.sender].remove(id);
        userInactiveStakes[msg.sender].push(id);

        stakes[id].unstakedAtBlockTimestamp = uint32(block.timestamp);

        // ALL TOKENS TRANSFERS -------------------------------------------------------

        // REWARDS + PRINCIPAL TRANSFERS

        uint256 amountToWallet = (amount * principalPenaltyPercentage) / (100 * ACCURACY);
        // amountToWallet + rewardAmountToWallet stay on comtract

        emit Withdrawn(msg.sender, id, amount - amountToWallet + rewardAmountToUser);

        // amount != amountToWallet due to the technical design
        stakingToken.safeTransfer(
            msg.sender,
            amount - amountToWallet + rewardAmountToUser
        );
    }

    /// @dev Allows to view current user earned rewards
    /// @param id to view rewards
    /// @return earned - Amount of rewards for the selected user stake
    function earned(uint256 id) public view returns (uint256) {
        Stake memory _stake = stakes[id];
        if (_stake.unstakedAtBlockTimestamp == 0) {
            // ACTIVE STAKE => calculate amount + increase reward per token
            // amountForDuration >= amount
            return
                _calculateRewardForDurationAndStakingPeriod(
                    _stake.amount,
                    getStakeRealDuration(id),
                    _stake.stakingPeriod
                );
        }

        // INACTIVE STAKE
        return 0;
    }

    /// @dev Returns the stake exact hold time
    /// @param id stake id
    /// @return duration - stake exact hold time
    function getStakeRealDuration(uint256 id) public view returns (uint256 duration) {
        Stake memory _stake = stakes[id];
        uint256 holdTime = block.timestamp - _stake.timestamp;
        duration = holdTime > _stake.stakingPeriod ? _stake.stakingPeriod : holdTime;
    }

    /// @dev Returns the approximate APY for a specific stake position including penalties (real APY = potential APY * (1 - rewardPenalty))
    /// @param id stake id
    /// @return APY value multiplied by 10**18
    function getAPY(uint256 id) external view returns (uint256) {
        (, uint256 rewardPenalty) = calculatePenalties(id);

        uint256 apy = getAPYforDuration(stakes[id].stakingPeriod);
        return (apy * (ONE_HUNDRED * ACCURACY - rewardPenalty)) / (ONE_HUNDRED); // apy * 10**18
    }

    /// @dev Calculates the max potential reward after unstake for a stake with a given amount and staking period (without substracting penalties)
    /// @param amount - stake amount
    /// @param duration - stake actual hold period
    /// @param stakingPeriod - stake period, set when making stake
    /// @return max potential unstaked reward
    function _calculateRewardForDurationAndStakingPeriod(
        uint256 amount,
        uint256 duration,
        uint256 stakingPeriod
    ) private pure returns (uint256) {
        uint256 apy = getAPYforDuration(stakingPeriod);

        return (amount * apy * duration) / (YEAR * ONE_HUNDRED);
    }

    /// @dev Returns the correct APY per annum value for the corresponding duration
    /// @param duration - stake hold period
    /// @return apy - APY value nominated in percents
    function getAPYforDuration(uint256 duration) public pure returns (uint256 apy) {
        if (duration <= 30 days) {
            apy = APY_4;
        } else if (duration > 30 days && duration <= 90 days) {
            apy = APY_7;
        } else if (duration > 90 days && duration <= 180 days) {
            apy = APY_15;
        } else if (duration > 180 days && duration <= 360 days) {
            apy = APY_34;
        } else if (duration > 360 days && duration <= 720 days) {
            apy = APY_53;
        } else if (duration > 720 days && duration <= 1080 days) {
            apy = APY_67;
        } else if (duration > 1080 days && duration <= 1440 days) {
            apy = APY_75;
        } else {
            // duration > 1440 days && duration < MAX_STAKE_PERIOD
            apy = APY_84;
        }
    }

    /// @dev Returns rewards which can be distributed to new users
    /// @return Max reward available at the moment
    function getRewardsAvailable() external view returns (uint256) {
        // maxPotentialDebt = sum of principal + sum of max potential reward
        return contractBalance() - maxPotentialDebt;
    }

    /// @dev Allows to view staking token contract balance
    /// @return balance of staking token contract balance
    function contractBalance() public view returns (uint256) {
        return stakingToken.balanceOf(address(this));
    }

    /// @dev Allows to view user stake ids
    /// @param user user account
    /// @return array of user ids
    function getUserStakeIds(address user) external view returns (uint256[] memory) {
        return _idsByUser[user].values();
    }

    /// @dev Allows to view user`s stake ids quantity
    /// @param user user account
    /// @return length of user ids array
    function getUserStakeIdsLength(address user) external view returns (uint256) {
        return _idsByUser[user].values().length;
    }

    /// @dev Allows to view if a user has a stake with specific id
    /// @param user user account
    /// @param id stake id
    /// @return bool flag (true if a user has owns the id)
    function hasStakeId(address user, uint256 id) external view returns (bool) {
        return _idsByUser[user].contains(id);
    }

    /// @dev Allows to get all user stakes
    /// @param user user account
    /// @return array of user stakes
    function getAllUserStakes(address user) external view returns (Stake[] memory) {
        uint256[] memory ids = _idsByUser[user].values();
        uint256 len = ids.length;
        Stake[] memory userStakes = new Stake[](len);
        for (uint256 i; i < len; ++i) {
            uint256 stakeId = ids[i];
            userStakes[i] = stakes[stakeId];
        }

        return userStakes;
    }

    /// @dev Allows to get a slice user stakes array
    /// @param user user account
    /// @param startIndex Starting index in user ids array
    /// @param length return array length
    /// @return Array-slice of user stakes
    function getUserStakesSlice(
        address user,
        uint256 startIndex,
        uint256 length
    ) external view returns (Stake[] memory) {
        uint256[] memory ids = _idsByUser[user].values();
        uint256 len = ids.length;
        require(startIndex + length <= len, 'Invalid startIndex + length');

        Stake[] memory userStakes = new Stake[](length);
        uint256 userIndex;
        for (uint256 i = startIndex; i < startIndex + length; ++i) {
            uint256 stakeId = ids[i];
            userStakes[userIndex] = stakes[stakeId];
            ++userIndex;
        }

        return userStakes;
    }

    /// @dev Sets paused state for the contract (can be called by the owner only)
    /// @param paused paused flag
    function setPaused(bool paused) external onlyOwner {
        if (paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    /// @dev Allows to get a slice user stakes history array
    /// @param user user account
    /// @param startIndex Starting index in user ids array
    /// @param length return array length
    /// @return Array-slice of user stakes history
    function getUserInactiveStakesSlice(
        address user,
        uint256 startIndex,
        uint256 length
    ) external view returns (Stake[] memory) {
        uint256 len = userInactiveStakes[user].length;
        require(startIndex + length <= len, 'Invalid startIndex + length');
        Stake[] memory userStakes = new Stake[](length);
        uint256[] memory userInactiveStakes_ = userInactiveStakes[user];
        uint256 userIndex;
        for (uint256 i = startIndex; i < startIndex + length; ++i) {
            uint256 stakeId = userInactiveStakes_[i];
            userStakes[userIndex] = stakes[stakeId];
            ++userIndex;
        }
        return userStakes;
    }

    /// @dev Allows to view user`s closed stakes quantity
    /// @param user user account
    /// @return length of user closed stakes array
    function getUserInactiveStakesLength(address user) external view returns (uint256) {
        return userInactiveStakes[user].length;
    }
}
