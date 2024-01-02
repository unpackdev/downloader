// SPDX-License-Identifier: UNLICENSED
pragma solidity = 0.8.20;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

/**
 * @title COCKS Staking contract
 * @dev Deposit COCKS token and partake in reward distributions paid in USDC per epoch.
 * Reward payouts are based on not only the amount a user stakes but also the duration that they were staked for during
 * each epoch. Each stake for a given user is treated as independent from one another
 */
contract COCKSStaking is ReentrancyGuard, Ownable {

    using SafeERC20 for IERC20;

    struct Stake {
        uint amount;
        uint epoch;
        uint epochRewardFactor;
        /// @dev claimedUpTill means the rewards have been claimed up to but not including the epoch
        uint claimedUpTill;
        uint withdrawalInitiatedAt;
        bool isWithdrawn;
    }

    struct Epoch {
        uint reward;
        /// @dev epoch starts at
        uint startedAt;
        uint finishedAt;
        uint firstDepositAt;
        uint lastDepositAt;
        uint totalDeposited;
        uint rewardFactor;
        uint fullEpochRewardFactor;
    }

    IERC20 public immutable cocks;
    IERC20 public immutable usdc;
    uint private constant MIN_EPOCH_TIME = 6.5 days;
    uint private constant WITHDRAWAL_LOCK_PERIOD = 7 days;
    uint private constant MAX_ITERATIONS = 25;
    uint private constant REWARD_PRECISION = 1000 ether;
    uint public currentEpoch;
    uint public totalDistributed;
    uint public totalClaimed;
    bool public isDepositingEnabled = true;
    address private _distributor;
    mapping(address => Stake[]) private _stakes;
    mapping(uint => Epoch) private _epochs;

    modifier onlyIfDepositingIsEnabled() {
        require(isDepositingEnabled, "COCKSStaking: Depositing is not enabled");
        _;
    }

    modifier onlyDistributor() {
        require(_msgSender() == _distributor, "COCKSStaking: caller is not the distributor");
        _;
    }

    event Deposit(address indexed staker, uint amount);
    event Withdraw(address indexed staker, uint totalLocked, uint totalWithdrawn, uint totalReward);
    event Distributed(uint indexed epoch, uint reward);
    event ClaimedReward(address indexed staker, uint reward);
    event DistributorUpdated(address indexed newDistributor, address prevDistributor);

    /**
     * @param cocks_ $COCKs token address
     * @param usdc_ USDC token address
     * @param distributor_ Distributor address
     */
    constructor(IERC20 cocks_, IERC20 usdc_, address distributor_) Ownable(_msgSender()) {
        require(address(cocks_) != address(0), "COCKSStaking: cocks_ is the zero address");
        require(address(usdc_) != address(0), "COCKSStaking: usdc_ is the zero address");
        require(distributor_ != address(0), "COCKSStaking: distributor_ is the zero address");
        cocks = cocks_;
        usdc = usdc_;
        _distributor = distributor_;
    }

    /// @notice Toggle depositing (only Owner)
    function toggleDepositing() external onlyOwner {
        isDepositingEnabled = !isDepositingEnabled;
    }

    /**
     * @notice Set distributor (only Owner)
     * @param distributor_ New distributor
     */
    function setDistributor(address distributor_) external onlyOwner {
        address prevDistributor = _distributor;
        _setDistributor(distributor_);
        emit DistributorUpdated(distributor_, prevDistributor);
    }

    /**
     * @notice Deposit $COCKs to earn rewards from USDC distributions
     * @param _amount Amount to deposit
     */
    function deposit(uint _amount) external nonReentrant onlyIfDepositingIsEnabled {
        require(cocks.allowance(_msgSender(), address(this)) >= _amount, "COCKSStaking: Insufficient allowance");
        require(cocks.balanceOf(_msgSender()) >= _amount, "COCKSStaking: Insufficient balance");
        Epoch storage current = _epochs[currentEpoch];
        if (current.firstDepositAt > 0) {
            _updateRewardFactor();
        } else {
            current.firstDepositAt = block.timestamp;
        }
        current.totalDeposited += _amount;
        current.lastDepositAt = block.timestamp;
        _stakes[_msgSender()].push(
            Stake(
                _amount,
                currentEpoch,
                current.rewardFactor,
                0,
                0,
                false
            )
        );
        cocks.safeTransferFrom(_msgSender(), address(this), _amount);
        emit Deposit(_msgSender(), _amount);
    }

    /**
     * @notice Initiates withdrawals (and claims rewards) and payouts withdrawals if 7 days have elapsed since a withdrawal was initiated
     * @param _indexes A list of indexes corresponding to a user's stakes
     */
    function withdraw(uint[] calldata _indexes) external nonReentrant {
        Epoch storage current = _epochs[currentEpoch];
        uint totalStakes = getTotalStakesByUser(_msgSender());
        uint totalLocked;
        uint totalWithdrawn;
        uint totalReward;
        for (uint i; i < _indexes.length; i++) {
            require(_indexes[i] < totalStakes, "COCKStaking: Invalid index");
            Stake storage stake = _stakes[_msgSender()][_indexes[i]];
            require(!stake.isWithdrawn, "COCKStaking: Already withdrawn");
            require(stake.withdrawalInitiatedAt == 0 || stake.withdrawalInitiatedAt + WITHDRAWAL_LOCK_PERIOD <= block.timestamp, "COCKStaking: Cannot withdraw before the unlock period");
            if (stake.withdrawalInitiatedAt == 0) {
                totalReward += _claimReward(_indexes[i]);
                totalLocked += stake.amount;
                stake.withdrawalInitiatedAt = block.timestamp;
            } else {
                totalWithdrawn += stake.amount;
                stake.isWithdrawn = true;
            }
        }
        if (totalLocked > 0) {
            current.totalDeposited -= totalLocked;
            _updateRewardFactor();
            current.lastDepositAt = block.timestamp;
        }
        if (totalWithdrawn > 0) {
            cocks.safeTransfer(_msgSender(), totalWithdrawn);
        }
        if (totalReward > 0) {
            totalClaimed += totalReward;
            usdc.safeTransfer(_msgSender(), totalReward);
        }
        emit Withdraw(_msgSender(), totalLocked, totalWithdrawn, totalReward);
    }

    /**
     * @notice Claim USDC rewards
     * @param _indexes A list of indexes corresponding to a user's stakes
     */
    function claimRewards(uint[] calldata _indexes) external nonReentrant {
        uint totalStakes = getTotalStakesByUser(_msgSender());
        uint totalReward;
        for (uint i; i < _indexes.length; i++) {
            require(_indexes[i] < totalStakes, "COCKStaking: Invalid index");
            uint reward = _claimReward(_indexes[i]);
            require(reward > 0, "COCKStaking: Nothing to claim for a specific stake");
            totalReward += reward;
        }
        usdc.safeTransfer(_msgSender(), totalReward);
        totalClaimed += totalReward;
        emit ClaimedReward(_msgSender(), totalReward);
    }

    /// @notice Distribute USDC and start the next epoch
    function distribute() external nonReentrant onlyDistributor {
        uint distributeInEpoch = currentEpoch;
        Epoch storage current = _epochs[distributeInEpoch];
        Epoch storage next = _epochs[distributeInEpoch + 1];
        require(current.startedAt + MIN_EPOCH_TIME <= block.timestamp, "COCKSStaking: A minimum of 6.5 days must elapse before distributing");
        uint reward = availableToDistribute();
        current.finishedAt = block.timestamp;
        if (current.totalDeposited > 0) {
            current.reward = reward;
            _updateRewardFactor();
            uint prevRewardFactor = distributeInEpoch > 0 ? _epochs[distributeInEpoch - 1].rewardFactor : 0;
            current.fullEpochRewardFactor += reward * (current.rewardFactor - prevRewardFactor) / (block.timestamp - current.firstDepositAt);
            totalDistributed += reward;

            /// @dev initialise next epoch based on current epoch
            next.firstDepositAt = block.timestamp;
            next.lastDepositAt = block.timestamp;
            next.totalDeposited = current.totalDeposited;
        }
        next.startedAt = block.timestamp;
        next.rewardFactor = current.rewardFactor;
        next.fullEpochRewardFactor += current.fullEpochRewardFactor;
        currentEpoch++;
        emit Distributed(distributeInEpoch, reward);
    }

    /**
     * @notice Calculate the amount available for distribution
     * @return uint Amount available to distribute
     */
    function availableToDistribute() public view returns (uint) {
        uint balance = usdc.balanceOf(address(this));
        uint unclaimedRewards = totalDistributed - totalClaimed;
        return balance - unclaimedRewards;
    }

    /**
     * @notice Get information about an epoch
     * @param _epoch Epoch
     * @return Epoch Epoch information
     */
    function getEpoch(uint _epoch) external view returns (Epoch memory) {
        require(_epoch <= currentEpoch, "COCKSStaking: _epoch does not exist");
        return _epochs[_epoch];
    }

    /**
     * @notice Get the address of the distributor
     * @return address Distributor
     */
    function getDistributor() external view returns (address) {
        return _distributor;
    }

    /**
     * @notice Get the total number of stakes made by a user (includes withdrawals)
     * @param _user User address
     * @return uint Total number of stakes made by _user
     */
    function getTotalStakesByUser(address _user) public view returns (uint) {
        require(_user != address(0), "COCKSStaking: _user is the zero address");
        return _stakes[_user].length;
    }

    /**
     * @notice Get a stake made by a user
     * @param _user User address
     * @param _index Index corresponding to a stake made by _user
     * @return Stake Staking information made by _user at index _index
     */
    function getStake(address _user, uint _index) public view returns (Stake memory) {
        uint total = getTotalStakesByUser(_user);
        require(_index < total, "COCKSStaking: _index does not exist for _user");
        return _stakes[_user][_index];
    }

    /**
     * @notice Get a list of stakes made by a user using a range of indexes
     * @param _user User address
     * @param _startIndex Start index corresponding to a stake
     * @param _endIndex End index corresponding to a stake
     * @return list A list of stakes for _user within the range of _startIndex to _endIndex
     */
    function getStakesByRange(address _user, uint _startIndex, uint _endIndex) public view returns (Stake[] memory list) {
        uint total = getTotalStakesByUser(_user);
        require(_startIndex <= _endIndex, "COCKSStaking: Start index must be less than or equal to end index");
        require(_endIndex - _startIndex + 1 <= MAX_ITERATIONS, "COCKSStaking: Range exceeds max iterations");
        require(_startIndex < total, "COCKSStaking: Invalid start index");
        require(_endIndex < total, "COCKSStaking: Invalid end index");
        list = new Stake[](_endIndex - _startIndex + 1);
        uint listIndex;
        for (uint i = _startIndex; i <= _endIndex; i++) {
            list[listIndex++] = _stakes[_user][i];
        }
        return list;
    }

    /**
     * @notice Get a list of stakes made by a user using a list of indexes
     * @param _user User address
     * @param _indexes A list of indexes
     * @return list A list of stakes made by _user based on _indexes
     */
    function getStakesByIndexes(address _user, uint[] calldata _indexes) public view returns (Stake[] memory list) {
        uint totalIterations = _indexes.length;
        uint total = getTotalStakesByUser(_user);
        require(totalIterations <= total && totalIterations <= MAX_ITERATIONS, "COCKSStaking: Invalid _indexes length");
        list = new Stake[](totalIterations);
        for (uint i; i < totalIterations; i++) {
            require(_indexes[i] < total, "COCKSStaking: _index does not exist for _user");
            list[i] = _stakes[_user][_indexes[i]];
        }
        return list;
    }

    /**
     * @notice Calculate the rewards earned by a user for a specific stake
     * @param _user User address
     * @param _index Index corresponding to a stake made by _user
     * @return uint Amount of rewards earned by _user at index _index
     */
    function calculateReward(address _user, uint _index) external view returns (uint) {
        uint total = getTotalStakesByUser(_user);
        require(_index < total, "COCKSStaking: _index does not exist for _user");
        return _calculateReward(_user, _index);
    }

    /**
     * @notice Calculate the rewards earned by a user for a range of stakes
     * @param _user User address
     * @param _startIndex Start index corresponding to a stake
     * @param _endIndex End index corresponding to a stake
     * @return totalRewards Total rewards earned by _user between _startIndex and _endIndex
     */
    function calculateRewardsByRange(address _user, uint _startIndex, uint _endIndex) external view returns (uint totalRewards) {
        uint total = getTotalStakesByUser(_user);
        require(_startIndex <= _endIndex, "COCKSStaking: Start index must be less than or equal to end index");
        require(_endIndex - _startIndex + 1 <= MAX_ITERATIONS, "COCKSStaking: Range exceeds max iterations");
        require(_startIndex < total, "COCKSStaking: Invalid start index");
        require(_endIndex < total, "COCKSStaking: Invalid end index");
        for (uint i = _startIndex; i <= _endIndex; i++) {
            totalRewards += _calculateReward(_user, i);
        }
        return totalRewards;
    }

    /**
     * @notice Calculate the rewards earned by a user for a list of stakes
     * @param _user User address
     * @param _indexes A list of indexes
     * @return totalRewards Total rewards earned by _user for _indexes
     */
    function calculateRewardsByIndexes(address _user, uint[] calldata _indexes) external view returns (uint totalRewards) {
        uint totalIterations = _indexes.length;
        uint total = getTotalStakesByUser(_user);
        require(totalIterations <= total && totalIterations <= MAX_ITERATIONS, "COCKSStaking: Invalid _indexes length");
        for (uint i; i < totalIterations; i++) {
            require(_indexes[i] < total, "COCKSStaking: _index does not exist for _user");
            totalRewards += _calculateReward(_user, _indexes[i]);
        }
        return totalRewards;
    }

    /// @param distributor_ Distributor address
    function _setDistributor(address distributor_) private {
        require(distributor_ != address(0), "COCKSStaking: distributor_ is the zero address");
        _distributor = distributor_;
    }

    function _updateRewardFactor() private {
        Epoch storage current = _epochs[currentEpoch];
        if (current.totalDeposited == 0) {
            current.rewardFactor = 0;
            current.firstDepositAt = 0;
        } else {
            current.rewardFactor += REWARD_PRECISION * (block.timestamp - current.lastDepositAt) / current.totalDeposited;
        }
    }

    /**
     * @param _index Index of stake to claim reward for
     * @return reward Reward earned for _index
     */
    function _claimReward(uint _index) private returns (uint reward) {
        Stake memory stake = _stakes[_msgSender()][_index];
        require(stake.withdrawalInitiatedAt == 0, "Already withdrawn or a withdrawal has been initiated");
        reward = _calculateReward(_msgSender(), _index);
        _stakes[_msgSender()][_index].claimedUpTill = currentEpoch;
        return reward;
    }

    /**
     * @param _user User address
     * @param _index Index of stake to calculate reward for
     * @return reward Reward earned for _user at stake index _index
     */
    function _calculateReward(address _user, uint _index) private view returns (uint reward) {
        Stake memory stake = _stakes[_user][_index];
        if (stake.withdrawalInitiatedAt == 0) {
            if (stake.claimedUpTill < currentEpoch) {
                if (stake.claimedUpTill == 0) {
                    reward += _calculateRewardsFromInitialEpoch(_user, _index);
                }
                return reward + _calculateRewardsFromSubsequentEpochs(_user, _index);
            }
        }
        return 0;
    }

    /**
     * @param _user User address
     * @param _index Index of stake to calculate initial epoch reward for
     * @return reward Reward earned for _user at stake index _index for their first epoch
     */
    function _calculateRewardsFromInitialEpoch(address _user, uint _index) private view returns (uint) {
        Stake memory stake = _stakes[_user][_index];
        /// @dev epoch has to have finished
        if (currentEpoch > stake.epoch) {
            Epoch memory epoch = _epochs[stake.epoch];
            uint rewardFactorDifference = epoch.rewardFactor - stake.epochRewardFactor;
            return epoch.reward * rewardFactorDifference * stake.amount / (epoch.finishedAt - epoch.firstDepositAt) / REWARD_PRECISION;
        }
        return 0;
    }

    /**
     * @param _user User address
     * @param _index Index of stake to calculate subsequent epoch rewards for
     * @return reward Reward earned for _user at stake index _index for epochs (excluding their first epoch for this stake)
     */
    function _calculateRewardsFromSubsequentEpochs(address _user, uint _index) private view returns (uint) {
        Stake memory stake = _stakes[_user][_index];
        if (currentEpoch > stake.epoch + 1) {
            /// @dev we take 1 from stake.claimedUpTill because we need the full epoch reward factor from the previous epoch
            Epoch memory start = stake.claimedUpTill > 0 ? _epochs[stake.claimedUpTill - 1] : _epochs[stake.epoch];
            /// @dev we look at the previous epoch because the current epoch won't have rewards
            Epoch memory prev = _epochs[currentEpoch - 1];
            uint rewardFactorDifference = prev.fullEpochRewardFactor - start.fullEpochRewardFactor;
            return stake.amount * rewardFactorDifference / REWARD_PRECISION;
        }
        return 0;
    }
}
