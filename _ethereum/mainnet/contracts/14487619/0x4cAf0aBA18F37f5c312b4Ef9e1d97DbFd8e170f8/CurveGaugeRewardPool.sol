// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.12;

import "./Math.sol";
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./IVirtualRewards.sol";

interface IGauge {
    function deposit(uint amount) external;

    function withdraw(uint amount) external;

    function claim_rewards() external;
}

interface ICrvMinter {
    function mint(address gauge) external;
}

contract CurveGaugeRewardPool is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    IERC20 public rewardToken;
    IERC20 public stakingToken;
    uint256 public constant duration = 7 days;

    address public operator;

    address public gauge;
    address public crvMinter;
    address public crv;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public queuedRewards = 0;
    uint256 public currentRewards = 0;
    uint256 public historicalRewards = 0;
    uint256 public constant newRewardRatio = 830;
    uint256 private _totalSupply;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) private _balances;

    address[] public extraRewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor() initializer {}

    function initialize(
        address gauge_,
        address minter_,
        address crv_,
        address stakingToken_
    ) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        gauge = gauge_;
        crvMinter = minter_;
        crv = crv_;
        stakingToken = IERC20(stakingToken_);
        rewardToken = IERC20(crv);

        setApprove();
    }

    function setApprove() public {
        stakingToken.approve(gauge, type(uint).max);
    }

    function setOperator(address op_) external onlyOwner {
        operator = op_;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function extraRewardsLength() external view returns (uint256) {
        return extraRewards.length;
    }

    function addExtraReward(address _reward) external onlyOwner {
        require(_reward != address(0), "!reward setting");

        extraRewards.push(_reward);
    }

    function clearExtraRewards() external onlyOwner {
        delete extraRewards;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "!authorized");
        _;
    }

    function claimCrv(address receiver) external onlyOperator {
        try ICrvMinter(crvMinter).mint(gauge) {
            IERC20(crv).safeTransfer(receiver, IERC20(crv).balanceOf(address(this)));
        } catch {}
    }

    function claimRewards() external onlyOperator {
        IGauge(gauge).claim_rewards();
    }

    function withdrawToken(address[] calldata tokens) external onlyOperator {
        for (uint i; i < tokens.length; i++) {
            IERC20(tokens[i]).safeTransfer(msg.sender, IERC20(tokens[i]).balanceOf(address(this)));
        }
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18 / totalSupply();
    }

    function earned(address account) public view returns (uint256) {
        return balanceOf(account) * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18 + rewards[account];
    }

    function stake(uint256 _amount) external returns (bool){
        stakeFor(msg.sender, _amount);
        return true;
    }

    function stakeAll() external returns (bool){
        uint256 balance = stakingToken.balanceOf(msg.sender);
        stakeFor(msg.sender, balance);
        return true;
    }

    function stakeFor(address _for, uint256 _amount)
    public
    updateReward(_for)
    returns (bool)
    {
        require(_amount > 0, 'RewardPool : Cannot stake 0');

        //also stake to linked rewards
        for (uint i = 0; i < extraRewards.length; i++) {
            IVirtualRewards(extraRewards[i]).stake(_for, _amount);
        }

        //give to _for
        _totalSupply += _amount;
        _balances[_for] += _amount;

        //take away from sender
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        IGauge(gauge).deposit(_amount);
        emit Staked(_for, _amount);

        return true;
    }

    function withdraw(uint256 amount, bool claim)
    public
    updateReward(msg.sender)
    returns (bool)
    {
        require(amount > 0, 'RewardPool : Cannot withdraw 0');

        //also withdraw from linked rewards
        for (uint i = 0; i < extraRewards.length; i++) {
            IVirtualRewards(extraRewards[i]).withdraw(msg.sender, amount);
        }

        _totalSupply -= amount;
        _balances[msg.sender] -= amount;

        if (claim) {
            getReward(msg.sender, true);
        }

        IGauge(gauge).withdraw(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);

        return true;
    }

    function withdrawAll(bool claim) external {
        withdraw(_balances[msg.sender], claim);
    }

    function getReward(address _account, bool _claimExtras) public updateReward(_account) returns (bool){
        uint256 reward = earned(_account);
        if (reward > 0) {
            rewards[_account] = 0;
            rewardToken.safeTransfer(_account, reward);
            emit RewardPaid(_account, reward);
        }

        //also get rewards from linked rewards
        if (_claimExtras) {
            for (uint i = 0; i < extraRewards.length; i++) {
                IVirtualRewards(extraRewards[i]).getReward(_account);
            }
        }
        return true;
    }

    function getRewards() external returns (bool) {
        getReward(msg.sender, true);
        return true;
    }

    function donate(uint256 _amount) external {
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
        queuedRewards += _amount;
    }

    function queueNewRewards(uint256 _rewards) external onlyOperator {
        _rewards += queuedRewards;

        if (block.timestamp >= periodFinish) {
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
            return;
        }

        //et = now - (finish-duration)
        uint256 elapsedTime = block.timestamp - (periodFinish - duration);
        //current at now: rewardRate * elapsedTime
        uint256 currentAtNow = rewardRate * elapsedTime;
        uint256 queuedRatio = currentAtNow * 1000 / _rewards;

        //uint256 queuedRatio = currentRewards.mul(1000).div(_rewards);
        if (queuedRatio < newRewardRatio) {
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
        } else {
            queuedRewards = _rewards;
        }
    }

    function notifyRewardAmount(uint256 reward)
    internal
    updateReward(address(0))
    {
        historicalRewards += reward;
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / duration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            reward += leftover;
            rewardRate = reward / duration;
        }
        currentRewards = reward;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + duration;
        emit RewardAdded(reward);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
    }
}
