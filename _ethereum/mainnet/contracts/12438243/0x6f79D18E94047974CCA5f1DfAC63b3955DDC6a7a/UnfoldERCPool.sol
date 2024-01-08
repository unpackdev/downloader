// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./Math.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

import "./PoolTokenWrapper.sol";

contract UnfoldERCPool is PoolTokenWrapper, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public rewardToken;
    uint256 public duration;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    mapping(address => uint256) public lastDepositTime;

    address payable public feeBeneficiar;

    uint256 public constant FEE_BASE = 10000;
    uint256 public constant minWithdrawFeeBp = 100;

    event FeeBeneficiarUpdated(address indexed beneficiar);
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(
        IERC20 _poolToken,
        IERC20 _rewardToken,
        uint256 _duration,
        address payable _feeBeneficiar
    ) public PoolTokenWrapper(_poolToken) {
        rewardToken = _rewardToken;
        duration = _duration;
        feeBeneficiar = _feeBeneficiar;
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

    function updateFeeBeneficiar(address payable _feeBeneficiar) external onlyOwner {
        require(_feeBeneficiar != address(0), 'UnfoldPool: fee beneficiar is 0x0');
        feeBeneficiar = _feeBeneficiar;
        emit FeeBeneficiarUpdated(_feeBeneficiar);
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

    function stake(uint256 _amount) public override updateReward(msg.sender) {
        require(_amount > 0, 'UnfoldPool: cannot stake 0');

        lastDepositTime[msg.sender] = block.timestamp;

        super.stake(_amount);

        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint256 _amount, uint256 _) public override updateReward(msg.sender) {
        require(_amount > 0, 'UnfoldPool: cannot withdraw 0');
        require(_amount == _, 'UnfoldPool: params should be eq');

        uint256 fee = calculateWithdrawalFeeBp(lastDepositTime[msg.sender]);
        uint256 feeAmount = calculateFee(fee, _amount);
        uint256 withdrawAmount = _amount.sub(feeAmount);

        poolToken.safeTransfer(feeBeneficiar, feeAmount);

        super.withdraw(_amount, withdrawAmount);

        emit Withdrawn(msg.sender, withdrawAmount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender), balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function addReward(uint256 reward) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(duration);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);
        emit RewardAdded(reward);
    }

    /// Applies the fee by subtracting fees from the amount and returns
    /// the amount after deducting the fee.
    /// @dev it calculates (1 - fee) * amount
    function applyFee(uint256 _feeInBips, uint256 _amount) internal pure returns (uint256) {
        return _amount.mul(FEE_BASE.sub(_feeInBips)).div(FEE_BASE);
    }

    /// Calculates the fee amount.
    /// @dev it calculates fee * amount
    function calculateFee(uint256 _feeInBips, uint256 _amount) internal pure returns (uint256) {
        return _amount.mul(_feeInBips).div(FEE_BASE);
    }

    /// Calculates withdrawal fee basis point.
    function calculateWithdrawalFeeBp(uint256 _despositTime) public view returns (uint256) {
        uint256 fee = minWithdrawFeeBp;
        uint256 depositDuration = block.timestamp.sub(_despositTime);

        if (depositDuration < 1 weeks) {
            fee = fee.mul(5);
        } else if (depositDuration >= 1 weeks && depositDuration < 2 weeks) {
            fee = fee.mul(4);
        } else if (depositDuration >= 2 weeks && depositDuration < 3 weeks) {
            fee = fee.mul(3);
        } else if (depositDuration >= 3 weeks && depositDuration < 4 weeks) {
            fee = fee.mul(2);
        }
        return fee;
    }
}
