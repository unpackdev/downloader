pragma solidity ^0.5.0;

import "./Math.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./IRewardDistributionRecipient.sol";


contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public token;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(address _token) public {
        token = IERC20(_token);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stakeFor(address _user, uint256 _amount) public {
        _stake(_user, _amount);
    }

    function stake(uint256 _amount) public {
        _stake(msg.sender, _amount);
    }

    function approve(address _user, uint256 _amount) public {
        _approve(msg.sender, _user, _amount);
    }

    function withdraw(uint256 _amount) public {
        _withdraw(msg.sender, _amount);
    }

    function withdrawFrom(address _user, uint256 _amount) public {
        _withdraw(_user, _amount);
        _approve(
            _user,
            msg.sender,
            _allowances[_user][msg.sender].sub(_amount, "LPTokenWrapper: withdraw amount exceeds allowance")
        );
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return _allowances[_owner][_spender];
    }

    function _stake(address _user, uint256 _amount) internal {
        _totalSupply = _totalSupply.add(_amount);
        _balances[_user] = _balances[_user].add(_amount);
        token.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function _withdraw(address _owner, uint256 _amount) internal {
        _totalSupply = _totalSupply.sub(_amount);
        _balances[_owner] = _balances[_owner].sub(_amount);
        IERC20(token).safeTransfer(msg.sender, _amount);
    }

    function _approve(
        address _owner,
        address _user,
        uint256 _amount
    ) internal returns (bool) {
        require(_user != address(0), "LPTokenWrapper: approve to the zero address");
        _allowances[_owner][_user] = _amount;
        emit Approval(_owner, _user, _amount);
        return true;
    }
}


contract ModifiedUnipool is LPTokenWrapper, IRewardDistributionRecipient {
    address public rewardToken;
    uint256 public constant DURATION = 7 days;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    constructor(address _rewardToken, address _token) public LPTokenWrapper(_token) {
        rewardToken = _rewardToken;
    }

    function notifyRewardAmount(uint256 reward) external onlyRewardDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward(msg.sender);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account).mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(
                rewards[account]
            );
    }

    function stake(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function stakeFor(address _user, uint256 _amount) public updateReward(_user) {
        require(_amount > 0, "Cannot stake 0");
        super.stakeFor(_user, _amount);
        emit Staked(_user, _amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function withdrawFrom(address _user, uint256 amount) public updateReward(_user) {
        require(amount > 0, "Cannot withdraw 0");
        super.withdrawFrom(_user, amount);
        emit Withdrawn(_user, amount);
    }

    function getReward() public {
        _getReward(msg.sender);
    }

    function getReward(address _user) public {
        _getReward(_user);
    }

    function _getReward(address _user) internal updateReward(_user) {
        uint256 reward = earned(_user);
        if (reward > 0) {
            rewards[_user] = 0;
            IERC20(rewardToken).safeTransfer(_user, reward);
            emit RewardPaid(_user, reward);
        }
    }
}
