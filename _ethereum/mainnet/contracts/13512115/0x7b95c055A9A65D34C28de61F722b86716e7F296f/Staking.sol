// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
pragma abicoder v2;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./SafeCastUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";

/// @title Snowswap Boosted Staking Contract
/// @author Daniel Lee
/// @notice You can use this contract for staking LP tokens
/// @dev All function calls are currently implemented without side effects
contract Staking is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCastUpgradeable for int256;
    using SafeCastUpgradeable for uint256;

    /// @notice Info of each user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of reward entitled to the user.
    /// `lastDepositedAt` The timestamp of the last deposit.
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
        uint256 lastDepositedAt;
    }

    uint256 private constant ACC_REWARD_PRECISION = 1e12;

    /// @notice Address of reward token contract.
    IERC20Upgradeable public rewardToken;

    /// @notice Address of the LP token.
    IERC20Upgradeable public lpToken;

    /********************** Staking params ***********************/

    /// @notice Reward treasury
    address public rewardTreasury;

    /// @notice Lockup period
    uint256 public lockPeriod;

    /// @notice Timestamp to disable locking
    uint256 public endTime;

    /// @notice Amount of reward token allocated per second.
    uint256 public rewardPerSecond;

    /********************** Staking status ***********************/

    /// @notice reward amount allocated per LP token.
    uint256 public accRewardPerShare;

    /// @notice Last time that the reward is calculated.
    uint256 public lastRewardTime;

    /// @notice Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 amount, address indexed to);
    event EmergencyWithdraw(
        address indexed user,
        uint256 amount,
        address indexed to
    );
    event Harvest(address indexed user, uint256 amount);

    event LogUpdatePool(
        uint256 lastRewardTime,
        uint256 lpSupply,
        uint256 accRewardPerShare
    );
    event LogRewardPerSecond(uint256 rewardPerSecond);
    event LogLockPeriod(uint256 lockPeriod);
    event LogEndTime(uint256 endTime);
    event LogRewardTreasury(address indexed wallet);

    modifier whilePoolOpen() {
        require(block.timestamp < endTime - lockPeriod, "Pool is closed");
        _;
    }

    /**
     * @param _rewardToken The reward token contract address.
     * @param _lpToken The LP token contract address.
     */
    function initialize(
        IERC20Upgradeable _rewardToken,
        IERC20Upgradeable _lpToken,
        uint256 _lockPeriod
    ) external initializer {
        require(
            address(_rewardToken) != address(0),
            "initialize: reward token address cannot be zero"
        );
        require(
            address(_lpToken) != address(0),
            "initialize: LP token address cannot be zero"
        );

        __Ownable_init();

        rewardToken = _rewardToken;
        lpToken = _lpToken;
        lastRewardTime = block.timestamp;
        lockPeriod = _lockPeriod;
        accRewardPerShare = 0;
    }

    /**
     * @notice Set the lockPeriod
     * @param _lockPeriod The new lockPeriod
     */
    function setLockPeriod(uint256 _lockPeriod) external onlyOwner {
        lockPeriod = _lockPeriod;
        emit LogLockPeriod(_lockPeriod);
    }

    /**
     * @notice Set the endTime
     * @param _endTime The new endTime
     */
    function setEndTime(uint256 _endTime) external onlyOwner {
        endTime = _endTime;
        emit LogEndTime(_endTime);
    }

    /**
     * @notice Sets the reward per second to be distributed. Can only be called by the owner.
     * @dev Its decimals count is ACC_REWARD_PRECISION
     * @param _rewardPerSecond The amount of reward to be distributed per second.
     */
    function setRewardPerSecond(uint256 _rewardPerSecond) public onlyOwner {
        updatePool();
        rewardPerSecond = _rewardPerSecond;
        emit LogRewardPerSecond(_rewardPerSecond);
    }

    /**
     * @notice set reward wallet
     * @param _wallet address that contains the rewards
     */
    function setRewardTreasury(address _wallet) external onlyOwner {
        rewardTreasury = _wallet;
        emit LogRewardTreasury(_wallet);
    }

    /**
     * @notice return available reward amount
     * @return rewardInTreasury reward amount in treasury
     * @return rewardAllowedForThisPool allowed reward amount to be spent by this pool
     */
    function availableReward()
        public
        view
        returns (uint256 rewardInTreasury, uint256 rewardAllowedForThisPool)
    {
        rewardInTreasury = rewardToken.balanceOf(rewardTreasury);
        rewardAllowedForThisPool = rewardToken.allowance(
            rewardTreasury,
            address(this)
        );
    }

    /**
     * @notice View function to see pending reward on frontend.
     * @dev It doens't update accRewardPerShare, it's just a view function.
     *
     *  pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
     *
     * @param _user Address of user.
     * @return pending reward for a given user.
     */
    function pendingReward(address _user)
        external
        view
        returns (uint256 pending)
    {
        UserInfo storage user = userInfo[_user];
        uint256 lpSupply = lpToken.balanceOf(address(this));
        uint256 accRewardPerShare_ = accRewardPerShare;

        if (block.timestamp > lastRewardTime && lpSupply != 0) {
            uint256 newReward = (block.timestamp - lastRewardTime) *
                rewardPerSecond;
            accRewardPerShare_ =
                accRewardPerShare_ +
                ((newReward * ACC_REWARD_PRECISION) / lpSupply);
        }
        pending = (((user.amount * accRewardPerShare_) / ACC_REWARD_PRECISION)
            .toInt256() - user.rewardDebt).toUint256();
    }

    /**
     * @notice Update reward variables.
     * @dev Updates accRewardPerShare and lastRewardTime.
     */
    function updatePool() public {
        if (block.timestamp > lastRewardTime) {
            uint256 lpSupply = lpToken.balanceOf(address(this));
            if (lpSupply > 0) {
                uint256 newReward = (block.timestamp - lastRewardTime) *
                    rewardPerSecond;
                accRewardPerShare =
                    accRewardPerShare +
                    ((newReward * ACC_REWARD_PRECISION) / lpSupply);
            }
            lastRewardTime = block.timestamp;
            emit LogUpdatePool(lastRewardTime, lpSupply, accRewardPerShare);
        }
    }

    /**
     * @notice Deposit LP tokens for staking.
     * @param amount LP token amount to deposit.
     * @param to The receiver of `amount` deposit benefit.
     */
    function deposit(uint256 amount, address to) public whilePoolOpen {
        updatePool();
        UserInfo storage user = userInfo[to];

        // Effects
        user.lastDepositedAt = block.timestamp;
        user.amount = user.amount + amount;
        user.rewardDebt =
            user.rewardDebt +
            ((amount * accRewardPerShare) / ACC_REWARD_PRECISION).toInt256();

        emit Deposit(msg.sender, amount, to);

        lpToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Withdraw LP tokens and harvest rewards to `to`.
     * @param amount LP token amount to withdraw.
     * @param to Receiver of the LP tokens and rewards.
     */
    function withdraw(uint256 amount, address to) public {
        UserInfo storage user = userInfo[msg.sender];
        require(
            user.lastDepositedAt + lockPeriod < block.timestamp,
            "Withdraw: Can't withdraw in lock period"
        );

        updatePool();
        int256 accumulatedReward = ((user.amount * accRewardPerShare) /
            ACC_REWARD_PRECISION).toInt256();
        uint256 _pendingReward = (accumulatedReward - user.rewardDebt)
            .toUint256();

        // Effects
        user.rewardDebt =
            accumulatedReward -
            ((amount * accRewardPerShare) / ACC_REWARD_PRECISION).toInt256();
        user.amount = user.amount - amount;

        emit Withdraw(msg.sender, amount, to);
        emit Harvest(msg.sender, _pendingReward);

        // Interactions
        rewardToken.safeTransferFrom(rewardTreasury, to, _pendingReward);
        lpToken.safeTransfer(to, amount);
    }

    /**
     * @notice Harvest rewards and send to `to`.
     * @dev Here comes the formula to calculate reward token amount
     * @param to Receiver of rewards.
     */
    function harvest(address to) public {
        UserInfo storage user = userInfo[msg.sender];
        require(
            user.lastDepositedAt + lockPeriod < block.timestamp,
            "Harvest: Can't harvest in lock period"
        );

        updatePool();
        int256 accumulatedReward = ((user.amount * accRewardPerShare) /
            ACC_REWARD_PRECISION).toInt256();
        uint256 _pendingReward = (accumulatedReward - user.rewardDebt)
            .toUint256();

        // Effects
        user.rewardDebt = accumulatedReward;

        emit Harvest(msg.sender, _pendingReward);

        // Interactions
        if (_pendingReward != 0) {
            rewardToken.safeTransferFrom(rewardTreasury, to, _pendingReward);
        }
    }

    /**
     * @notice Withdraw without caring about rewards. EMERGENCY ONLY.
     * @param to Receiver of the LP tokens.
     */
    function emergencyWithdraw(address to) public {
        UserInfo storage user = userInfo[msg.sender];
        require(
            user.lastDepositedAt + lockPeriod < block.timestamp,
            "EmergencyWithdraw: Can't withdraw in lock period"
        );

        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        emit EmergencyWithdraw(msg.sender, amount, to);

        // Note: transfer can fail or succeed if `amount` is zero.
        lpToken.safeTransfer(to, amount);
    }

    function renounceOwnership() public override onlyOwner {
        revert();
    }
}
