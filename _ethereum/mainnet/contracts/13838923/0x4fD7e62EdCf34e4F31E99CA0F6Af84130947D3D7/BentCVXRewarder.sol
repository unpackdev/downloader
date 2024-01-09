// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./Errors.sol";
import "./IBentCVXRewarder.sol";
import "./IBentCVX.sol";

contract BentCVXRewarder is OwnableUpgradeable, ReentrancyGuardUpgradeable, IBentCVXRewarder {
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

    address public cvx;
    address public bentCVX;
    address public bentCVXStaking;

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

    modifier onlyBentCVXStaking() {
        require(bentCVXStaking == _msgSender(), Errors.UNAUTHORIZED);
        _;
    }

    function initialize(
        address _cvx,
        address _bentCVX,
        address _bentCVXStaking,
        address[] memory _rewardTokens,
        uint256 _windowLength // around 7 days
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        cvx = _cvx;
        bentCVX = _bentCVX;
        bentCVXStaking = _bentCVXStaking;

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

    function onReward() external {
        _updateAccPerShare(false, address(0));

        bool newRewardsAvailable = false;
        for (uint256 i = 0; i < rewardPoolsCount; ++i) {
            PoolData storage pool = rewardPools[i];
            if (pool.rewardToken == address(0)) {
                continue;
            }

            if (bentCVX == pool.rewardToken) {
                // deposit CVX to bentCVX
                uint256 cvxAmount = IERC20Upgradeable(cvx).balanceOf(
                    address(this)
                );
                if (cvxAmount > 0) {
                    IERC20Upgradeable(cvx).safeApprove(bentCVX, cvxAmount);
                    IBentCVX(bentCVX).deposit(cvxAmount);
                }
            }

            uint256 newRewards = IERC20Upgradeable(pool.rewardToken).balanceOf(
                address(this)
            ) - pool.reserves;
            if (newRewards > 0) {
                newRewardsAvailable = true;
            }

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

        require(newRewardsAvailable, Errors.ZERO_AMOUNT);

        endRewardBlock = lastRewardBlock + windowLength;
    }

    // Internal Functions

    function _updateAccPerShare(bool withdrawReward, address user) internal {
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
                uint256 pending = ((balanceOf[user] * pool.accRewardPerShare) /
                    1e36) - userRewardDebt[i][user];

                if (pending > 0) {
                    userPendingRewards[i][user] += pending;
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
        if (rewardPools[pid].rewardToken == address(0)) {
            return 0;
        }

        claimAmount = userPendingRewards[pid][user];
        if (claimAmount > 0) {
            IERC20Upgradeable(rewardPools[pid].rewardToken).safeTransfer(
                user,
                claimAmount
            );
            rewardPools[pid].reserves -= claimAmount;
            userPendingRewards[pid][user] = 0;
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
