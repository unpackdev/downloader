pragma solidity 0.6.12;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

contract StakingPool is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;
    IERC20 public rewardToken;
    uint256 public startBlock;
    uint256 public lastRewardBlock;
    uint256 public finishBlock;
    uint256 public allStakedAmount;
    uint256 public allPaidReward;
    uint256 public allRewardDebt;
    uint256 public poolTokenAmount;
    uint256 public rewardPerBlock;
    uint256 public accTokensPerShare; // Accumulated tokens per share
    uint256 public participants; //Count of participants

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many tokens the user has staked.
        uint256 rewardDebt; // Reward debt
    }

    mapping (address => UserInfo) public userInfo;

    event FinishBlockUpdated(uint256 newFinishBlock);
    event PoolReplenished(uint256 amount);
    event TokensStaked(address indexed user, uint256 amount, uint256 reward);
    event StakeWithdrawn(address indexed user, uint256 amount, uint256 reward);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    event WithdrawPoolRemainder(address indexed user, uint256 amount);

    constructor(
        IERC20 _stakingToken,
        IERC20 _poolToken,
        uint256 _startBlock,
        uint256 _finishBlock,
        uint256 _poolTokenAmount
    ) public {
        stakingToken = _stakingToken;
        rewardToken = _poolToken;
        require(
            _startBlock < _finishBlock,
            "start block must be less than finish block"
        );
        require(
            _finishBlock > block.number,
            "finish block must be more than current block"
        );
        startBlock = _startBlock;
        lastRewardBlock = startBlock;
        finishBlock = _finishBlock;
        poolTokenAmount = _poolTokenAmount;
        rewardPerBlock = _poolTokenAmount.div(_finishBlock.sub(_startBlock));
    }

    function getMultiplier(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        if (_to <= finishBlock) {
            return _to.sub(_from);
        } else if (_from >= finishBlock) {
            return 0;
        } else {
            return finishBlock.sub(_from);
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 tempAccTokensPerShare = accTokensPerShare;
        if (block.number > lastRewardBlock && allStakedAmount != 0) {
            uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
            uint256 reward = multiplier.mul(rewardPerBlock);
            tempAccTokensPerShare = accTokensPerShare.add(
                reward.mul(1e18).div(allStakedAmount)
            );
        }
        return user.amount.mul(tempAccTokensPerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        if (allStakedAmount == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
        uint256 reward = multiplier.mul(rewardPerBlock);
        accTokensPerShare = accTokensPerShare.add(
            reward.mul(1e18).div(allStakedAmount)
        );
        lastRewardBlock = block.number;
    }

    function stakeTokens(uint256 _amountToStake) external nonReentrant{
        updatePool();
        uint256 pending = 0;
        UserInfo storage user = userInfo[msg.sender];
        if (user.amount > 0) {
            pending = transferPendingReward(user);
        }
        else{
            participants +=1;
        }

        if (_amountToStake > 0) {
            stakingToken.safeTransferFrom(msg.sender, address(this), _amountToStake);
            user.amount = user.amount.add(_amountToStake);
            allStakedAmount = allStakedAmount.add(_amountToStake);
        }

        allRewardDebt = allRewardDebt.sub(user.rewardDebt);
        user.rewardDebt = user.amount.mul(accTokensPerShare).div(1e18);
        allRewardDebt = allRewardDebt.add(user.rewardDebt);
        emit TokensStaked(msg.sender, _amountToStake, pending);
    }

    // Leave the pool. Claim back your tokens.
    // Unclocks the staked + gained tokens and burns pool shares
    function withdrawStake(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool();
        uint256 pending = transferPendingReward(user);

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            stakingToken.safeTransfer(msg.sender, _amount);
            if(user.amount == 0){
                participants -= 1;
            }
        }
        allRewardDebt = allRewardDebt.sub(user.rewardDebt);
        user.rewardDebt = user.amount.mul(accTokensPerShare).div(1e18);
        allRewardDebt = allRewardDebt.add(user.rewardDebt);
        allStakedAmount = allStakedAmount.sub(_amount);

        emit StakeWithdrawn(msg.sender, _amount, pending);
    }

    function transferPendingReward(UserInfo memory user) private returns (uint256) {
        uint256 pending = user.amount.mul(accTokensPerShare).div(1e18).sub(user.rewardDebt);

        if (pending > 0) {
            rewardToken.safeTransfer(msg.sender, pending);
            allPaidReward = allPaidReward.add(pending);
        }

        return pending;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external nonReentrant{
        UserInfo storage user = userInfo[msg.sender];
        if(user.amount > 0) {
            stakingToken.safeTransfer(msg.sender, user.amount);
            emit EmergencyWithdraw(msg.sender, user.amount);

            allStakedAmount = allStakedAmount.sub(user.amount);
            allRewardDebt = allRewardDebt.sub(user.rewardDebt);
            user.amount = 0;
            user.rewardDebt = 0;
            participants -= 1;
        }
    }


    function withdrawPoolRemainder() external onlyOwner nonReentrant{
        require(block.number > finishBlock, "Allow after finish");
        updatePool();
        uint256 pending = allStakedAmount.mul(accTokensPerShare).div(1e18).sub(allRewardDebt);
        uint256 returnAmount = poolTokenAmount.sub(allPaidReward).sub(pending);
        allPaidReward = allPaidReward.add(returnAmount);

        rewardToken.safeTransfer(msg.sender, returnAmount);
        emit WithdrawPoolRemainder(msg.sender, returnAmount);
    }
}
