// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

interface IRewardManager {
    function withdrawRewardTokens(
        address _token,
        address _recipient,
        uint256 _amount
    ) external;

    function totalRewardCount(address _token) external view returns (uint256);

    function getRewardFrom(
        address _token,
        uint256 _index
    ) external view returns (uint256);

    function totalAddedRewards(
        address _token,
        uint256 index
    ) external view returns (uint256);

    function rewardAddTime(address _token) external view returns (uint256);

    function totalTokens() external view returns (uint256);

    function rewardToken(uint256 _index) external view returns (address);

    function isRewardToken(address _token) external view returns (bool);
}

contract StakingContractV3 is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public usdtToken;
    IRewardManager public rewardManager;

    uint256 public penaltyPercent; // 10% penalty during penalty duration
    uint256 public lockDuration;
    uint256 public hardLockDuration;
    uint256 public PERCENT_DIVIDER;

    uint256 public totalStakedUsers;
    uint256 public totalStakedAmount;
    uint256 public totalPenaltyAmount;
    uint256 public totalUnStakedAmount;

    bool public paused;

    struct Reward {
        uint256 count;
        mapping(uint256 => uint256) balances;
        mapping(uint256 => address) tokens;
    }
    struct Stake {
        uint256 amount;
        uint256 endTime;
        uint256 startTime;
        uint256 unstakedAt;
        uint256 lastClaimedInd;
    }

    struct User {
        uint256 totalPenalty;
        uint256 lastUnstakedIndex;
        uint256 totalAmountStaked;
        uint256 totalAmountUnstaked;
        uint256 stakesCount;
        uint256 lastClaimedAt;
        mapping(uint256 => Stake) stakes;
        mapping(address => uint256) prevRemainingReward;
        mapping(address => uint256) lastClaimedTokenCount;
    }

    mapping(address => User) public userStakes;

    struct StakeDetail {
        uint256 totalUsers;
        uint256 totalAmount;
    }
    mapping(address => mapping(uint256 => StakeDetail))
        public rewardStakeHistory;

    uint256 public maxPerWallet;

    event STAKED(address indexed user, uint256 amount, uint256 at);
    event UNSTAKED(
        address indexed user,
        uint256 _index,
        uint256 _reward,
        uint256 at
    );
    event REWARD_CLAIMED(address indexed user, uint256 amount, uint256 at);

    modifier notPaused() {
        require(!paused, "Temporarily Paused");
        _;
    }

    // Initialize the contract
    function initialize(
        IERC20Upgradeable _usdtTokenAddress,
        IRewardManager _rewardManager
    ) external initializer {
        __Ownable_init();
        usdtToken = _usdtTokenAddress;
        rewardManager = _rewardManager;

        penaltyPercent = 20; // 10% penalty during penalty duration
        lockDuration = 14 days;
        hardLockDuration = 7 days;
        PERCENT_DIVIDER = 10000;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        User storage user = userStakes[msg.sender];
        require(
            (user.totalAmountStaked - user.totalAmountUnstaked) + amount <=
                maxPerWallet,
            "Stake limit reached"
        );
        // Update last Reward
        usdtToken.safeTransferFrom(msg.sender, address(this), amount);
        (address[] memory _tokens, uint256[] memory _rewards) = claimableReward(
            msg.sender
        );
        for (uint256 i = 0; i < _tokens.length; i++) {
            user.prevRemainingReward[_tokens[i]] = _rewards[i];
        }
        updateLastClaimedIndex(msg.sender);

        // update user
        uint256 currentIndex = ++user.stakesCount;
        Stake storage _currentStake = user.stakes[currentIndex];
        _currentStake.amount = amount;
        _currentStake.startTime = block.timestamp;
        _currentStake.endTime = block.timestamp + lockDuration;

        // update total staked info
        if (currentIndex == 1) {
            totalStakedUsers++;
        }
        user.totalAmountStaked = user.totalAmountStaked.add(amount);
        totalStakedAmount = totalStakedAmount.add(amount);

        emit STAKED(msg.sender, amount, block.timestamp);
    }

    function unstakeUnlocked() external nonReentrant notPaused {
        User storage user = userStakes[msg.sender];
        require(user.stakesCount != 0, "Stakes not found!");

        uint256 totalStakedUSDT;
        uint256 totalWithdrawableUSDT;

        // Claim reward if available
        _withdrawReward(msg.sender);

        uint256 i;
        for (i = user.lastUnstakedIndex + 1; i <= user.stakesCount; i++) {
            Stake storage stakeInfo = user.stakes[i];
            if (
                block.timestamp > stakeInfo.startTime + hardLockDuration &&
                stakeInfo.unstakedAt == 0
            ) {
                stakeInfo.unstakedAt = block.timestamp;

                uint256 stakeAmount = stakeInfo.amount;
                totalStakedUSDT += stakeAmount;
                if (block.timestamp < stakeInfo.endTime) {
                    uint256 penaltyAmount = (stakeAmount * penaltyPercent) /
                        100;
                    usdtToken.safeTransfer(owner(), penaltyAmount);
                    stakeAmount -= penaltyAmount;
                }
                // staked usdt info
                totalWithdrawableUSDT += stakeAmount;
                emit UNSTAKED(msg.sender, i, stakeAmount, block.timestamp);
            }
        }
        require(totalWithdrawableUSDT != 0, "No withdrawable amount.");

        user.lastUnstakedIndex = i - 1;
        usdtToken.safeTransfer(msg.sender, totalWithdrawableUSDT);

        // update total staked info
        user.totalAmountUnstaked = user.totalAmountUnstaked.add(
            totalStakedUSDT
        );
        user.totalPenalty = user.totalPenalty.add(
            totalStakedUSDT.sub(totalWithdrawableUSDT)
        );

        totalUnStakedAmount = totalUnStakedAmount.add(totalStakedUSDT);
        totalPenaltyAmount = totalPenaltyAmount.add(
            totalStakedUSDT.sub(totalWithdrawableUSDT)
        );
    }

    function claimReward() external nonReentrant notPaused {
        User storage user = userStakes[msg.sender];
        require(user.stakesCount != 0, "Stakes not found!");

        uint256 rewardSent = _withdrawReward(msg.sender);
        require(rewardSent != 0, "Nothing to withdraw!");
    }

    function _withdrawReward(address _user) private returns (uint256) {
        (address[] memory tokens, uint256[] memory balances) = claimableReward(
            _user
        );

        uint256 rewardSent;
        for (uint256 i; i < tokens.length; i++) {
            uint256 rewardAmount = balances[i];
            address rewardToken = tokens[i];
            userStakes[_user].prevRemainingReward[tokens[i]] = 0;
            // update last claim
            if (rewardAmount != 0) {
                rewardSent++;
                rewardManager.withdrawRewardTokens(
                    rewardToken,
                    _user,
                    rewardAmount
                );
            }
        }
        userStakes[_user].lastClaimedAt = block.timestamp;

        updateLastClaimedIndex(_user);
        return rewardSent;
    }

    function updateRewardRecord(address _token, uint256 _index) public {
        require(msg.sender == address(rewardManager), "Only reward manager!");
        rewardStakeHistory[_token][_index].totalUsers = totalStakedUsers;
        rewardStakeHistory[_token][_index].totalAmount =
            totalStakedAmount -
            totalUnStakedAmount;
    }

    function updateLastClaimedIndex(address _user) internal {
        uint256 _tokensCount = rewardManager.totalTokens();
        for (uint256 j = 0; j < _tokensCount; j++) {
            address rewardToken = rewardManager.rewardToken(j);
            userStakes[_user].lastClaimedTokenCount[rewardToken] = rewardManager
                .totalRewardCount(rewardToken);
        }
    }

    function claimableReward(
        address _user
    ) public view returns (address[] memory, uint256[] memory) {
        User storage user = userStakes[_user];
        // require(user.stakesCount != 0, "Stakes not found!");
        uint256 _tokensCount = rewardManager.totalTokens();
        address[] memory tokens = new address[](_tokensCount);
        uint256[] memory balances = new uint256[](_tokensCount);

        (uint256 stakedAmount, , ) = calculateTotalStakedInfo(_user);
        // uint256 stakePercentage = stakedAmount.mul(PERCENT_DIVIDER).div(
        //     usdtToken.balanceOf(address(this))
        // );

        uint256 _tokenIndex = 0;
        for (uint256 j = 0; j < _tokensCount; j++) {
            address rewardToken = rewardManager.rewardToken(j);
            // Check if token is set as reward
            if (rewardManager.isRewardToken(rewardToken)) {
                uint256 totalAddedRewardCount = rewardManager.totalRewardCount(
                    rewardToken
                );
                uint256 lastUserClaimed = user.lastClaimedTokenCount[
                    rewardToken
                ];
                for (
                    uint256 k = lastUserClaimed + 1;
                    k <= totalAddedRewardCount;
                    k++
                ) {
                    uint256 totalAddedReward = rewardManager.totalAddedRewards(
                        rewardToken,
                        k
                    );
                    StakeDetail memory _detail = rewardStakeHistory[
                        rewardToken
                    ][k];
                    // uint256 totalUsers = _detail.totalUsers;
                    uint256 stakedAmountAt = _detail.totalAmount;

                    uint256 currentPercentage = stakedAmount
                        .mul(PERCENT_DIVIDER)
                        .div(stakedAmountAt);
                    uint256 _claimableReward = totalAddedReward
                        .mul(currentPercentage)
                        .div(PERCENT_DIVIDER);
                    balances[_tokenIndex] += _claimableReward;
                }
                balances[_tokenIndex] += user.prevRemainingReward[rewardToken];
                // lastTokenCount[_tokenIndex] = totalAddedRewardCount;
                if (tokens[_tokenIndex] == address(0)) {
                    tokens[_tokenIndex] = rewardToken;
                }
                _tokenIndex++;
            }
        }

        return (tokens, balances);
    }

    function calculateTotalStakedInfo(
        address _usr
    )
        public
        view
        returns (
            uint256 stakedAmount,
            uint256 withdrawableAmount,
            uint256 penaty
        )
    {
        for (uint256 i = 1; i <= userStakes[_usr].stakesCount; i++) {
            if (userStakes[_usr].stakes[i].unstakedAt == 0) {
                Stake memory stakeInfo = userStakes[_usr].stakes[i];
                uint256 stakeAmount = stakeInfo.amount;
                if (block.timestamp > stakeInfo.startTime + hardLockDuration) {
                    withdrawableAmount += stakeAmount;
                    if (block.timestamp < stakeInfo.endTime) {
                        penaty += (stakeAmount * penaltyPercent) / 100;
                    }
                }
                stakedAmount += stakeAmount;
            }
        }
    }

    function getStakeInfo(
        address _usr,
        uint256 _index
    )
        external
        view
        returns (
            uint256 staked,
            uint256 stakeTime,
            uint256 endTime,
            uint256 unstakedAt
        )
    {
        require(
            _index != 0 && _index <= userStakes[_usr].stakesCount,
            "Invalid index"
        );

        return (
            userStakes[_usr].stakes[_index].amount,
            userStakes[_usr].stakes[_index].startTime,
            userStakes[_usr].stakes[_index].endTime,
            userStakes[_usr].stakes[_index].unstakedAt
        );
    }

    function setLockDuration(uint256 duration) external onlyOwner {
        lockDuration = duration;
    }

    function setHardLockDuration(uint256 duration) external onlyOwner {
        hardLockDuration = duration;
    }

    function setPenaltyPercent(uint256 percent) external onlyOwner {
        require(percent <= 100, "Invalid penalty percent");
        penaltyPercent = percent;
    }

    function setUsdtToken(IERC20Upgradeable _usdtToken) external onlyOwner {
        usdtToken = _usdtToken;
    }

    function setRewardManager(
        IRewardManager _rewardManager
    ) external onlyOwner {
        rewardManager = _rewardManager;
    }

    function setPauseStatus(bool _pauseStatus) external onlyOwner {
        paused = _pauseStatus;
    }

    function setMaxPerWalletLimit(uint256 _amount) external onlyOwner {
        maxPerWallet = _amount;
    }
}
