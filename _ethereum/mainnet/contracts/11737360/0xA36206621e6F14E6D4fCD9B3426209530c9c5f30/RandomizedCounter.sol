// SPDX-License-Identifier: MIT
/*

██████╗ ███████╗██████╗  █████╗ ███████╗███████╗
██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝
██║  ██║█████╗  ██████╔╝███████║███████╗█████╗  
██║  ██║██╔══╝  ██╔══██╗██╔══██║╚════██║██╔══╝  
██████╔╝███████╗██████╔╝██║  ██║███████║███████╗
╚═════╝ ╚══════╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝
                                               

* Debase: RandomizedCounter.sol
* Description:
* Counts rebases and distributes rewards when a random threshold is triggered.
* Coded by: punkUnknown
*/

pragma solidity >=0.6.6;

import "./SafeMath.sol";
import "./Math.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface IRandomNumberConsumer {
    function getRandomNumber(uint256 userProvidedSeed) external;

    function fee() external view returns (uint256);
}

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public y;

    function setStakeToken(address _y) internal {
        y = IERC20(_y);
    }

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        y.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        y.safeTransfer(msg.sender, amount);
    }
}

contract RandomizedCounter is
    Ownable,
    Initializable,
    LPTokenWrapper,
    ReentrancyGuard
{
    using Address for address;

    event LogEmergencyWithdraw(uint256 timestamp);
    event LogSetCountThreshold(uint256 countThreshold_);
    event LogSetBeforePeriodFinish(bool beforePeriodFinish_);
    event LogSetCountInSequence(bool countInSequence_);
    event LogSetRewardPercentage(uint256 rewardPercentage_);
    event LogSetRevokeReward(bool revokeReward_);
    event LogSetRevokeRewardPrecentage(uint256 revokeRewardPrecentage_);
    event LogSetNormalDistribution(
        uint256 noramlDistributionMean_,
        uint256 normalDistributionDeviation_,
        uint256[100] normalDistribution_
    );
    event LogSetRandomNumberConsumer(
        IRandomNumberConsumer randomNumberConsumer_
    );
    event LogSetMultiSigAddress(address multiSigAddress_);
    event LogSetMultiSigRewardPercentage(uint256 multiSigRewardPercentage_);
    event LogRevokeRewardDuration(uint256 revokeRewardDuration_);
    event LogLastRandomThreshold(uint256 lastRandomThreshold_);
    event LogSetBlockDuration(uint256 blockDuration_);
    event LogStartNewDistributionCycle(
        uint256 poolShareAdded_,
        uint256 rewardRate_,
        uint256 periodFinish_,
        uint256 count_
    );
    event LogRandomThresold(uint256 randomNumber);
    event LogSetPoolEnabled(bool poolEnabled_);
    event LogSetEnableUserLpLimit(bool enableUserLpLimit_);
    event LogSetEnablePoolLpLimit(bool enablePoolLpLimit_);
    event LogSetUserLpLimit(uint256 userLpLimit_);
    event LogSetPoolLpLimit(uint256 poolLpLimit_);
    event LogRewardsClaimed(uint256 rewardAmount_);
    event LogRewardAdded(uint256 reward);
    event LogRewardRevoked(
        uint256 revokeDuratoin,
        uint256 precentageRevoked,
        uint256 amountRevoked
    );
    event LogClaimRevoked(uint256 claimAmountRevoked_);
    event LogStaked(address indexed user, uint256 amount);
    event LogWithdrawn(address indexed user, uint256 amount);
    event LogRewardPaid(address indexed user, uint256 reward);
    event LogManualPoolStarted(uint256 startedAt);

    IERC20 public debase;
    address public policy;
    bool public poolEnabled;

    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateBlock;
    uint256 public rewardPerTokenStored;
    uint256 public rewardPercentage;
    uint256 public rewardDistributed;

    uint256 public blockDuration;

    //Flag to enable amount of lp that can be staked by a account
    bool public enableUserLpLimit;
    //Amount of lp that can be staked by a account
    uint256 public userLpLimit;

    //Flag to enable total amount of lp that can be staked by all users
    bool public enablePoolLpLimit;
    //Total amount of lp tat can be staked
    uint256 public poolLpLimit;

    uint256 public revokeRewardDuration;

    // Should revoke reward
    bool public revokeReward;

    uint256 public lastRewardPercentage;

    // The count of s hitting their target
    uint256 public count;

    // Flag to enable or disable   sequence checker
    bool public countInSequence;

    bool public newBufferFunds;

    // Address for the random number contract (chainlink vrf)
    IRandomNumberConsumer public randomNumberConsumer;

    //Address of the link token
    IERC20 public link;

    // Flag to send reward before stabilizer pool period time finished
    bool public beforePeriodFinish;

    // The mean for the normal distribution added
    uint256 public normalDistributionMean;

    // The deviation for te normal distribution added
    uint256 public normalDistributionDeviation;

    // The array of normal distribution value data
    uint256[100] public normalDistribution;

    address public multiSigAddress;
    uint256 public multiSigRewardPercentage;
    uint256 public multiSigRewardToClaimShare;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    modifier enabled() {
        require(poolEnabled, "Pool isn't enabled");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateBlock = lastBlockRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /**
     * @notice Function to set how much reward the stabilizer will request
     */
    function setRewardPercentage(uint256 rewardPercentage_) external onlyOwner {
        rewardPercentage = rewardPercentage_;
        emit LogSetRewardPercentage(rewardPercentage);
    }

    /**
     * @notice Function to enable or disable count should be in sequence
     */
    function setCountInSequence(bool countInSequence_) external onlyOwner {
        countInSequence = countInSequence_;
        count = 0;
        emit LogSetCountInSequence(!countInSequence);
    }

    /**
     * @notice Function to enable or disable reward revoking
     */
    function setRevokeReward(bool revokeReward_) external onlyOwner {
        revokeReward = revokeReward_;
        emit LogSetRevokeReward(revokeReward);
    }

    /**
     * @notice Function to set how much of the reward duration should be revoked
     */
    function setRevokeRewardDuration(uint256 revokeRewardDuration_)
        external
        onlyOwner
    {
        revokeRewardDuration = revokeRewardDuration_;
        emit LogRevokeRewardDuration(revokeRewardDuration);
    }

    /**
     * @notice Function to allow reward distribution before previous rewards have been distributed
     */
    function setBeforePeriodFinish(bool beforePeriodFinish_)
        external
        onlyOwner
    {
        beforePeriodFinish = beforePeriodFinish_;
        emit LogSetBeforePeriodFinish(beforePeriodFinish);
    }

    /**
     * @notice Function to set reward drop period
     */
    function setBlockDuration(uint256 blockDuration_) external onlyOwner {
        require(blockDuration >= 1);
        blockDuration = blockDuration_;
        emit LogSetBlockDuration(blockDuration);
    }

    /**
     * @notice Function enabled or disable pool staking,withdraw
     */
    function setPoolEnabled(bool poolEnabled_) external onlyOwner {
        poolEnabled = poolEnabled_;
        count = 0;
        emit LogSetPoolEnabled(poolEnabled);
    }

    /**
     * @notice Function to enable user lp limit
     */
    function setEnableUserLpLimit(bool enableUserLpLimit_) external onlyOwner {
        enableUserLpLimit = enableUserLpLimit_;
        emit LogSetEnableUserLpLimit(enableUserLpLimit);
    }

    /**
     * @notice Function to set user lp limit
     */
    function setUserLpLimit(uint256 userLpLimit_) external onlyOwner {
        require(
            userLpLimit_ <= poolLpLimit,
            "User lp limit cant be more than pool limit"
        );
        userLpLimit = userLpLimit_;
        emit LogSetUserLpLimit(userLpLimit);
    }

    /**
     * @notice Function to enable pool lp limit
     */
    function setEnablePoolLpLimit(bool enablePoolLpLimit_) external onlyOwner {
        enablePoolLpLimit = enablePoolLpLimit_;
        emit LogSetEnablePoolLpLimit(enablePoolLpLimit);
    }

    /**
     * @notice Function to set pool lp limit
     */
    function setPoolLpLimit(uint256 poolLpLimit_) external onlyOwner {
        require(
            poolLpLimit_ >= userLpLimit,
            "Pool lp limit cant be less than user lp limit"
        );
        poolLpLimit = poolLpLimit_;
        emit LogSetPoolLpLimit(poolLpLimit);
    }

    /**
     * @notice Function to set address of the random number consumer (chain link vrf)
     */
    function setRandomNumberConsumer(
        IRandomNumberConsumer randomNumberConsumer_
    ) external onlyOwner {
        randomNumberConsumer = IRandomNumberConsumer(randomNumberConsumer_);
        emit LogSetRandomNumberConsumer(randomNumberConsumer);
    }

    function setMultiSigRewardPercentage(uint256 multiSigRewardPercentage_)
        external
        onlyOwner
    {
        multiSigRewardPercentage = multiSigRewardPercentage_;
        emit LogSetMultiSigRewardPercentage(multiSigRewardPercentage);
    }

    function setMultiSigAddress(address multiSigAddress_) external onlyOwner {
        multiSigAddress = multiSigAddress_;
        emit LogSetMultiSigAddress(multiSigAddress);
    }

    /**
     * @notice Function to set the normal distribution array and its associated mean/deviation
     */
    function setNormalDistribution(
        uint256 normalDistributionMean_,
        uint256 normalDistributionDeviation_,
        uint256[100] calldata normalDistribution_
    ) external onlyOwner {
        normalDistributionMean = normalDistributionMean_;
        normalDistributionDeviation = normalDistributionDeviation_;
        normalDistribution = normalDistribution_;
        emit LogSetNormalDistribution(
            normalDistributionMean,
            normalDistributionDeviation,
            normalDistribution
        );
    }

    function initialize(
        address debase_,
        address pairToken_,
        address policy_,
        address randomNumberConsumer_,
        address link_,
        uint256 rewardPercentage_,
        uint256 blockDuration_,
        bool enableUserLpLimit_,
        uint256 userLpLimit_,
        bool enablePoolLpLimit_,
        uint256 poolLpLimit_,
        uint256 revokeRewardDuration_,
        uint256 normalDistributionMean_,
        uint256 normalDistributionDeviation_,
        uint256[100] memory normalDistribution_
    ) public initializer {
        setStakeToken(pairToken_);
        debase = IERC20(debase_);
        link = IERC20(link_);
        randomNumberConsumer = IRandomNumberConsumer(randomNumberConsumer_);
        policy = policy_;
        count = 0;

        blockDuration = blockDuration_;
        enableUserLpLimit = enableUserLpLimit_;
        userLpLimit = userLpLimit_;
        enablePoolLpLimit = enablePoolLpLimit_;
        poolLpLimit = poolLpLimit_;
        rewardPercentage = rewardPercentage_;
        revokeRewardDuration = revokeRewardDuration_;
        countInSequence = true;
        normalDistribution = normalDistribution_;
        normalDistributionMean = normalDistributionMean_;
        normalDistributionDeviation = normalDistributionDeviation_;
    }

    /**
     * @notice When a rebase happens this function is called by the rebase function. If the supplyDelta is positive (supply increase) a random
     * will be constructed using Chainlink VRF. The mod of the random number is taken to get a number between 0-100. This result
     * is used as a index to get a number from the normal distribution array. The number returned will be compared against the current count of
     * positive rebases and if the count is equal to or greater that the number obtained from array, then the pool will request rewards from the stabilizer pool.
     */
    function checkStabilizerAndGetReward(
        int256 supplyDelta_,
        int256 rebaseLag_,
        uint256 exchangeRate_,
        uint256 debasePolicyBalance
    ) external returns (uint256 rewardAmount_) {
        require(
            msg.sender == policy,
            "Only debase policy contract can call this"
        );

        if (newBufferFunds) {
            uint256 previousUnusedRewardToClaim =
                debase.totalSupply().mul(lastRewardPercentage).div(10**18);

            if (
                debase.balanceOf(address(this)) >= previousUnusedRewardToClaim
            ) {
                debase.safeTransfer(policy, previousUnusedRewardToClaim);
                emit LogRewardsClaimed(previousUnusedRewardToClaim);
            }
            newBufferFunds = false;
        }

        if (supplyDelta_ > 0) {
            count = count.add(1);

            // Call random number fetcher only if the random number consumer has link in its balance to do so. Otherwise return 0
            if (
                link.balanceOf(address(randomNumberConsumer)) >=
                randomNumberConsumer.fee() &&
                (beforePeriodFinish || block.number >= periodFinish)
            ) {
                uint256 rewardToClaim =
                    debasePolicyBalance.mul(rewardPercentage).div(10**18);

                uint256 multiSigRewardAmount =
                    rewardToClaim.mul(multiSigRewardPercentage).div(10**18);

                lastRewardPercentage = rewardToClaim.mul(10**18).div(
                    debase.totalSupply()
                );

                multiSigRewardToClaimShare = multiSigRewardAmount
                    .mul(10**18)
                    .div(debase.totalSupply());

                uint256 totalRewardToClaim =
                    rewardToClaim.add(multiSigRewardAmount);

                if (totalRewardToClaim <= debasePolicyBalance) {
                    newBufferFunds = true;
                    randomNumberConsumer.getRandomNumber(block.number);
                    emit LogRewardsClaimed(totalRewardToClaim);
                    return totalRewardToClaim;
                }
            }
        } else if (countInSequence) {
            count = 0;

            if (revokeReward && block.number < periodFinish) {
                uint256 timeRemaining = periodFinish.sub(block.number);
                // Rewards will only be revoked from period after the current period so unclaimed rewards arent taken away.
                if (timeRemaining >= revokeRewardDuration) {
                    //Set reward distribution period back
                    periodFinish = periodFinish.sub(revokeRewardDuration);
                    //Calculate reward to rewark by amount the reward moved back
                    uint256 rewardToRevokeShare =
                        rewardRate.mul(revokeRewardDuration);

                    uint256 rewardToRevokeAmount =
                        debase.totalSupply().mul(rewardToRevokeShare).div(
                            10**18
                        );

                    lastUpdateBlock = block.number;

                    debase.safeTransfer(policy, rewardToRevokeAmount);
                    emit LogRewardRevoked(
                        revokeRewardDuration,
                        rewardToRevokeShare,
                        rewardToRevokeAmount
                    );
                }
            }
        }
        return 0;
    }

    function claimer(uint256 randomNumber) external {
        require(
            msg.sender == address(randomNumberConsumer),
            "Only debase policy contract can call this"
        );
        newBufferFunds = false;

        uint256 lastRandomThreshold = normalDistribution[randomNumber.mod(100)];
        emit LogLastRandomThreshold(lastRandomThreshold);

        if (count >= lastRandomThreshold) {
            startNewDistributionCycle();
            count = 0;

            if (multiSigRewardToClaimShare != 0) {
                uint256 amountToClaim =
                    debase.totalSupply().mul(multiSigRewardToClaimShare).div(
                        10**18
                    );

                debase.transfer(multiSigAddress, amountToClaim);
            }
        } else {
            uint256 rewardToClaim =
                debase.totalSupply().mul(lastRewardPercentage).div(10**18);

            debase.safeTransfer(policy, rewardToClaim);
            emit LogClaimRevoked(rewardToClaim);
        }
    }

    /**
     * @notice Function allows for emergency withdrawal of all reward tokens back into stabilizer fund
     */
    function emergencyWithdraw() external onlyOwner {
        debase.safeTransfer(policy, debase.balanceOf(address(this)));
        emit LogEmergencyWithdraw(block.number);
    }

    function lastBlockRewardApplicable() internal view returns (uint256) {
        return Math.min(block.number, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastBlockRewardApplicable()
                    .sub(lastUpdateBlock)
                    .mul(rewardRate)
                    .mul(10**18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(10**18)
                .add(rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount)
        public
        override
        nonReentrant
        updateReward(msg.sender)
        enabled
    {
        require(
            !address(msg.sender).isContract(),
            "Caller must not be a contract"
        );
        require(amount > 0, "Cannot stake 0");

        if (enablePoolLpLimit) {
            uint256 lpBalance = totalSupply();
            require(
                amount.add(lpBalance) <= poolLpLimit,
                "Cant stake pool lp limit reached"
            );
        }
        if (enableUserLpLimit) {
            uint256 userLpBalance = balanceOf(msg.sender);
            require(
                userLpBalance.add(amount) <= userLpLimit,
                "Cant stake more than lp limit"
            );
        }

        super.stake(amount);
        emit LogStaked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        override
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit LogWithdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public nonReentrant updateReward(msg.sender) enabled {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;

            uint256 rewardToClaim =
                debase.totalSupply().mul(reward).div(10**18);

            debase.safeTransfer(msg.sender, rewardToClaim);

            emit LogRewardPaid(msg.sender, rewardToClaim);
            rewardDistributed = rewardDistributed.add(reward);
        }
    }

    function startNewDistributionCycle() internal updateReward(address(0)) {
        // https://sips.synthetix.io/sips/sip-77
        require(
            debase.balanceOf(address(this)) < uint256(-1) / 10**18,
            "Rewards: rewards too large, would lock"
        );

        if (block.number >= periodFinish) {
            rewardRate = lastRewardPercentage.div(blockDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.number);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = lastRewardPercentage.add(leftover).div(blockDuration);
        }
        lastUpdateBlock = block.number;
        periodFinish = block.number.add(blockDuration);

        emit LogStartNewDistributionCycle(
            lastRewardPercentage,
            rewardRate,
            periodFinish,
            count
        );
    }
}
