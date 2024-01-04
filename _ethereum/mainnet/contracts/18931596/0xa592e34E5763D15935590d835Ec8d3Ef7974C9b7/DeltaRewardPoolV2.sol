// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Math.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IDeltaRewardPool.sol";

contract DeltaRewardPool is IDeltaRewardPool, Ownable, ReentrancyGuard {
    using Address for address;
    using SafeERC20 for IERC20;

    bool private initialized;

    uint256 public constant monthTime = 30 days;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 stakeTime; // month; limit = 36;
        uint256 stakeDuration;
        uint256 power; // How much weight the user has provided.
        uint256 reward; // Reward
        uint256 allReward; // Reward
        uint256 rewardPerTokenPaid;
    }
    address public devAddress;

    uint256 public constant MIN_DEPOSIT_AMOUNT = 0.00001 ether;
    uint256 public constant MIN_WITHDRAW_AMOUNT = 0.00001 ether;

    uint256 public constant basRate = 100000;
    uint256[] public stakeTimeRatio; // basRate = 100000; limit = 36;

    // tokens of the pool!
    address public rewardToken;
    address public stakedToken;

    // all reward for pool
    uint256 public totalReward;

    uint256 public curCycleStartTime;
    uint256 public startStakeTime;

    uint256 public poolSurplusReward;
    uint256 public curCycleReward;
    uint256 public nextCycleReward;
    uint256 public nextDuration;

    uint256 public cycleTimes;
    uint256 public periodFinish;

    uint256 public totalPower;
    uint256 public totalAmount;

    uint256 public rewardPerTokenStored;
    uint256 public lastUpdateTime;
    uint256 public rewardRate;

    // Info of each user that stakes tokens.
    mapping(address => UserInfo) public userInfo;

    event Stake(
        address indexed user,
        uint256 amount,
        uint256 power,
        uint256 duration
    );

    event Withdraw(
        address indexed user,
        uint256 punish,
        uint256 amount,
        uint256 power
    );
    event Harvest(address indexed user, uint256 amount);
    event SetStakeTimeRatio(uint256[] _stakeTimeRatio);
    event AddStakeTimeRatio(uint256[] _stakeTimeRatio);
    event AddNextCycleReward(uint256 rewardAmount);
    event SetRewardConfig(uint256 nextCycleReward, uint256 nextDuration);
    event StartNewEpoch(uint256 reward, uint256 duration);

    function initialize(
        address _owner,
        address _devAddress,
        address _rewardToken,
        address _stakedToken,
        uint256 _curCycleStartTime,
        uint256 _duration,
        uint256 _nextCycleReward,
        uint256[] memory _stakeTimeRatio
    ) external {
        require(!initialized, "initialize: Already initialized!");
        _transferOwnership(_owner);

        devAddress = _devAddress;

        rewardToken = _rewardToken;
        stakedToken = _stakedToken;
        curCycleStartTime = _curCycleStartTime - _duration; // start time - duration
        periodFinish = _curCycleStartTime;
        nextDuration = _duration;
        startStakeTime = periodFinish;
        nextCycleReward = _nextCycleReward;
        stakeTimeRatio = _stakeTimeRatio;

        initialized = true;
    }

    //for reward
    function notifyMintAmount(uint256 addNextReward) external onlyOwner {
        uint256 balanceBefore = IERC20(rewardToken).balanceOf(address(this));
        IERC20(rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            addNextReward
        );
        uint256 balanceEnd = IERC20(rewardToken).balanceOf(address(this));

        poolSurplusReward = poolSurplusReward + (balanceEnd - balanceBefore);
        emit AddNextCycleReward(poolSurplusReward);
    }

    function setNextCycleReward(
        uint256 _nextCycleReward,
        uint256 _nextDuration
    ) external onlyOwner {
        nextCycleReward = _nextCycleReward;
        nextDuration = _nextDuration;
        emit SetRewardConfig(nextCycleReward, nextDuration);
    }

    function setStakeTimeRatio(
        uint256[] memory _stakeTimeRatio
    ) external onlyOwner {
        stakeTimeRatio = _stakeTimeRatio;
        emit SetStakeTimeRatio(_stakeTimeRatio);
    }

    function addStakeTimeRatio(
        uint256[] memory _stakeTimeRatio
    ) external onlyOwner {
        for (uint256 i = 0; i < _stakeTimeRatio.length; i++) {
            stakeTimeRatio.push(_stakeTimeRatio[i]);
        }
        emit AddStakeTimeRatio(_stakeTimeRatio);
    }

    modifier checkNextEpoch() {
        if (block.timestamp >= periodFinish) {
            curCycleReward = nextCycleReward;
            require(
                poolSurplusReward >= nextCycleReward,
                "poolSurplusReward is not enough"
            );
            poolSurplusReward = poolSurplusReward - nextCycleReward;
            curCycleStartTime = block.timestamp;
            periodFinish = block.timestamp + (nextDuration);
            cycleTimes++;
            lastUpdateTime = curCycleStartTime;
            rewardRate = curCycleReward / (nextDuration);
            totalReward = totalReward + (curCycleReward);
            emit StartNewEpoch(curCycleReward, nextDuration);
        }
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            UserInfo storage user = userInfo[account];
            user.reward = earned(account);
            user.rewardPerTokenPaid = rewardPerTokenStored;
        }
        _;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((lastTimeRewardApplicable() - lastUpdateTime) *
                rewardRate *
                1e18) / totalSupply());
    }

    function stake(
        uint256 _amount,
        uint256 _durationType
    ) external checkNextEpoch updateReward(msg.sender) nonReentrant {
        // check stake amount
        require(block.timestamp >= startStakeTime, "not start");
        require(_amount > 0, "Cannot stake 0");
        require(_durationType > 0, "stake time is too short");
        require(_durationType <= 36, "stake time is too long");
        UserInfo storage user = userInfo[msg.sender];
        if (user.amount == 0 || _amount > 0) {
            require(
                _amount > MIN_DEPOSIT_AMOUNT,
                "Deposit amount must be greater than MIN_DEPOSIT_AMOUNT"
            );
        }

        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            safeTokenTransfer(msg.sender, reward);
            user.allReward = user.allReward + (reward);
            user.reward = 0;
            emit Harvest(msg.sender, reward);
        }

        // check duration
        if (
            user.stakeTime + (user.stakeDuration * (monthTime)) >=
            block.timestamp
        ) {
            uint256 lockDuration = user.stakeTime +
                (user.stakeDuration * (monthTime)) -
                (block.timestamp);
            require(
                _durationType * (monthTime) >= lockDuration,
                "Can only increase staked duration"
            );
        }

        // transfer token to this contract
        uint256 balanceBefore = IERC20(stakedToken).balanceOf(address(this));
        IERC20(stakedToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        uint256 balanceEnd = IERC20(stakedToken).balanceOf(address(this));
        uint256 currentAmount = balanceEnd - balanceBefore;
        // uint256 stakePower = (currentAmount * (stakeTimeRatio[_durationType])) /
        //     (basRate);

        // update user info
        uint256 beforePower = user.power;
        user.amount = user.amount + (currentAmount);
        user.stakeTime = block.timestamp;
        user.stakeDuration = _durationType;
        // user.power = user.power + (stakePower);

        uint256 userPower = (user.amount * (stakeTimeRatio[_durationType])) /
            (basRate);
        user.power = userPower;

        // update total info
        totalAmount = totalAmount + (currentAmount);
        totalPower = totalPower - beforePower + (userPower);

        // emit Stake(msg.sender, currentAmount, stakePower, _durationType);
        emit Stake(
            msg.sender,
            currentAmount,
            userPower - beforePower,
            _durationType
        );
    }

    function fixUpdateUserPower(
        address user
    ) external onlyOwner updateReward(user) {
        UserInfo storage updateUser = userInfo[user];
        uint256 beforePower = updateUser.power;
        uint256 userPower = (updateUser.amount *
            (stakeTimeRatio[updateUser.stakeDuration])) / (basRate);
        updateUser.power = userPower;
        totalPower = totalPower - beforePower + (userPower);
    }

    // Withdraw without caring about punish
    function withdraw(
        uint256 amount
    ) external checkNextEpoch updateReward(msg.sender) nonReentrant {
        require(
            amount > MIN_WITHDRAW_AMOUNT,
            "Withdraw amount must be greater than MIN_WITHDRAW_AMOUNT"
        );
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount > 0, "no stake amount");
        require(user.amount >= amount, "Overdrawing");

        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            safeTokenTransfer(msg.sender, reward);
            user.allReward = user.allReward + (reward);
            user.reward = 0;
            emit Harvest(msg.sender, reward);
        }

        // calculate withdraw power
        uint256 withdrawPower = (amount *
            (stakeTimeRatio[user.stakeDuration])) / (basRate);

        // update user info
        user.amount = user.amount - amount;
        user.power = user.power - withdrawPower;

        // update total info
        totalAmount = totalAmount - amount;
        totalPower = totalPower - withdrawPower;

        uint256 punish = punishStake(msg.sender, amount);
        // transfer token to user
        if (punish > 0) {
            IERC20(stakedToken).safeTransfer(devAddress, punish);
        }

        IERC20(stakedToken).safeTransfer(msg.sender, amount - punish);

        emit Withdraw(msg.sender, punish, amount, withdrawPower);
    }

    // (1-(lockTime/stakeTime))*10%
    function punishStake(
        address user,
        uint256 withdrawAmount
    ) public view returns (uint256) {
        UserInfo memory _userInfo = userInfo[user];
        uint256 stakeTime = _userInfo.stakeTime;
        uint256 _stakeDuration = _userInfo.stakeDuration;
        uint256 shouldDuration = _stakeDuration * monthTime;
        uint256 stopStake = stakeTime + shouldDuration;
        if (stopStake > block.timestamp) {
            uint256 lockTime = block.timestamp - stakeTime;
            uint256 punishRatio = (((1e18 -
                ((lockTime * 1e18) / shouldDuration)) * 10) / 100);
            return (punishRatio * withdrawAmount) / 1e18;
        } else {
            return 0;
        }
    }

    function harvest()
        external
        checkNextEpoch
        updateReward(msg.sender)
        nonReentrant
    {
        uint256 reward = earned(msg.sender);
        require(reward > 0, "no reward");
        safeTokenTransfer(msg.sender, reward);
        UserInfo storage user = userInfo[msg.sender];
        user.allReward = user.allReward + (reward);
        user.reward = 0;
        emit Harvest(msg.sender, reward);
    }

    function lastTimeRewardApplicable() internal view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function earned(address account) public view returns (uint256) {
        UserInfo memory user = userInfo[account];
        return
            (user.power * (rewardPerToken() - (user.rewardPerTokenPaid))) /
            (1e18) +
            (user.reward);
    }

    function totalSupply() public view returns (uint256) {
        return totalPower;
    }

    function getUserStakeInfo(
        address user
    )
        external
        view
        override
        returns (
            uint256 power,
            uint256 amount,
            uint256 stakeTime,
            uint256 stakeDuration
        )
    {
        UserInfo memory _userInfo = userInfo[user];

        power = _userInfo.power;
        amount = _userInfo.amount;
        stakeTime = _userInfo.stakeTime;
        stakeDuration = _userInfo.stakeDuration;
    }

    // Safe slt transfer function, just in case if rounding error causes pool to not have enough SLTs.
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        require(rewardToken != address(0x0), "No harvest began");
        uint256 tokenBalance = IERC20(rewardToken).balanceOf(address(this));
        if (_amount > tokenBalance) {
            IERC20(rewardToken).transfer(_to, tokenBalance);
        } else {
            IERC20(rewardToken).transfer(_to, _amount);
        }
    }
}
