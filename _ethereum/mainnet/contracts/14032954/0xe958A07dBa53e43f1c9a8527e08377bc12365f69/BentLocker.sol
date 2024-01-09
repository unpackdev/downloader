// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./Errors.sol";
import "./IBentCVX.sol";
import "./IBentPool.sol";
import "./IBentPoolManager.sol";
import "./IConvexBooster.sol";
import "./IBaseRewardPool.sol";
import "./IConvexToken.sol";
import "./IVirtualBalanceRewardPool.sol";

contract BentLocker is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // events
    event Deposit(address indexed user, uint256 amount, uint256 shares);
    event Withdraw(address indexed user, uint256 amount, uint256 shares);
    event ClaimAll(address indexed user);
    event Claim(address indexed user, uint256[] pids);

    // structs
    struct PoolData {
        address rewardToken;
        uint256 accRewardPerShare; // Accumulated Rewards per share, times 1e36. See below.
        uint256 rewardRate;
        uint256 reserves;
    }
    struct LockedBalance {
        uint256 amount;
        uint256 unlockAt;
    }
    struct Epoch {
        uint256 supply;
        uint256 startAt;
    }
    struct StreamInfo {
        uint256 windowLength;
        uint256 endRewardBlock; // end block of rewards stream
    }

    IERC20Upgradeable public bent;
    IBentCVX public bentCVX;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    // reward settings
    uint256 public rewardPoolsCount;
    mapping(uint256 => PoolData) public rewardPools;
    mapping(address => bool) public isRewardToken;
    mapping(uint256 => mapping(address => uint256)) internal userRewardDebt;
    mapping(uint256 => mapping(address => uint256)) internal userPendingRewards;

    // lock settings
    uint256 internal firstEpoch; // first epoch start in week
    uint256 public epochLength; // 1 weeks
    uint256 public lockDurationInEpoch; // in lock group = 8 weeks
    mapping(address => mapping(uint256 => uint256)) public userLocks; // user => epoch => locked balance

    uint256 lastRewardBlock; // last block of rewards streamed
    StreamInfo public bentStreamInfo; // only for bentCVX rewards
    StreamInfo public votiumStreamInfo; // for non-bentCVX rewards

    function initialize(
        address _bent,
        address _bentCVX,
        address[] memory _rewardTokens,
        uint256 bentWindowLength, // 7 days
        uint256 votiumWindowLength, // 15 days
        uint256 _epochLength, // 1 weeks
        uint256 _lockDurationInEpoch // in lock group = 8 weeks
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        bent = IERC20Upgradeable(_bent);
        bentCVX = IBentCVX(_bentCVX);

        addRewardTokens(_rewardTokens);

        bentStreamInfo.windowLength = bentWindowLength;
        votiumStreamInfo.windowLength = votiumWindowLength;
        epochLength = _epochLength;
        lockDurationInEpoch = _lockDurationInEpoch;

        firstEpoch = block.timestamp / epochLength;
    }

    function name() external pure returns (string memory) {
        return "weBENT";
    }

    function decimals() external pure returns (uint256) {
        return 18;
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

    function currentEpoch() public view returns (uint256) {
        return block.timestamp / epochLength - firstEpoch;
    }

    function epochExpireAt(uint256 epoch) public view returns (uint256) {
        return (firstEpoch + epoch + 1) * epochLength;
    }

    function unlockableBalances(address user) public view returns (uint256) {
        uint256 lastEpoch = currentEpoch();
        uint256 fromLockedEpoch = lastEpoch >= lockDurationInEpoch
            ? lastEpoch - lockDurationInEpoch + 1
            : 0;

        uint256 locked;
        for (uint256 i = fromLockedEpoch; i <= lastEpoch; i++) {
            locked += userLocks[user][i];
        }
        return balanceOf[user] - locked;
    }

    function lockedBalances(address user)
        external
        view
        returns (
            uint256 unlockable,
            uint256 locked,
            LockedBalance[] memory lockData
        )
    {
        uint256 lastEpoch = currentEpoch();
        uint256 fromLockedEpoch = lastEpoch >= lockDurationInEpoch
            ? lastEpoch - lockDurationInEpoch + 1
            : 0;

        lockData = new LockedBalance[](lastEpoch - fromLockedEpoch + 1);
        for (uint256 i = fromLockedEpoch; i <= lastEpoch; i++) {
            uint256 amount = userLocks[user][i];
            lockData[i - fromLockedEpoch] = LockedBalance(
                amount,
                epochExpireAt(i)
            );
            locked += amount;
        }
        return (balanceOf[user] - locked, locked, lockData);
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

        uint256 shares = _amount;
        if (totalSupply != 0) {
            shares = (shares * totalSupply) / bent.balanceOf(address(this));
        }

        bent.safeTransferFrom(msg.sender, address(this), _amount);

        _mint(msg.sender, shares);

        _updateUserRewardDebt();

        emit Deposit(msg.sender, _amount, shares);
    }

    function withdraw(uint256 _shares) external nonReentrant {
        require(
            unlockableBalances(msg.sender) >= _shares && _shares != 0,
            Errors.INVALID_AMOUNT
        );

        _updateAccPerShare(true);

        uint256 amount = _shares;
        if (totalSupply != 0) {
            amount = (amount * bent.balanceOf(address(this))) / totalSupply;
        }

        _burn(msg.sender, _shares);

        // transfer to msg.sender
        bent.safeTransfer(msg.sender, amount);

        _updateUserRewardDebt();

        emit Withdraw(msg.sender, amount, _shares);
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

        bool isBentAvaialble = false;
        bool isVotiumAvailable = false;

        // stream the rewards
        for (uint256 i = 0; i < rewardPoolsCount; ++i) {
            PoolData storage pool = rewardPools[i];
            if (pool.rewardToken == address(0)) {
                continue;
            }

            uint256 newRewards = IERC20Upgradeable(pool.rewardToken).balanceOf(
                address(this)
            ) - pool.reserves;

            if (newRewards == 0) {
                continue;
            }

            StreamInfo memory streamInfo = bentStreamInfo;
            isBentAvaialble = true;
            if (pool.rewardToken != address(bentCVX)) {
                streamInfo = votiumStreamInfo;
                isVotiumAvailable = true;
            }

            if (streamInfo.endRewardBlock > lastRewardBlock) {
                pool.rewardRate =
                    (pool.rewardRate *
                        (streamInfo.endRewardBlock - lastRewardBlock) +
                        newRewards *
                        1e36) /
                    streamInfo.windowLength;
            } else {
                pool.rewardRate = (newRewards * 1e36) / streamInfo.windowLength;
            }

            pool.reserves += newRewards;
        }

        if (isBentAvaialble) {
            bentStreamInfo.endRewardBlock =
                lastRewardBlock +
                bentStreamInfo.windowLength;
        }
        if (isVotiumAvailable) {
            votiumStreamInfo.endRewardBlock =
                lastRewardBlock +
                votiumStreamInfo.windowLength;
        }
    }

    function bentBalanceOf(address user) external view returns (uint256) {
        if (totalSupply == 0) {
            return 0;
        }

        return (balanceOf[user] * bent.balanceOf(address(this))) / totalSupply;
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
        uint256 bentStreamDuration = _calcRewardDuration(
            bentStreamInfo.windowLength,
            bentStreamInfo.endRewardBlock
        );
        uint256 votiumStreamDuration = _calcRewardDuration(
            votiumStreamInfo.windowLength,
            votiumStreamInfo.endRewardBlock
        );

        uint256 _rewardPoolsCount = rewardPoolsCount;
        addedRewards = new uint256[](_rewardPoolsCount);
        for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
            if (rewardPools[i].rewardToken == address(bentCVX)) {
                addedRewards[i] =
                    (rewardPools[i].rewardRate * bentStreamDuration) /
                    1e36;
            } else {
                addedRewards[i] =
                    (rewardPools[i].rewardRate * votiumStreamDuration) /
                    1e36;
            }
        }
    }

    function _calcRewardDuration(uint256 windowLength, uint256 endRewardBlock)
        internal
        view
        returns (uint256)
    {
        uint256 startBlock = endRewardBlock > lastRewardBlock + windowLength
            ? endRewardBlock - windowLength
            : lastRewardBlock;
        uint256 endBlock = block.number > endRewardBlock
            ? endRewardBlock
            : block.number;
        return endBlock > startBlock ? endBlock - startBlock : 0;
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

        userLocks[_user][currentEpoch()] += _amount;
    }

    function _burn(address _user, uint256 _amount) internal {
        balanceOf[_user] -= _amount;
        totalSupply -= _amount;
    }
}
