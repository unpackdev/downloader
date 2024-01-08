// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./Errors.sol";
import "./IBentPool.sol";
import "./IBentPoolManager.sol";
import "./IConvexBooster.sol";
import "./IBaseRewardPool.sol";
import "./IConvexToken.sol";
import "./IVirtualBalanceRewardPool.sol";

contract BentSingleStaking is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event ClaimAll(address indexed user);
    event Claim(address indexed user, uint256[] pids);

    struct PoolData {
        address rewardToken;
        uint256 accRewardPerShare; // Accumulated Rewards per share, times 1e36. See below.
        uint256 rewardRate;
        uint256 reserves;
    }

    IERC20Upgradeable public bent;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    uint256 public rewardPoolsCount;
    mapping(uint256 => PoolData) public rewardPools;
    mapping(address => bool) public isRewardToken;
    mapping(uint256 => mapping(address => uint256)) internal userRewardDebt;
    mapping(uint256 => mapping(address => uint256)) internal userPendingRewards;

    uint256 public windowLength;
    uint256 public endRewardBlock; // end block of rewards stream
    uint256 public lastRewardBlock; // last block of rewards streamed

    function initialize(
        address _bent,
        address[] memory _rewardTokens,
        uint256 _windowLength // around 7 days
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        bent = IERC20Upgradeable(_bent);

        addRewardTokens(_rewardTokens);

        windowLength = _windowLength;
    }

    function addRewardTokens(address[] memory _rewardTokens) public onlyOwner {
        uint256 length = _rewardTokens.length;
        for (uint256 i = 0; i < length; i++) {
            require(!isRewardToken[_rewardTokens[i]], Errors.ALREADY_EXISTS);
            rewardPools[rewardPoolsCount + i].rewardToken = _rewardTokens[i];
            isRewardToken[_rewardTokens[i]] = true;
        }
        rewardPoolsCount += length;
    }

    function removeRewardToken(uint256 _index) external onlyOwner {
        require(_index < rewardPoolsCount, Errors.INVALID_INDEX);

        isRewardToken[rewardPools[_index].rewardToken] = false;
        delete rewardPools[_index];
    }

    function pendingReward(address user)
        external
        view
        returns (uint256[] memory pending)
    {
        uint256 _rewardPoolsCount = rewardPoolsCount;
        pending = new uint256[](_rewardPoolsCount);

        if (totalSupply != 0) {
            uint256[] memory addedRewards = _calcAddedRewards();
            for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
                PoolData memory pool = rewardPools[i];
                if (pool.rewardToken == address(0)) {
                    continue;
                }
                uint256 newAccRewardPerShare = pool.accRewardPerShare +
                    ((addedRewards[i] * 1e36) / totalSupply);

                pending[i] =
                    userPendingRewards[i][user] +
                    ((balanceOf[user] * newAccRewardPerShare) / 1e36) -
                    userRewardDebt[i][user];
            }
        }
    }

    function deposit(uint256 _amount) external nonReentrant {
        require(_amount != 0, Errors.ZERO_AMOUNT);

        _updateAccPerShare(true);

        bent.safeTransferFrom(msg.sender, address(this), _amount);

        _mint(msg.sender, _amount);

        _updateUserRewardDebt();

        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external nonReentrant {
        require(
            balanceOf[msg.sender] >= _amount && _amount != 0,
            Errors.INVALID_AMOUNT
        );

        _updateAccPerShare(true);

        _burn(msg.sender, _amount);

        // transfer to msg.sender
        bent.safeTransfer(msg.sender, _amount);

        _updateUserRewardDebt();

        emit Withdraw(msg.sender, _amount);
    }

    function claimAll() external virtual nonReentrant {
        _updateAccPerShare(true);

        bool claimed = false;
        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
            uint256 claimAmount = _claim(i);
            if (claimAmount > 0) {
                claimed = true;
            }
        }
        require(claimed, Errors.NO_PENDING_REWARD);

        _updateUserRewardDebt();

        emit ClaimAll(msg.sender);
    }

    function claim(uint256[] memory pids) external nonReentrant {
        _updateAccPerShare(true);

        bool claimed = false;
        for (uint256 i = 0; i < pids.length; ++i) {
            uint256 claimAmount = _claim(pids[i]);
            if (claimAmount > 0) {
                claimed = true;
            }
        }
        require(claimed, Errors.NO_PENDING_REWARD);

        _updateUserRewardDebt();

        emit Claim(msg.sender, pids);
    }

    function onReward() external nonReentrant {
        _updateAccPerShare(false);

        for (uint256 i = 0; i < rewardPoolsCount; ++i) {
            PoolData storage pool = rewardPools[i];
            if (pool.rewardToken == address(0)) {
                continue;
            }

            uint256 newRewards = IERC20Upgradeable(pool.rewardToken).balanceOf(
                address(this)
            ) - pool.reserves;
            if (endRewardBlock > lastRewardBlock) {
                pool.rewardRate =
                    (pool.rewardRate *
                        (endRewardBlock - lastRewardBlock) +
                        newRewards *
                        1e36) /
                    windowLength;
            } else {
                pool.rewardRate = (newRewards * 1e36) / windowLength;
            }

            pool.reserves += newRewards;
        }

        endRewardBlock = lastRewardBlock + windowLength;
    }

    // Internal Functions

    function _updateAccPerShare(bool withdrawReward) internal {
        uint256[] memory addedRewards = _calcAddedRewards();
        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
            PoolData storage pool = rewardPools[i];
            if (pool.rewardToken == address(0)) {
                continue;
            }

            if (totalSupply == 0) {
                pool.accRewardPerShare = block.number;
            } else {
                pool.accRewardPerShare +=
                    (addedRewards[i] * (1e36)) /
                    totalSupply;
            }

            if (withdrawReward) {
                uint256 pending = ((balanceOf[msg.sender] *
                    pool.accRewardPerShare) / 1e36) -
                    userRewardDebt[i][msg.sender];

                if (pending > 0) {
                    userPendingRewards[i][msg.sender] += pending;
                }
            }
        }

        lastRewardBlock = block.number;
    }

    function _calcAddedRewards()
        internal
        view
        returns (uint256[] memory addedRewards)
    {
        uint256 startBlock = endRewardBlock > lastRewardBlock + windowLength
            ? endRewardBlock - windowLength
            : lastRewardBlock;
        uint256 endBlock = block.number > endRewardBlock
            ? endRewardBlock
            : block.number;
        uint256 duration = endBlock > startBlock ? endBlock - startBlock : 0;

        uint256 _rewardPoolsCount = rewardPoolsCount;
        addedRewards = new uint256[](_rewardPoolsCount);
        for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
            addedRewards[i] = (rewardPools[i].rewardRate * duration) / 1e36;
        }
    }

    function _updateUserRewardDebt() internal {
        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
            if (rewardPools[i].rewardToken != address(0)) {
                userRewardDebt[i][msg.sender] =
                    (balanceOf[msg.sender] * rewardPools[i].accRewardPerShare) /
                    1e36;
            }
        }
    }

    function _claim(uint256 pid) internal returns (uint256 claimAmount) {
        claimAmount = userPendingRewards[pid][msg.sender];
        if (claimAmount > 0) {
            IERC20Upgradeable(rewardPools[pid].rewardToken).safeTransfer(
                msg.sender,
                claimAmount
            );
            rewardPools[pid].reserves -= claimAmount;
            userPendingRewards[pid][msg.sender] = 0;
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
}
