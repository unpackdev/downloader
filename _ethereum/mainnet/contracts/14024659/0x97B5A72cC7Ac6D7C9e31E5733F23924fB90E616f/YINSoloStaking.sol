// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Ownable.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract YINSoloStaking is Ownable, ReentrancyGuard {
    using SafeMath for uint64;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct DepositInfo {
        uint256 amount;
        uint64 begin;
        uint64 until;
    }

    uint256 public constant MIN_LOCK_DURATION = 1 weeks;
    uint256 public immutable maxLockDuration;
    uint256 public startTime;
    uint256 public periodFinish;
    uint256 public totalReward;
    uint256 public accruedReward;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerShareStored;

    mapping(address => DepositInfo[]) public depositsOf;
    mapping(address => uint256) public rewardDebt;
    mapping(address => uint256) private _userShare;
    mapping(address => uint256) public userRewardPerSharePaid;
    uint256 private _totalShare;
    address public provider;
    IERC20 public depositToken;

    event Stake(uint256 amount, uint256 duration, address indexed from);
    event UnStake(
        uint256 depositId,
        address indexed from,
        address indexed receiver
    );
    event ClaimReward(address account, uint256 reward);
    event ModifyRewardRate(uint256 o, uint256 n);
    event ModifyPeriodFinish(uint256 o, uint256 n);
    event ModifyTotalReward(uint256 o, uint256 n);

    constructor(
        address _depositToken,
        address _provider,
        uint256 _rewardRate,
        uint256 _startTime,
        uint256 _totalReward,
        uint256 _maxLockDuration // 365 * 86400 seconds
    ) {
        depositToken = IERC20(_depositToken);
        provider = _provider;
        maxLockDuration = _maxLockDuration;
        rewardRate = _rewardRate;
        totalReward = _totalReward;
        accruedReward = 0;

        if (_startTime == 0) {
            _startTime = block.timestamp;
        }
        startTime = _startTime;
        lastUpdateTime = _startTime;
        periodFinish = _startTime.add(_maxLockDuration);
    }

    function totalShare() public view returns (uint256) {
        return _totalShare;
    }

    function userShare(address account) public view returns (uint256) {
        return _userShare[account];
    }

    function stake(uint256 amount, uint256 duration)
        external
        nonReentrant
        notifyUpdateReward(msg.sender)
    {
        require(amount > 0, "AM0");
        duration = Math.max(
            Math.min(duration, maxLockDuration),
            MIN_LOCK_DURATION
        );
        depositToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 shares = getMultiper(
            amount,
            block.timestamp,
            block.timestamp.add(duration)
        );
        _userShare[msg.sender] = shares;
        _totalShare = _totalShare.add(_userShare[msg.sender]);

        depositsOf[msg.sender].push(
            DepositInfo({
                amount: amount,
                begin: uint64(block.timestamp),
                until: uint64(block.timestamp) + uint64(duration)
            })
        );

        emit Stake(amount, duration, msg.sender);
    }

    function unstake(uint256 depositId, address receiver)
        external
        nonReentrant
        notifyUpdateReward(msg.sender)
    {
        require(depositId < depositsOf[msg.sender].length, "MISS");
        DepositInfo memory userDeposit = depositsOf[msg.sender][depositId];
        require(block.timestamp >= userDeposit.until, "EARLY");

        uint256 depositOfLength = getDepositsOfLength(msg.sender);
        depositsOf[msg.sender][depositId] = depositsOf[msg.sender][
            depositOfLength - 1
        ];
        depositsOf[msg.sender].pop();

        uint256 shares = getMultiper(
            userDeposit.amount,
            userDeposit.begin,
            userDeposit.until
        );
        _totalShare = _totalShare.sub(shares);
        _userShare[msg.sender] = _userShare[msg.sender].sub(shares);

        // return tokens
        depositToken.safeTransfer(receiver, userDeposit.amount);

        emit UnStake(depositId, msg.sender, receiver);
    }

    function claimReward()
        external
        nonReentrant
        notifyUpdateReward(msg.sender)
    {
        uint256 reward = Math.min(
            rewardDebt[msg.sender],
            totalReward.sub(accruedReward)
        );
        if (reward > 0) {
            rewardDebt[msg.sender] = 0;
            accruedReward = accruedReward.add(reward);
            depositToken.safeTransferFrom(provider, msg.sender, reward);
        }

        emit ClaimReward(msg.sender, reward);
    }

    function pendingReward(address account, uint256 depositId)
        external
        view
        returns (uint256)
    {
        DepositInfo memory userDeposit = depositsOf[account][depositId];
        uint256 shares = getMultiper(
            userDeposit.amount,
            userDeposit.begin,
            userDeposit.until
        );
        uint256 reward = earned(account);
        return reward.mul(shares).div(_userShare[account]);
    }

    function rewardPerShare() public view returns (uint256) {
        if (_totalShare == 0) {
            return rewardPerShareStored;
        }
        return
            rewardPerShareStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(3e18)
                    .div(_totalShare)
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            _userShare[account]
                .mul(rewardPerShare().sub(userRewardPerSharePaid[account]))
                .div(5e18)
                .add(rewardDebt[account]);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function getTotalDeposit(address account)
        public
        view
        returns (uint256 totalAmount)
    {
        for (uint256 idx; idx < depositsOf[account].length; idx++) {
            totalAmount += depositsOf[account][idx].amount;
        }
    }

    function getDepositsOf(address account)
        public
        view
        returns (DepositInfo[] memory)
    {
        return depositsOf[account];
    }

    function getDepositsOfLength(address account)
        public
        view
        returns (uint256)
    {
        return depositsOf[account].length;
    }

    function getMultiper(
        uint256 amount,
        uint256 _from,
        uint256 _to
    ) public view returns (uint256) {
        require(_to >= _from, "NEG");
        uint256 duration = _to.sub(_from);
        require(
            duration >= MIN_LOCK_DURATION && duration <= maxLockDuration,
            "DURATION"
        );
        return
            amount
                .mul(duration.mul(1e18).div(1 weeks).mul(2).div(100))
                .div(1e18)
                .add(amount);
    }

    function modifyRewardRate(uint256 _rewardRate) external onlyOwner {
        emit ModifyRewardRate(rewardRate, _rewardRate);
        rewardRate = _rewardRate;
    }

    function modifyPeriodFinish(uint256 _periodFinish) external onlyOwner {
        emit ModifyPeriodFinish(periodFinish, _periodFinish);
        periodFinish = _periodFinish;
    }

    function modifyTotalReward(uint256 _totalReward) external onlyOwner {
        emit ModifyTotalReward(totalReward, _totalReward);
        totalReward = _totalReward;
    }

    modifier notifyUpdateReward(address account) {
        rewardPerShareStored = rewardPerShare();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewardDebt[account] = earned(account);
            userRewardPerSharePaid[account] = rewardPerShareStored;
        }
        _;
    }
}
