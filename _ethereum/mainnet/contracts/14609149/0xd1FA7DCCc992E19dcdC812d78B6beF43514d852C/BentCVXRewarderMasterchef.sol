// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./Errors.sol";
import "./IBentCVXRewarder.sol";

contract BentCVXRewarderMasterchef is
    Ownable,
    ReentrancyGuard,
    IBentCVXRewarder
{
    using SafeERC20 for IERC20;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event ClaimAll(address indexed user);
    event Claim(address indexed user, uint256[] pids);

    struct PoolData {
        address rewardToken;
        uint256 accRewardPerShare; // Accumulated Rewards per share, times 1e36. See below.
    }

    address public bentCVXStaking;

    // BENT tokens reward settings
    uint256 public rewardPerBlock;
    uint256 public maxRewardPerBlock;
    uint256 public lastRewardBlock;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    uint256 public rewardPoolsCount;
    mapping(uint256 => PoolData) public rewardPools;
    mapping(uint256 => mapping(address => uint256)) internal userRewardDebt;
    mapping(uint256 => mapping(address => uint256)) internal userPendingRewards;

    modifier onlyBentCVXStaking() {
        require(bentCVXStaking == _msgSender(), Errors.UNAUTHORIZED);
        _;
    }

    constructor(
        address _bent,
        address _bentCVXStaking,
        uint256 _rewardPerBlock
    ) Ownable() ReentrancyGuard() {
        bentCVXStaking = _bentCVXStaking;
        // rewardPerBlock at deployment will be max reward per block
        maxRewardPerBlock = _rewardPerBlock;
        rewardPerBlock = _rewardPerBlock;
        lastRewardBlock = block.number;

        rewardPools[rewardPoolsCount].rewardToken = _bent;
        rewardPoolsCount = 1;
    }

    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(
            _rewardPerBlock <= maxRewardPerBlock,
            Errors.INVALID_REWARD_PER_BLOCK
        );

        _updateAccPerShare(false, address(0));

        rewardPerBlock = _rewardPerBlock;
    }

    function pendingReward(address user)
        external
        view
        returns (uint256[] memory pending)
    {
        uint256 _rewardPoolsCount = rewardPoolsCount;
        pending = new uint256[](_rewardPoolsCount);

        if (totalSupply != 0) {
            for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
                PoolData memory pool = rewardPools[i];
                if (pool.rewardToken == address(0)) {
                    continue;
                }
                uint256 bentReward = (block.number - lastRewardBlock) *
                    rewardPerBlock;
                uint256 newAccRewardPerShare = pool.accRewardPerShare +
                    ((bentReward * 1e36) / totalSupply);

                pending[i] =
                    userPendingRewards[i][user] +
                    ((balanceOf[user] * newAccRewardPerShare) / 1e36) -
                    userRewardDebt[i][user];
            }
        }
    }

    function deposit(address _user, uint256 _amount)
        external
        override
        onlyBentCVXStaking
    {
        require(_amount != 0, Errors.ZERO_AMOUNT);

        _updateAccPerShare(true, _user);

        _mint(_user, _amount);

        _updateUserRewardDebt(_user);

        emit Deposit(_user, _amount);
    }

    function withdraw(address _user, uint256 _amount)
        external
        override
        onlyBentCVXStaking
    {
        require(
            balanceOf[_user] >= _amount && _amount != 0,
            Errors.INVALID_AMOUNT
        );

        _updateAccPerShare(true, _user);

        _burn(_user, _amount);

        _updateUserRewardDebt(_user);

        emit Withdraw(_user, _amount);
    }

    function claimAll(address _user)
        external
        override
        nonReentrant
        returns (bool claimed)
    {
        _updateAccPerShare(true, _user);

        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
            uint256 claimAmount = _claim(i, _user);
            if (claimAmount > 0) {
                claimed = true;
            }
        }

        _updateUserRewardDebt(_user);

        emit ClaimAll(_user);
    }

    function claim(address _user, uint256[] memory pids)
        external
        override
        nonReentrant
        returns (bool claimed)
    {
        _updateAccPerShare(true, _user);

        for (uint256 i = 0; i < pids.length; ++i) {
            uint256 claimAmount = _claim(pids[i], _user);
            if (claimAmount > 0) {
                claimed = true;
            }
        }

        _updateUserRewardDebt(_user);

        emit Claim(_user, pids);
    }

    // Internal Functions

    function _updateAccPerShare(bool withdrawReward, address user) internal {
        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
            PoolData storage pool = rewardPools[i];
            if (pool.rewardToken == address(0)) {
                continue;
            }

            if (totalSupply == 0) {
                pool.accRewardPerShare = block.number;
            } else {
                uint256 bentReward = (block.number - lastRewardBlock) *
                    rewardPerBlock;
                pool.accRewardPerShare += (bentReward * (1e36)) / totalSupply;
            }

            if (withdrawReward) {
                uint256 pending = ((balanceOf[user] * pool.accRewardPerShare) /
                    1e36) - userRewardDebt[i][user];

                if (pending > 0) {
                    userPendingRewards[i][user] += pending;
                }
            }
        }

        lastRewardBlock = block.number;
    }

    function _updateUserRewardDebt(address user) internal {
        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
            if (rewardPools[i].rewardToken != address(0)) {
                userRewardDebt[i][user] =
                    (balanceOf[user] * rewardPools[i].accRewardPerShare) /
                    1e36;
            }
        }
    }

    function _claim(uint256 pid, address user)
        internal
        returns (uint256 claimAmount)
    {
        require(pid < rewardPoolsCount, Errors.INVALID_PID);

        if (rewardPools[pid].rewardToken != address(0)) {
            claimAmount = userPendingRewards[pid][user];
            if (claimAmount > 0) {
                IERC20(rewardPools[pid].rewardToken).safeTransfer(
                    user,
                    claimAmount
                );
                userPendingRewards[pid][user] = 0;
            }
        }
    }

    function _mint(address _user, uint256 _amount) internal {
        balanceOf[_user] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _user, uint256 _amount) internal {
        balanceOf[_user] -= _amount;
        totalSupply -= _amount;
    }

    // owner can force withdraw bent tokens
    function forceWithdrawBent(uint256 _amount) external onlyOwner {
        // bent reward index is zero
        IERC20(rewardPools[0].rewardToken).safeTransfer(msg.sender, _amount);
    }
}
