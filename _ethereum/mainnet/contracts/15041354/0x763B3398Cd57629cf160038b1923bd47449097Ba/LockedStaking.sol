//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "./IERC20.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

contract LockedStaking is Initializable, OwnableUpgradeable {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    event LockAdded(address indexed from, uint208 amount, uint32 end, uint16 multiplier);
    event LockUpdated(address indexed from, uint8 index, uint208 amount, uint32 end, uint16 multiplier);
    event Unlock(address indexed from, uint256 amount, uint256 index);
    event Claim(address indexed from, uint256 amount);
    event RewardAdded(uint256 start, uint256 end, uint256 amountPerSecond);
    event RewardUpdated(uint256 index, uint256 start, uint256 end, uint256 amountPerSecond);
    event RewardRemoved(uint256 index);

    /*///////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////*/
    error MustProlongLock(uint256 oldDuration, uint256 newDuration);
    error AmountIsZero();
    error TransferFailed();
    error NothingToClaim();
    error LockStillActive();
    error IndexOutOfBounds(uint256 index, uint256 length);
    error DurationOutOfBounds(uint256 duration);
    error UpdateToSmallerMultiplier(uint16 oldMultiplier, uint16 newMultiplier);
    error ZeroAddress();
    error ZeroPrecision();
    error MaxLocksSucceeded();
    error MaxRewardsSucceeded();
    error CanOnlyAddFutureRewards();

    /*///////////////////////////////////////////////////////////////
                             IMMUTABLES & CONSTANTS
    //////////////////////////////////////////////////////////////*/
    IERC20 public swapToken;
    uint256 public precision;
    uint256 public constant MAX_LOCK_COUNT = 5;
    uint256 public constant MAX_REWARD_COUNT = 5;

    /*///////////////////////////////////////////////////////////////
                             STRUCTS
    //////////////////////////////////////////////////////////////*/
    struct Lock {
        uint16 multiplier;
        uint32 end;
        uint208 amount;
    }

    struct Reward {
        uint32 start;
        uint32 end;
        uint192 amountPerSecond;
    }

    /*///////////////////////////////////////////////////////////////
                             STORAGE
    //////////////////////////////////////////////////////////////*/
    Reward[] public rewards;
    mapping(address => Lock[]) public locks;
    mapping(address => uint256) public userLastAccRewardsWeight;

    uint256 public lastRewardUpdate;
    uint256 public totalScore;
    uint256 public accRewardWeight;

    function initialize(address _swapToken, uint256 _precision) external initializer {
        if (_swapToken == address(0)) revert ZeroAddress();
        if (_precision == 0) revert ZeroPrecision();

        swapToken = IERC20(_swapToken);
        precision = _precision;

        __Ownable_init();
    }

    function getRewardsLength() external view returns (uint256) {
        return rewards.length;
    }

    function getLockInfo(address addr, uint256 index) external view returns (Lock memory) {
        return locks[addr][index];
    }

    function getUserLocks(address addr) external view returns (Lock[] memory) {
        return locks[addr];
    }

    function getLockLength(address addr) external view returns (uint256) {
        return locks[addr].length;
    }

    function getRewards() external view returns (Reward[] memory) {
        return rewards;
    }

    function addReward(
        uint32 start,
        uint32 end,
        uint192 amountPerSecond
    ) external onlyOwner {
        if (rewards.length == MAX_REWARD_COUNT) revert MaxRewardsSucceeded();
        if (amountPerSecond == 0) revert AmountIsZero();
        if (start < block.timestamp || end < block.timestamp) revert CanOnlyAddFutureRewards();

        rewards.push(Reward(start, end, amountPerSecond));

        if (!IERC20(swapToken).transferFrom(msg.sender, address(this), (end - start) * amountPerSecond))
            revert TransferFailed();

        emit RewardAdded(start, end, amountPerSecond);
    }

    function removeReward(uint256 index) external onlyOwner {
        updateRewardsWeight();

        Reward memory reward = rewards[index];

        rewards[index] = rewards[rewards.length - 1];
        rewards.pop();

        // if rewards are not unlocked completely, send remaining to owner
        if (reward.end > block.timestamp) {
            uint256 lockedRewards = (reward.end - max(block.timestamp, reward.start)) * reward.amountPerSecond;

            if (!IERC20(swapToken).transfer(msg.sender, lockedRewards)) revert TransferFailed();
        }

        emit RewardRemoved(index);
    }

    function updateReward(
        uint256 index,
        uint256 start,
        uint256 end,
        uint256 amountPerSecond
    ) external onlyOwner {
        uint256 newRewards = (end - start) * amountPerSecond;

        Reward storage reward = rewards[index];
        uint256 oldStart = reward.start;
        uint256 oldEnd = reward.end;

        uint256 oldRewards = (oldEnd - oldStart) * reward.amountPerSecond;

        uint32 newStart = uint32(min(oldStart, start));
        uint32 newEnd = uint32(max(oldEnd, end));
        uint192 newAmountPerSecond = uint192((newRewards + oldRewards) / (newEnd - newStart));

        reward.start = newStart;
        reward.end = newEnd;
        reward.amountPerSecond = newAmountPerSecond;

        if (!IERC20(swapToken).transferFrom(msg.sender, address(this), newRewards)) revert TransferFailed();

        emit RewardUpdated(index, newStart, newEnd, newAmountPerSecond);
    }

    // claims for current locks and creates new lock
    function addLock(uint208 amount, uint256 duration) external {
        if (amount == 0) revert AmountIsZero();
        if (locks[msg.sender].length == MAX_LOCK_COUNT) revert MaxLocksSucceeded();

        uint256 newAccRewardsWeight = updateRewardsWeight();

        uint256 claimable = calculateUserClaimable(msg.sender, newAccRewardsWeight);

        userLastAccRewardsWeight[msg.sender] = newAccRewardsWeight;

        uint32 end = uint32(block.timestamp + duration);
        uint16 multiplier = getDurationMultiplier(duration);

        locks[msg.sender].push(Lock(multiplier, end, amount));

        totalScore += multiplier * amount;

        if (claimable < amount) {
            if (!IERC20(swapToken).transferFrom(msg.sender, address(this), amount - claimable)) revert TransferFailed();
        }

        if (claimable > amount) {
            if (!IERC20(swapToken).transfer(msg.sender, claimable - amount)) revert TransferFailed();
        }

        if (claimable > 0) {
            emit Claim(msg.sender, claimable);
        }

        emit LockAdded(msg.sender, amount, end, multiplier);
    }

    // adds claimable to current lock, keeping the same end
    function compound(uint8 index) external {
        uint256 newAccRewardsWeight = updateRewardsWeight();

        uint256 claimable = calculateUserClaimable(msg.sender, newAccRewardsWeight);
        if (claimable == 0) revert NothingToClaim();

        userLastAccRewardsWeight[msg.sender] = newAccRewardsWeight;

        Lock storage lock = locks[msg.sender][index];
        uint208 amount = lock.amount;
        uint16 multiplier = lock.multiplier;

        lock.amount = amount + uint208(claimable);
        totalScore += claimable * multiplier;

        emit LockUpdated(msg.sender, index, amount, lock.end, multiplier);
    }

    // claims for current lock and adds amount to existing lock, keeping the same end
    function updateLockAmount(uint256 index, uint208 amount) external {
        if (amount == 0) revert AmountIsZero();

        uint256 newAccRewardsWeight = updateRewardsWeight();

        Lock storage lock = locks[msg.sender][index];
        uint208 newAmount = lock.amount + amount;
        uint16 multiplier = lock.multiplier;

        uint256 claimable = calculateUserClaimable(msg.sender, newAccRewardsWeight);

        userLastAccRewardsWeight[msg.sender] = newAccRewardsWeight;

        lock.amount = newAmount;

        totalScore += amount * multiplier;

        if (claimable < amount) {
            if (!IERC20(swapToken).transferFrom(msg.sender, address(this), amount - claimable)) revert TransferFailed();
        }
        if (claimable > amount) {
            if (!IERC20(swapToken).transfer(msg.sender, claimable - amount)) revert TransferFailed();
        }

        if (claimable > 0) {
            emit Claim(msg.sender, claimable);
        }

        emit LockUpdated(msg.sender, uint8(index), newAmount, lock.end, multiplier);
    }

    // claims for current locks and increases duration of existing lock
    function updateLockDuration(uint8 index, uint256 duration) external {
        uint256 newAccRewardsWeight = updateRewardsWeight();

        Lock storage lock = locks[msg.sender][index];

        uint32 end = uint32(block.timestamp + duration);
        if (lock.end > end) revert MustProlongLock(lock.end, end);

        uint256 claimable = calculateUserClaimable(msg.sender, newAccRewardsWeight);

        userLastAccRewardsWeight[msg.sender] = newAccRewardsWeight;

        uint16 multiplier = getDurationMultiplier(duration);

        lock.end = end;

        uint16 oldMultiplier = lock.multiplier;

        if (oldMultiplier > multiplier) revert UpdateToSmallerMultiplier(oldMultiplier, multiplier);

        lock.multiplier = multiplier;

        totalScore += (multiplier - oldMultiplier) * lock.amount;

        if (claimable > 0) {
            if (!IERC20(swapToken).transfer(msg.sender, claimable)) revert TransferFailed();

            emit Claim(msg.sender, claimable);
        }

        emit LockUpdated(msg.sender, index, lock.amount, end, lock.multiplier);
    }

    // updates rewards weight & returns users claimable amount
    function getUserClaimable(address user) external view returns (uint256 claimable) {
        uint256 accRewardsWeight = getRewardsWeight();

        return calculateUserClaimable(user, accRewardsWeight);
    }

    // returns users claimable amount
    function calculateUserClaimable(address user, uint256 accRewardsWeight_) internal view returns (uint256 claimable) {
        uint256 userScore = getUsersTotalScore(user);

        return (userScore * (accRewardsWeight_ - userLastAccRewardsWeight[user])) / precision;
    }

    // returns users score for all locks
    function getUsersTotalScore(address user) public view returns (uint256 score) {
        uint256 lockLength = locks[user].length;
        Lock storage lock;
        for (uint256 lockId = 0; lockId < lockLength; ++lockId) {
            lock = locks[user][lockId];
            score += lock.amount * lock.multiplier;
        }
    }

    // claims for current locks
    function claim() external {
        uint256 newAccRewardsWeight = updateRewardsWeight();

        uint256 claimable = calculateUserClaimable(msg.sender, newAccRewardsWeight);
        if (claimable == 0) revert NothingToClaim();

        userLastAccRewardsWeight[msg.sender] = newAccRewardsWeight;

        if (!IERC20(swapToken).transfer(msg.sender, claimable)) revert TransferFailed();

        emit Claim(msg.sender, claimable);
    }

    // returns locked amount to user and deletes lock from array
    function unlock(uint256 index) external {
        uint256 newAccRewardsWeight = updateRewardsWeight();
        Lock storage lock = locks[msg.sender][index];

        if (lock.end > block.timestamp) revert LockStillActive();

        uint256 amount = lock.amount;

        uint256 claimable = calculateUserClaimable(msg.sender, newAccRewardsWeight);

        userLastAccRewardsWeight[msg.sender] = newAccRewardsWeight;

        totalScore -= amount * lock.multiplier;

        locks[msg.sender][index] = locks[msg.sender][locks[msg.sender].length - 1];
        locks[msg.sender].pop();

        if (!IERC20(swapToken).transfer(msg.sender, amount + claimable)) revert TransferFailed();

        if (claimable > 0) {
            emit Claim(msg.sender, claimable);
        }

        emit Unlock(msg.sender, amount, index);
    }

    // calculates and updates rewards weight
    function updateRewardsWeight() public returns (uint256) {
        // already updated
        if (block.timestamp == lastRewardUpdate) {
            return accRewardWeight;
        }

        uint256 newAccRewardsWeight = getRewardsWeight();

        if (newAccRewardsWeight > 0) {
            lastRewardUpdate = block.timestamp;
            accRewardWeight = newAccRewardsWeight;
        }

        return newAccRewardsWeight;
    }

    // calculates rewards weight
    function getRewardsWeight() public view returns (uint256) {
        // to avoid div by zero on first lock
        if (totalScore == 0) {
            return 0;
        }

        uint256 _lastRewardUpdate = lastRewardUpdate;

        uint256 length = rewards.length;
        uint256 newRewards;
        for (uint256 rewardId = 0; rewardId < length; ++rewardId) {
            Reward storage reward = rewards[rewardId];
            uint256 start = reward.start;
            uint256 end = reward.end;

            if (block.timestamp < start) continue;
            if (_lastRewardUpdate > end) continue;

            newRewards += (min(block.timestamp, end) - max(start, _lastRewardUpdate)) * reward.amountPerSecond;
        }

        return newRewards == 0 ? accRewardWeight : accRewardWeight + (newRewards * precision) / totalScore;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x > y ? x : y;
    }

    // returns multiplier(2 decimals) on amount locked for duration in seconds
    // aprox of function (2592000,1),(31536000,2),(94608000,5),(157680000,10)
    // 2.22574×10^-16 x^2 + 2.19094×10^-8 x + 0.993975
    function getDurationMultiplier(uint256 duration) public pure returns (uint16) {
        if (duration < 30 days || duration > 1825 days) revert DurationOutOfBounds(duration);

        return uint16((222574 * duration * duration + 21909400000000 * duration + 993975000000000000000) / 1e19);
    }
}
