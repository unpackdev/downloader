// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";

import "./IStaking.sol";
import "./IRewardManager.sol";

contract TribotStakingV3 is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    IERC20MetadataUpgradeable public token;
    uint256 public totalStaked;
    uint256 public minDeposit;
    uint256 public timeStep;
    uint256 public percentDivider;
    uint256 public basePercent;
    uint256 public uniqueStakers;

    // Initialize the contract
    function initialize(IERC20MetadataUpgradeable _token) external initializer {
        __Ownable_init();

        token = _token;
        minDeposit = 100 * 10 ** token.decimals();
        timeStep = 14 days;
        percentDivider = 100_00;
        basePercent = 10;
    }

    struct User {
        uint256 amount;
        uint256 checkpoint;
        uint256 claimedReward;
        uint256 totalclaimed;
        uint256 reward;
        uint256 startTime;
        uint256 withdrawTime;
        bool isActive;
        bool isExists;
    }
    mapping(address => User) public users;

    // new storage
    mapping(address => mapping(uint256 => uint256)) public rewardStakeHistory;

    // New Storage
    IRewardManager public rewardManager;
    mapping(address => mapping(address => uint256)) public userLastPoolCount;
    mapping(address => mapping(address => uint256)) public prevRemainingReward;

    address public usdtStaking;
    uint256 public penaltyPercent;
    bool public paused;
    bool private locked; // State variable to track reentrancy

    event STAKE(address Staker, uint256 amount);
    event CLAIM(address Staker, uint256 amount);
    event WITHDRAW(address Staker, uint256 amount);

    modifier notPaused() {
        require(!paused, "Temporarily Paused");
        _;
    }

    function stake(uint256 _amount) public {
        User storage user = users[msg.sender];
        require(_amount >= minDeposit, "Amount less than min amount");
        if (!user.isExists) {
            user.isExists = true;
            uniqueStakers++;
            user.startTime = block.timestamp;
        } else {
            uint256 claimableReward = calculateReward(msg.sender);
            if (claimableReward > 0) {
                token.transfer(msg.sender, claimableReward);
            }
        }
        // from reward pool
        (
            address[] memory tokens,
            uint256[] memory balances
        ) = calculatePoolReward(msg.sender);
        uint256 rewardSent;
        for (uint256 i; i < tokens.length; i++) {
            uint256 poolRewardAmount = balances[i];
            address rewardToken = tokens[i];
            prevRemainingReward[msg.sender][tokens[i]] = 0;
            // update last claim
            if (poolRewardAmount != 0) {
                rewardSent++;
                rewardManager.withdrawRewardTokens(
                    rewardToken,
                    msg.sender,
                    poolRewardAmount
                );
            }
        }
        updateLastClaimedIndex(msg.sender);

        token.transferFrom(msg.sender, address(this), _amount);
        user.amount += _amount;
        user.claimedReward = 0;
        user.reward = user.amount.mul(basePercent).div(percentDivider);
        totalStaked += _amount;
        user.checkpoint = block.timestamp;
        user.withdrawTime = block.timestamp + timeStep;
        user.isActive = true;

        emit STAKE(msg.sender, _amount);
    }

    function claim() public notPaused {
        require(!locked, "Locked: reentrancy attack detected");
        // Set the locked state to prevent reentrancy
        locked = true;

        User storage user = users[msg.sender];
        require(user.isActive, "Already withdrawn");
        uint256 rewardAmount;
        rewardAmount = calculateReward(msg.sender);
        require(rewardAmount > 0, "Can't claim 0");
        token.transfer(msg.sender, rewardAmount);

        // from reward pool
        (
            address[] memory tokens,
            uint256[] memory balances
        ) = calculatePoolReward(msg.sender);
        uint256 rewardSent;
        for (uint256 i; i < tokens.length; i++) {
            uint256 poolRewardAmount = balances[i];
            address rewardToken = tokens[i];
            prevRemainingReward[msg.sender][tokens[i]] = 0;
            // update last claim
            if (poolRewardAmount != 0) {
                rewardSent++;
                rewardManager.withdrawRewardTokens(
                    rewardToken,
                    msg.sender,
                    poolRewardAmount
                );
            }
        }
        user.checkpoint = block.timestamp;
        user.claimedReward += rewardAmount;
        user.totalclaimed += rewardAmount;

        updateLastClaimedIndex(msg.sender);
        // Reset the locked state after the operation is complete
        locked = false;
        emit CLAIM(msg.sender, rewardAmount);
    }

    function restake() public {
        require(false, "Not implemented");
        User storage user = users[msg.sender];
        uint256 claimableReward = calculateReward(msg.sender);
        require(claimableReward > 0, "Nothing to restake");
        user.claimedReward = 0;
        user.totalclaimed += claimableReward;
        user.amount += claimableReward;
        user.checkpoint = block.timestamp;
        user.reward = user.amount.mul(basePercent).div(percentDivider);
        user.withdrawTime = block.timestamp + timeStep;
        totalStaked += claimableReward;
    }

    function calculateReward(address _user) public view returns (uint256) {
        User storage user = users[_user];
        uint256 _reward;
        uint256 rewardDuration = block.timestamp.sub(user.checkpoint);
        _reward = user.amount.mul(rewardDuration).mul(basePercent).div(
            percentDivider.mul(timeStep)
        );
        if (_reward.add(user.claimedReward) > user.reward) {
            _reward = user.reward.sub(user.claimedReward);
        }
        return _reward;
    }

    function withdraw() public notPaused {
        require(!locked, "Locked: reentrancy attack detected");
        User storage user = users[msg.sender];
        require(user.isActive, "user is not active!");

        // Set the locked state to prevent reentrancy
        locked = true;
        // require(block.timestamp > user.withdrawTime, "Wait for withdraw time!");
        uint256 stakedAmount = user.amount;
        totalStaked -= stakedAmount;
        // Claim reward
        uint256 claimAbleReward = calculateReward(msg.sender);
        if (claimAbleReward > 0) {
            claim();
        }
        if (
            block.timestamp < user.withdrawTime &&
            block.timestamp > user.withdrawTime.sub(7 days)
        ) {
            uint256 penaltyAmount = stakedAmount.mul(penaltyPercent).div(
                percentDivider
            );
            stakedAmount -= penaltyAmount;
        }
        user.amount = 0;
        user.reward = 0;
        user.claimedReward = 0;
        user.totalclaimed = claimAbleReward;
        user.isActive = false;

        token.transfer(msg.sender, stakedAmount);

        // Reset the locked state after the operation is complete
        locked = false;
    }

    function calculatePoolReward(
        address _user
    ) public view returns (address[] memory, uint256[] memory) {
        User storage user = users[_user];
        uint256 _tokensCount = rewardManager.totalTokens();
        address[] memory tokens = new address[](_tokensCount);
        uint256[] memory balances = new uint256[](_tokensCount);

        uint256 stakedAmount = user.amount;
        uint256 _tokenIndex = 0;
        for (uint256 j = 0; j < _tokensCount; j++) {
            address rewardToken = rewardManager.rewardToken(j);
            // Check if token is set as reward
            if (rewardManager.isRewardToken(rewardToken)) {
                uint256 totalAddedRewardCount = rewardManager.totalRewardCount(
                    rewardToken
                );
                uint256 lastUserClaimed = userLastPoolCount[_user][rewardToken];
                for (
                    uint256 k = lastUserClaimed + 1;
                    k <= totalAddedRewardCount;
                    k++
                ) {
                    uint256 totalAddedReward = getCurrentShareAmount(
                        _user,
                        stakedAmount,
                        rewardToken,
                        k
                    );
                    // uint256 totalAddedReward = rewardManager.totalAddedRewards(
                    //     rewardToken,
                    //     k
                    // );
                    // New Logic
                    // uint256 currentShare = rewardManager.getRewardPoolShare(
                    //     _user
                    // );
                    // uint256 currentAccessibleReward = totalAddedReward
                    //     .mul(currentShare)
                    //     .div(percentDivider);
                    uint256 stakedAmountAt = rewardStakeHistory[rewardToken][k];
                    uint256 _claimableReward;
                    if (stakedAmountAt != 0) {
                        uint256 currentPercentage = stakedAmount
                            .mul(percentDivider)
                            .div(stakedAmountAt);
                        _claimableReward = totalAddedReward
                            .mul(currentPercentage)
                            .div(percentDivider);
                    }
                    balances[_tokenIndex] += _claimableReward;
                }
                balances[_tokenIndex] += prevRemainingReward[_user][
                    rewardToken
                ];
                // lastTokenCount[_tokenIndex] = totalAddedRewardCount;
                if (tokens[_tokenIndex] == address(0)) {
                    tokens[_tokenIndex] = rewardToken;
                }
                _tokenIndex++;
            }
        }

        return (tokens, balances);
    }

    function getCurrentShareAmount(
        address _user,
        uint256 _stakedAmount,
        address rewardToken,
        uint256 k
    ) public view returns (uint256) {
        if (_stakedAmount == 0) {
            return 0;
        }
        (uint256 usdtStaked, , ) = IStaking(usdtStaking)
            .calculateTotalStakedInfo(_user);
        uint256 totalAddedReward;
        if (usdtStaked != 0) {
            totalAddedReward =
                rewardManager.totalRewardSharePlus(rewardToken, k) /
                2;
        } else {
            totalAddedReward = rewardManager.totalRewardShareTribot(
                rewardToken,
                k
            );
        }
        return
            totalAddedReward == 0
                ? rewardManager.totalAddedRewards(rewardToken, k)
                : totalAddedReward;
    }

    function updateLastClaimedIndex(address _user) internal {
        uint256 _tokensCount = rewardManager.totalTokens();
        for (uint256 j = 0; j < _tokensCount; j++) {
            address rewardToken = rewardManager.rewardToken(j);
            userLastPoolCount[_user][rewardToken] = rewardManager
                .totalRewardCount(rewardToken);
        }
    }

    function updateRewardRecord(address _token, uint256 _index) public {
        require(msg.sender == address(rewardManager), "Only reward manager!");
        rewardStakeHistory[_token][_index] = totalStaked;
    }

    function updateToken(IERC20MetadataUpgradeable _token) public onlyOwner {
        require(address(_token) != address(0), "token address cannot be 0");
        token = _token;
    }

    function updateTimeStep(uint256 _timeStep) public onlyOwner {
        timeStep = _timeStep;
    }

    function setBasePercent(uint256 _basePercent) public onlyOwner {
        basePercent = _basePercent;
    }

    function setPercentDivider(uint256 _percentDivider) public onlyOwner {
        percentDivider = _percentDivider;
    }

    function setRewardManager(
        IRewardManager _rewardManager
    ) external onlyOwner {
        rewardManager = _rewardManager;
    }

    function setUsdtStaking(address _addr) external onlyOwner {
        usdtStaking = _addr;
    }

    function setPenaltyPercent(uint256 percent) external onlyOwner {
        require(percent <= 10000, "Invalid penalty percent");
        penaltyPercent = percent;
    }

    function setPauseStatus(bool _pauseStatus) external onlyOwner {
        paused = _pauseStatus;
    }
}
