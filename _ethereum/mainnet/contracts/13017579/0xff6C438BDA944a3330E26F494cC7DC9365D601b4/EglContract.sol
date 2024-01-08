pragma solidity 0.6.6;

import "./EglToken.sol";
import "./IEglGenesis.sol";
import "./Math.sol";

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./SignedSafeMathUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

/**
 * @title EGL Voting Smart Contract
 * @author Shane van Coller
 */
contract EglContract is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using Math for *;
    using SafeMathUpgradeable for *;
    using SignedSafeMathUpgradeable for int;

    uint8 constant WEEKS_IN_YEAR = 52;
    uint constant DECIMAL_PRECISION = 10**18;

    /* PUBLIC STATE VARIABLES */
    int public desiredEgl;
    int public baselineEgl;
    int public initialEgl;
    int public tallyVotesGasLimit;

    uint public creatorEglsTotal;
    uint public liquidityEglMatchingTotal;

    uint16 public currentEpoch;
    uint public currentEpochStartDate;
    uint public tokensInCirculation;

    uint[52] public voterRewardSums;
    uint[8] public votesTotal;
    uint[8] public voteWeightsSum;
    uint[8] public gasTargetSum;

    mapping(address => Voter) public voters;
    mapping(address => Supporter) public supporters;
    mapping(address => uint) public seeders;

    struct Voter {
        uint8 lockupDuration;
        uint16 voteEpoch;
        uint releaseDate;
        uint tokensLocked;
        uint gasTarget;
    }

    struct Supporter {
        uint32 claimed;
        uint poolTokens;
        uint firstEgl;
        uint lastEgl;
    }

    /* PRIVATE STATE VARIABLES */
    EglToken private eglToken;
    IERC20Upgradeable private balancerPoolToken;
    IEglGenesis private eglGenesis;

    address private creatorRewardsAddress;
    
    int private epochGasLimitSum;
    int private epochVoteCount;
    int private desiredEglThreshold;

    uint24 private votingPauseSeconds;
    uint32 private epochLength;
    uint private firstEpochStartDate;
    uint private latestRewardSwept;
    uint private minLiquidityTokensLockup;
    uint private creatorRewardFirstEpoch;
    uint private remainingPoolReward;
    uint private remainingCreatorReward;
    uint private remainingDaoBalance;
    uint private remainingSeederBalance;
    uint private remainingSupporterBalance;
    uint private remainingBptBalance;
    uint private remainingVoterReward;
    uint private lastSerializedEgl;
    uint private ethEglRatio;
    uint private ethBptRatio;
    uint private voterRewardMultiplier;
    uint private gasTargetTolerance;    
    uint16 private voteThresholdGracePeriod;

    /* EVENTS */
    event Initialized(
        address deployer,
        address eglContract,
        address eglToken,
        address genesisContract,
        address balancerToken,
        uint totalGenesisEth,
        uint ethEglRatio,
        uint ethBptRatio,
        uint minLiquidityTokensLockup,
        uint firstEpochStartDate,
        uint votingPauseSeconds,
        uint epochLength,
        uint date
    );
    event Vote(
        address caller,
        uint16 currentEpoch,
        uint gasTarget,
        uint eglAmount,
        uint8 lockupDuration,
        uint releaseDate,
        uint epochVoteWeightSum,
        uint epochGasTargetSum,
        uint epochVoterRewardSum,
        uint epochTotalVotes,
        uint date
    );
    event ReVote(
        address caller, 
        uint gasTarget, 
        uint eglAmount, 
        uint date
    );
    event Withdraw(
        address caller,
        uint16 currentEpoch,
        uint tokensLocked,
        uint rewardTokens,
        uint gasTarget,
        uint epochVoterRewardSum,
        uint epochTotalVotes,
        uint epochVoteWeightSum,
        uint epochGasTargetSum,
        uint date
    );
    event VotesTallied(
        address caller,
        uint16 currentEpoch,
        int desiredEgl,
        int averageGasTarget,
        uint votingThreshold,
        uint actualVotePercentage,
        int baselineEgl,
        uint tokensInCirculation,
        uint date
    );
    event CreatorRewardsClaimed(
        address caller,
        address creatorRewardAddress,
        uint amountClaimed,
        uint lastSerializedEgl,
        uint remainingCreatorReward,
        uint16 currentEpoch,
        uint date
    );
    event VoteThresholdMet(
        address caller,
        uint16 currentEpoch,
        int desiredEgl,
        uint voteThreshold,
        uint actualVotePercentage,
        int gasLimitSum,
        int voteCount,
        int baselineEgl,
        uint date
    );
    event VoteThresholdFailed(
        address caller,
        uint16 currentEpoch,
        int desiredEgl,
        uint voteThreshold,
        uint actualVotePercentage,
        int baselineEgl,
        int initialEgl,
        uint timeSinceFirstEpoch,
        uint gracePeriodSeconds,
        uint date
    );
    event PoolRewardsSwept(
        address caller, 
        address coinbaseAddress,
        uint blockNumber, 
        int blockGasLimit, 
        uint blockReward, 
        uint date
    );
    event BlockRewardCalculated(
        uint blockNumber, 
        uint16 currentEpoch,
        uint remainingPoolReward,
        int blockGasLimit, 
        int desiredEgl,
        int tallyVotesGasLimit,
        uint proximityRewardPercent,
        uint totalRewardPercent,
        uint blockReward,
        uint date
    );
    event SeedAccountClaimed(
        address seedAddress, 
        uint individualSeedAmount, 
        uint releaseDate,
        uint date
    );
    event VoterRewardCalculated(
        address voter,
        uint16 currentEpoch,
        uint voterReward,
        uint epochVoterReward,
        uint voteWeight,
        uint rewardMultiplier,
        uint weeksDiv,
        uint epochVoterRewardSum,
        uint remainingVoterRewards,
        uint date
    );
    event SupporterTokensClaimed(
        address caller,
        uint amountContributed,
        uint gasTarget,
        uint lockDuration,
        uint ethEglRatio,
        uint ethBptRatio,
        uint bonusEglsReceived,
        uint poolTokensReceived,
        uint remainingSupporterBalance,
        uint remainingBptBalance, 
        uint date
    );
    event PoolTokensWithdrawn(
        address caller, 
        uint currentSerializedEgl, 
        uint poolTokensDue, 
        uint poolTokens, 
        uint firstEgl, 
        uint lastEgl, 
        uint eglReleaseDate,
        uint date
    );  
    event SerializedEglCalculated(
        uint currentEpoch, 
        uint secondsSinceEglStart,
        uint timePassedPercentage, 
        uint serializedEgl,
        uint maxSupply,
        uint date
    );
    event SeedAccountAdded(
        address seedAccount,
        uint seedAmount,
        uint remainingSeederBalance,
        uint date
    );
    
    /**
     * @notice Revert any transactions that attempts to send ETH to the contract directly
     */
    receive() external payable {
        revert("EGL:NO_PAYMENTS");
    }

    /* EXTERNAL FUNCTIONS */
    /**
     * @notice Initialized contract variables and sets up token bucket sizes
     *
     * @param _token Address of the EGL token     
     * @param _poolToken Address of the Balance Pool Token (BPT)
     * @param _genesis Address of the EGL Genesis contract
     * @param _currentEpochStartDate Start date for the first epoch
     * @param _votingPauseSeconds Number of seconds to pause voting before votes are tallied
     * @param _epochLength The length of each epoch in seconds
     * @param _seedAccounts List of accounts to seed with EGL's
     * @param _seedAmounts Amount of EGLS's to seed accounts with
     * @param _creatorRewardsAccount Address that creator rewards get sent to
     */
    function initialize(
        address _token,
        address _poolToken,
        address _genesis,
        uint _currentEpochStartDate,
        uint24 _votingPauseSeconds,
        uint32 _epochLength,
        address[] memory _seedAccounts,
        uint[] memory _seedAmounts,
        address _creatorRewardsAccount
    ) 
        public 
        initializer 
    {
        require(_token != address(0), "EGL:INVALID_EGL_TOKEN_ADDR");
        require(_poolToken != address(0), "EGL:INVALID_BP_TOKEN_ADDR");
        require(_genesis != address(0), "EGL:INVALID_GENESIS_ADDR");

        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();

        eglToken = EglToken(_token);
        balancerPoolToken = IERC20Upgradeable(_poolToken);
        eglGenesis = IEglGenesis(_genesis);        

        creatorEglsTotal = 750000000 ether;
        remainingCreatorReward = creatorEglsTotal;

        liquidityEglMatchingTotal = 750000000 ether;
        remainingPoolReward = 1250000000 ether;        
        remainingDaoBalance = 250000000 ether;
        remainingSeederBalance = 50000000 ether;
        remainingSupporterBalance = 500000000 ether;
        remainingVoterReward = 500000000 ether;
        
        voterRewardMultiplier = 362844.70 ether;

        uint totalGenesisEth = eglGenesis.cumulativeBalance();
        require(totalGenesisEth > 0, "EGL:NO_GENESIS_BALANCE");

        remainingBptBalance = balancerPoolToken.balanceOf(eglGenesis.owner());
        require(remainingBptBalance > 0, "EGL:NO_BPT_BALANCE");
        ethEglRatio = liquidityEglMatchingTotal.mul(DECIMAL_PRECISION)
            .div(totalGenesisEth);
        ethBptRatio = remainingBptBalance.mul(DECIMAL_PRECISION)
            .div(totalGenesisEth);

        creatorRewardFirstEpoch = 10;
        minLiquidityTokensLockup = _epochLength.mul(10);

        firstEpochStartDate = _currentEpochStartDate;
        currentEpochStartDate = _currentEpochStartDate;
        votingPauseSeconds = _votingPauseSeconds;
        epochLength = _epochLength;
        creatorRewardsAddress = _creatorRewardsAccount;
        tokensInCirculation = liquidityEglMatchingTotal;
        tallyVotesGasLimit = int(block.gaslimit);
        
        baselineEgl = int(block.gaslimit);
        initialEgl = baselineEgl;
        desiredEgl = baselineEgl;

        gasTargetTolerance = 4000000;
        desiredEglThreshold = 1000000;
        voteThresholdGracePeriod = 7;

        if (_seedAccounts.length > 0) {
            for (uint8 i = 0; i < _seedAccounts.length; i++) {
                addSeedAccount(_seedAccounts[i], _seedAmounts[i]);
            }
        }
        
        emit Initialized(
            msg.sender,
            address(this),
            address(eglToken),
            address(eglGenesis), 
            address(balancerPoolToken), 
            totalGenesisEth,
            ethEglRatio,
            ethBptRatio,
            minLiquidityTokensLockup,
            firstEpochStartDate,
            votingPauseSeconds,
            epochLength,
            block.timestamp
        );
    }

    /**
    * @notice Allows EGL Genesis contributors to claim their "bonus" EGL's from contributing in Genesis. Bonus EGL's
    * get locked up in a vote right away and can only be withdrawn once all BPT's are available
    *
    * @param _gasTarget desired gas target for initial vote
    * @param _lockupDuration duration to lock tokens for - determines vote multiplier
    */
    function claimSupporterEgls(uint _gasTarget, uint8 _lockupDuration) external whenNotPaused {
        require(remainingSupporterBalance > 0, "EGL:SUPPORTER_EGLS_DEPLETED");
        require(remainingBptBalance > 0, "EGL:BPT_BALANCE_DEPLETED");
        require(
            eglGenesis.canContribute() == false && eglGenesis.canWithdraw() == false, 
            "EGL:GENESIS_LOCKED"
        );
        require(supporters[msg.sender].claimed == 0, "EGL:ALREADY_CLAIMED");

        (uint contributionAmount, uint cumulativeBalance, ,) = eglGenesis.contributors(msg.sender);
        require(contributionAmount > 0, "EGL:NOT_CONTRIBUTED");

        if (block.timestamp > currentEpochStartDate.add(epochLength))
            tallyVotes();
        
        uint serializedEgls = contributionAmount.mul(ethEglRatio).div(DECIMAL_PRECISION);
        uint firstEgl = cumulativeBalance.sub(contributionAmount)
            .mul(ethEglRatio)
            .div(DECIMAL_PRECISION);
        uint lastEgl = firstEgl.add(serializedEgls);
        uint bonusEglsDue = Math.umin(
            _calculateBonusEglsDue(firstEgl, lastEgl), 
            remainingSupporterBalance
        );
        uint poolTokensDue = Math.umin(
            contributionAmount.mul(ethBptRatio).div(DECIMAL_PRECISION),
            remainingBptBalance
        );

        remainingSupporterBalance = remainingSupporterBalance.sub(bonusEglsDue);
        remainingBptBalance = remainingBptBalance.sub(poolTokensDue);
        tokensInCirculation = tokensInCirculation.add(bonusEglsDue);

        Supporter storage _supporter = supporters[msg.sender];        
        _supporter.claimed = 1;
        _supporter.poolTokens = poolTokensDue;
        _supporter.firstEgl = firstEgl;
        _supporter.lastEgl = lastEgl;        
        
        emit SupporterTokensClaimed(
            msg.sender,
            contributionAmount,
            _gasTarget,
            _lockupDuration,
            ethEglRatio,
            ethBptRatio,
            bonusEglsDue,
            poolTokensDue,
            remainingSupporterBalance,
            remainingBptBalance,
            block.timestamp
        );

        _internalVote(
            msg.sender,
            _gasTarget,
            bonusEglsDue,
            _lockupDuration,
            firstEpochStartDate.add(epochLength.mul(WEEKS_IN_YEAR))
        );
    }

    /**
     * @notice Function for seed/signal accounts to claim their EGL's. EGL's get locked up in a vote right away and can 
     * only be withdrawn after the seeder/signal lockup period
     *
     * @param _gasTarget desired gas target for initial vote
     * @param _lockupDuration duration to lock tokens for - determines vote multiplier
     */
    function claimSeederEgls(uint _gasTarget, uint8 _lockupDuration) external whenNotPaused {
        require(seeders[msg.sender] > 0, "EGL:NOT_SEEDER");
        if (block.timestamp > currentEpochStartDate.add(epochLength))
            tallyVotes();
        
        uint seedAmount = seeders[msg.sender];
        delete seeders[msg.sender];

        tokensInCirculation = tokensInCirculation.add(seedAmount);
        uint releaseDate = firstEpochStartDate.add(epochLength.mul(WEEKS_IN_YEAR));
        emit SeedAccountClaimed(msg.sender, seedAmount, releaseDate, block.timestamp);

        _internalVote(
            msg.sender,
            _gasTarget,
            seedAmount,
            _lockupDuration,
            releaseDate
        );
    }

    /**
     * @notice Submit vote to either increase or decrease the desired gas limit
     *
     * @param _gasTarget The votes target gas limit
     * @param _eglAmount Amount of EGL's to vote with
     * @param _lockupDuration Duration to lock the EGL's
     */
    function vote(
        uint _gasTarget,
        uint _eglAmount,
        uint8 _lockupDuration
    ) 
        external 
        whenNotPaused
        nonReentrant 
    {
        require(_eglAmount >= 1 ether, "EGL:AMNT_TOO_LOW");
        require(_eglAmount <= eglToken.balanceOf(msg.sender), "EGL:INSUFFICIENT_EGL_BALANCE");
        require(eglToken.allowance(msg.sender, address(this)) >= _eglAmount, "EGL:INSUFFICIENT_ALLOWANCE");
        if (block.timestamp > currentEpochStartDate.add(epochLength))
            tallyVotes();

        bool success = eglToken.transferFrom(msg.sender, address(this), _eglAmount);
        require(success, "EGL:TOKEN_TRANSFER_FAILED");
        _internalVote(
            msg.sender,
            _gasTarget,
            _eglAmount,
            _lockupDuration,
            0
        );
    }

    /**
     * @notice Re-Vote to change parameters of an existing vote. Will not shorten the time the tokens are 
     * locked up from the original vote 
     *
     * @param _gasTarget The votes target gas limit
     * @param _eglAmount Amount of EGL's to vote with
     * @param _lockupDuration Duration to lock the EGL's
     */
    function reVote(
        uint _gasTarget,
        uint _eglAmount,
        uint8 _lockupDuration
    ) 
        external 
        whenNotPaused
        nonReentrant
    {
        require(voters[msg.sender].tokensLocked > 0, "EGL:NOT_VOTED");
        if (_eglAmount > 0) {
            require(_eglAmount >= 1 ether, "EGL:AMNT_TOO_LOW");
            require(_eglAmount <= eglToken.balanceOf(msg.sender), "EGL:INSUFFICIENT_EGL_BALANCE");
            require(eglToken.allowance(msg.sender, address(this)) >= _eglAmount, "EGL:INSUFFICIENT_ALLOWANCE");
            bool success = eglToken.transferFrom(msg.sender, address(this), _eglAmount);
            require(success, "EGL:TOKEN_TRANSFER_FAILED");
        }
        if (block.timestamp > currentEpochStartDate.add(epochLength))
            tallyVotes();

        uint originalReleaseDate = voters[msg.sender].releaseDate;
        _eglAmount = _eglAmount.add(_internalWithdraw(msg.sender));
        _internalVote(
            msg.sender,
            _gasTarget,
            _eglAmount,
            _lockupDuration,
            originalReleaseDate
        );
        emit ReVote(msg.sender, _gasTarget, _eglAmount, block.timestamp);
    }

    /**
     * @notice Withdraw EGL's once they have matured
     */
    function withdraw() external whenNotPaused {
        require(voters[msg.sender].tokensLocked > 0, "EGL:NOT_VOTED");
        require(block.timestamp > voters[msg.sender].releaseDate, "EGL:NOT_RELEASE_DATE");
        bool success = eglToken.transfer(msg.sender, _internalWithdraw(msg.sender));
        require(success, "EGL:TOKEN_TRANSFER_FAILED");
    }

    /**
     * @notice Send EGL reward to miner of the block. Reward caclulated based on how close the block gas limit
     * is to the desired EGL. The closer it is, the higher the reward
     */
    function sweepPoolRewards() external whenNotPaused {
        require(block.number > latestRewardSwept, "EGL:ALREADY_SWEPT");
        latestRewardSwept = block.number;
        int blockGasLimit = int(block.gaslimit);
        uint blockReward = _calculateBlockReward(blockGasLimit, desiredEgl, tallyVotesGasLimit);
        if (blockReward > 0) {
            remainingPoolReward = remainingPoolReward.sub(blockReward);
            tokensInCirculation = tokensInCirculation.add(blockReward);
            bool success = eglToken.transfer(block.coinbase, Math.umin(eglToken.balanceOf(address(this)), blockReward));
            require(success, "EGL:TOKEN_TRANSFER_FAILED");
        }

        emit PoolRewardsSwept(
            msg.sender, 
            block.coinbase,
            latestRewardSwept, 
            blockGasLimit, 
            blockReward,
            block.timestamp
        );
    }

    /**
     * @notice Allows for the withdrawal of liquidity pool tokens once they have matured
     */
    function withdrawPoolTokens() external whenNotPaused {
        require(supporters[msg.sender].poolTokens > 0, "EGL:NO_POOL_TOKENS");
        require(block.timestamp.sub(firstEpochStartDate) > minLiquidityTokensLockup, "EGL:ALL_TOKENS_LOCKED");

        uint currentSerializedEgl = _calculateSerializedEgl(
            block.timestamp.sub(firstEpochStartDate), 
            liquidityEglMatchingTotal, 
            minLiquidityTokensLockup
        );

        Voter storage _voter = voters[msg.sender];
        Supporter storage _supporter = supporters[msg.sender];
        require(_supporter.firstEgl <= currentSerializedEgl, "EGL:ADDR_TOKENS_LOCKED");

        uint poolTokensDue;
        if (currentSerializedEgl >= _supporter.lastEgl) {
            poolTokensDue = _supporter.poolTokens;
            _supporter.poolTokens = 0;
            
            uint releaseEpoch = _voter.voteEpoch.add(_voter.lockupDuration);
            _voter.releaseDate = releaseEpoch > currentEpoch
                ? block.timestamp.add(releaseEpoch.sub(currentEpoch).mul(epochLength))
                : block.timestamp;

            emit PoolTokensWithdrawn(
                msg.sender, 
                currentSerializedEgl, 
                poolTokensDue, 
                _supporter.poolTokens,
                _supporter.firstEgl, 
                _supporter.lastEgl, 
                _voter.releaseDate,
                block.timestamp
            );
        } else {
            poolTokensDue = _calculateCurrentPoolTokensDue(
                currentSerializedEgl, 
                _supporter.firstEgl, 
                _supporter.lastEgl, 
                _supporter.poolTokens
            );
            _supporter.poolTokens = _supporter.poolTokens.sub(poolTokensDue);
            emit PoolTokensWithdrawn(
                msg.sender,
                currentSerializedEgl,
                poolTokensDue,
                _supporter.poolTokens,
                _supporter.firstEgl,
                _supporter.lastEgl,
                _voter.releaseDate,
                block.timestamp
            );
            _supporter.firstEgl = currentSerializedEgl;
        }        

        bool success = balancerPoolToken.transfer(
            msg.sender, 
            Math.umin(balancerPoolToken.balanceOf(address(this)), poolTokensDue)
        );        
        require(success, "EGL:TOKEN_TRANSFER_FAILED");
    }

    /**
     * @notice Ower only funciton to pause contract
     */
    function pauseEgl() external onlyOwner whenNotPaused {
        _pause();
    }

    /** 
     * @notice Owner only function to unpause contract
     */
    function unpauseEgl() external onlyOwner whenPaused {
        _unpause();
    }

    /* PUBLIC FUNCTIONS */
    /**
     * @notice Tally Votes for the most recent epoch and calculate the new desired EGL amount
     */
    function tallyVotes() public whenNotPaused {
        require(block.timestamp > currentEpochStartDate.add(epochLength), "EGL:VOTE_NOT_ENDED");
        tallyVotesGasLimit = int(block.gaslimit);

        uint votingThreshold = currentEpoch <= voteThresholdGracePeriod
            ? DECIMAL_PRECISION.mul(10)
            : DECIMAL_PRECISION.mul(30);

	    if (currentEpoch >= WEEKS_IN_YEAR) {
            uint actualThreshold = votingThreshold.add(
                (DECIMAL_PRECISION.mul(20).div(WEEKS_IN_YEAR.mul(2)))
                .mul(currentEpoch.sub(WEEKS_IN_YEAR.sub(1)))
            );
            votingThreshold = Math.umin(actualThreshold, 50 * DECIMAL_PRECISION);
        }

        int averageGasTarget = voteWeightsSum[0] > 0
            ? int(gasTargetSum[0].div(voteWeightsSum[0]))
            : 0;
        uint votePercentage = _calculatePercentageOfTokensInCirculation(votesTotal[0]);
        if (votePercentage >= votingThreshold) {
            epochGasLimitSum = epochGasLimitSum.add(int(tallyVotesGasLimit));
            epochVoteCount = epochVoteCount.add(1);
            baselineEgl = epochGasLimitSum.div(epochVoteCount);

            desiredEgl = baselineEgl > averageGasTarget
                ? baselineEgl.sub(baselineEgl.sub(averageGasTarget).min(desiredEglThreshold))
                : baselineEgl.add(averageGasTarget.sub(baselineEgl).min(desiredEglThreshold));

            if (
                desiredEgl >= tallyVotesGasLimit.sub(10000) &&
                desiredEgl <= tallyVotesGasLimit.add(10000)
            ) 
                desiredEgl = tallyVotesGasLimit;

            emit VoteThresholdMet(
                msg.sender,
                currentEpoch,
                desiredEgl,
                votingThreshold,
                votePercentage,
                epochGasLimitSum,
                epochVoteCount,
                baselineEgl,
                block.timestamp
            );
        } else {
            if (block.timestamp.sub(firstEpochStartDate) >= epochLength.mul(voteThresholdGracePeriod))
                desiredEgl = tallyVotesGasLimit.mul(95).div(100);

            emit VoteThresholdFailed(
                msg.sender,
                currentEpoch,
                desiredEgl,
                votingThreshold,
                votePercentage,
                baselineEgl,
                initialEgl,
                block.timestamp.sub(firstEpochStartDate),
                epochLength.mul(6),
                block.timestamp
            );
        }

        // move values 1 slot earlier and put a '0' at the last slot
        for (uint8 i = 0; i < 7; i++) {
            voteWeightsSum[i] = voteWeightsSum[i + 1];
            gasTargetSum[i] = gasTargetSum[i + 1];
            votesTotal[i] = votesTotal[i + 1];
        }
        voteWeightsSum[7] = 0;
        gasTargetSum[7] = 0;
        votesTotal[7] = 0;

        epochGasLimitSum = 0;
        epochVoteCount = 0;

        if (currentEpoch >= creatorRewardFirstEpoch && remainingCreatorReward > 0)
            _issueCreatorRewards(currentEpoch);

        currentEpoch += 1;
        currentEpochStartDate = currentEpochStartDate.add(epochLength);

        emit VotesTallied(
            msg.sender,
            currentEpoch - 1,
            desiredEgl,
            averageGasTarget,
            votingThreshold,
            votePercentage,
            baselineEgl,
            tokensInCirculation,
            block.timestamp
        );
    }

    /**
     * @notice Owner only function to add a seeder account with specified number of EGL's. Amount cannot
     * exceed balance allocated for seed/signal accounts
     *
     * @param _seedAccount Wallet address of seeder
     * @param _seedAmount Amount of EGL's to seed
     */
    function addSeedAccount(address _seedAccount, uint _seedAmount) public onlyOwner {
        require(_seedAmount <= remainingSeederBalance, "EGL:INSUFFICIENT_SEED_BALANCE");
        require(seeders[_seedAccount] == 0, "EGL:ALREADY_SEEDER");
        require(voters[_seedAccount].tokensLocked == 0, "EGL:ALREADY_HAS_VOTE");
        require(eglToken.balanceOf(_seedAccount) == 0, "EGL:ALREADY_HAS_EGLS");
        require(block.timestamp < firstEpochStartDate.add(minLiquidityTokensLockup), "EGL:SEED_PERIOD_PASSED");
        (uint contributorAmount,,,) = eglGenesis.contributors(_seedAccount);
        require(contributorAmount == 0, "EGL:IS_CONTRIBUTOR");
        
        remainingSeederBalance = remainingSeederBalance.sub(_seedAmount);
        remainingDaoBalance = remainingDaoBalance.sub(_seedAmount);
        seeders[_seedAccount] = _seedAmount;
        emit SeedAccountAdded(
            _seedAccount,
            _seedAmount,
            remainingSeederBalance,
            block.timestamp
        );
    }

    /**
     * @notice Do not allow owner to renounce ownership, only transferOwnership
     */
    function renounceOwnership() public override onlyOwner {
        revert("EGL:NO_RENOUNCE_OWNERSHIP");
    }

    /* INTERNAL FUNCTIONS */
    /**
     * @notice Internal function that adds the vote 
     *
     * @param _voter Address the vote should to assigned to
     * @param _gasTarget The target gas limit amount
     * @param _eglAmount Amount of EGL's to vote with
     * @param _lockupDuration Duration to lock the EGL's
     * @param _releaseTime Date the EGL's are available to withdraw
     */
    function _internalVote(
        address _voter,
        uint _gasTarget,
        uint _eglAmount,
        uint8 _lockupDuration,
        uint _releaseTime
    ) internal {
        require(_voter != address(0), "EGL:VOTER_ADDRESS_0");
        require(block.timestamp >= firstEpochStartDate, "EGL:VOTING_NOT_STARTED");
        require(voters[_voter].tokensLocked == 0, "EGL:ALREADY_VOTED");
        require(
            Math.udelta(_gasTarget, block.gaslimit) < gasTargetTolerance,
            "EGL:INVALID_GAS_TARGET"
        );

        require(_lockupDuration >= 1 && _lockupDuration <= 8, "EGL:INVALID_LOCKUP");
        require(block.timestamp < currentEpochStartDate.add(epochLength), "EGL:VOTE_TOO_FAR");
        require(block.timestamp < currentEpochStartDate.add(epochLength).sub(votingPauseSeconds), "EGL:VOTE_TOO_CLOSE");

        epochGasLimitSum = epochGasLimitSum.add(int(block.gaslimit));
        epochVoteCount = epochVoteCount.add(1);

        uint updatedReleaseDate = block.timestamp.add(_lockupDuration.mul(epochLength)).umax(_releaseTime);

        Voter storage voter = voters[_voter];
        voter.voteEpoch = currentEpoch;
        voter.lockupDuration = _lockupDuration;
        voter.releaseDate = updatedReleaseDate;
        voter.tokensLocked = _eglAmount;
        voter.gasTarget = _gasTarget;

        // Add the vote
        uint voteWeight = _eglAmount.mul(_lockupDuration);
        for (uint8 i = 0; i < _lockupDuration; i++) {
            voteWeightsSum[i] = voteWeightsSum[i].add(voteWeight);
            gasTargetSum[i] = gasTargetSum[i].add(_gasTarget.mul(voteWeight));
            if (currentEpoch.add(i) < WEEKS_IN_YEAR)
                voterRewardSums[currentEpoch.add(i)] = voterRewardSums[currentEpoch.add(i)].add(voteWeight);
            votesTotal[i] = votesTotal[i].add(_eglAmount);
        }

        emit Vote(
            _voter,
            currentEpoch,
            _gasTarget,
            _eglAmount,
            _lockupDuration,
            updatedReleaseDate,
            voteWeightsSum[0],
            gasTargetSum[0],
            currentEpoch < WEEKS_IN_YEAR ? voterRewardSums[currentEpoch]: 0,
            votesTotal[0],
            block.timestamp
        );
    }

    /**
     * @notice Internal function that removes the vote from current and future epochs as well as
     * calculates the rewards due for the time the tokens were locked
     *
     * @param _voter Address the voter for be withdrawn for
     * @return totalWithdrawn - The original vote amount + the total reward tokens due
     */
    function _internalWithdraw(address _voter) internal returns (uint totalWithdrawn) {
        require(_voter != address(0), "EGL:VOTER_ADDRESS_0");
        Voter storage voter = voters[_voter];
        uint16 voterEpoch = voter.voteEpoch;
        uint originalEglAmount = voter.tokensLocked;
        uint8 lockupDuration = voter.lockupDuration;
        uint gasTarget = voter.gasTarget;
        delete voters[_voter];

        uint voteWeight = originalEglAmount.mul(lockupDuration);
        uint voterReward = _calculateVoterReward(_voter, currentEpoch, voterEpoch, lockupDuration, voteWeight);        

        // Remove the gas target vote
        uint voterInterval = voterEpoch.add(lockupDuration);
        uint affectedEpochs = currentEpoch < voterInterval ? voterInterval.sub(currentEpoch) : 0;
        for (uint8 i = 0; i < affectedEpochs; i++) {
            voteWeightsSum[i] = voteWeightsSum[i].sub(voteWeight);
            gasTargetSum[i] = gasTargetSum[i].sub(voteWeight.mul(gasTarget));
            if (currentEpoch.add(i) < WEEKS_IN_YEAR) {
                voterRewardSums[currentEpoch.add(i)] = voterRewardSums[currentEpoch.add(i)].sub(voteWeight);
            }
            votesTotal[i] = votesTotal[i].sub(originalEglAmount);
        }
        
        tokensInCirculation = tokensInCirculation.add(voterReward);

        emit Withdraw(
            _voter,
            currentEpoch,
            originalEglAmount,
            voterReward,
            gasTarget,
            currentEpoch < WEEKS_IN_YEAR ? voterRewardSums[currentEpoch]: 0,
            votesTotal[0],
            voteWeightsSum[0],
            gasTargetSum[0],
            block.timestamp
        );
        totalWithdrawn = originalEglAmount.add(voterReward);
    }

    /**
     * @notice Calculates and issues creator reward EGLs' based on the release schedule
     *
     * @param _rewardEpoch The epoch number to calcualte the rewards for
     */
    function _issueCreatorRewards(uint _rewardEpoch) internal {
        uint serializedEgl = _calculateSerializedEgl(
            _rewardEpoch.mul(epochLength), 
            creatorEglsTotal,
            creatorRewardFirstEpoch.mul(epochLength)
        );
        uint creatorRewardForEpoch = serializedEgl > 0
            ? serializedEgl.sub(lastSerializedEgl).umin(remainingCreatorReward)
            : 0;
                
        bool success = eglToken.transfer(creatorRewardsAddress, creatorRewardForEpoch);
        require(success, "EGL:TOKEN_TRANSFER_FAILED");
        remainingCreatorReward = remainingCreatorReward.sub(creatorRewardForEpoch);
        tokensInCirculation = tokensInCirculation.add(creatorRewardForEpoch);

        emit CreatorRewardsClaimed(
            msg.sender,
            creatorRewardsAddress,
            creatorRewardForEpoch,
            lastSerializedEgl,
            remainingCreatorReward,
            currentEpoch,
            block.timestamp
        );
        lastSerializedEgl = serializedEgl;
    }

    /**
     * @notice Calulates the block reward depending on the current blocks gas limit
     *
     * @param _blockGasLimit Gas limit of the currently mined block
     * @param _desiredEgl Current desired EGL value
     * @param _tallyVotesGasLimit Gas limit of the block that contained the tally votes tx
     * @return blockReward The calculated block reward
     */
    function _calculateBlockReward(
        int _blockGasLimit, 
        int _desiredEgl, 
        int _tallyVotesGasLimit
    ) 
        internal 
        returns (uint blockReward) 
    {
        uint totalRewardPercent;
        uint proximityRewardPercent;
        int eglDelta = Math.delta(_tallyVotesGasLimit, _desiredEgl);
        int actualDelta = Math.delta(_tallyVotesGasLimit, _blockGasLimit);
        int ceiling = _desiredEgl.add(10000);
        int floor = _desiredEgl.sub(10000);

        if (_blockGasLimit >= floor && _blockGasLimit <= ceiling) {
            totalRewardPercent = DECIMAL_PRECISION.mul(100);
        } else if (eglDelta > 0 && (
                (
                    _desiredEgl > _tallyVotesGasLimit 
                    && _blockGasLimit > _tallyVotesGasLimit 
                    && _blockGasLimit <= ceiling
                ) || (
                    _desiredEgl < _tallyVotesGasLimit 
                    && _blockGasLimit < _tallyVotesGasLimit 
                    && _blockGasLimit >= floor
                )
            )            
        ) {
            proximityRewardPercent = uint(actualDelta.mul(int(DECIMAL_PRECISION))
                .div(eglDelta))
                .mul(75);                
            totalRewardPercent = proximityRewardPercent.add(DECIMAL_PRECISION.mul(25));
        }

        blockReward = totalRewardPercent.mul(remainingPoolReward.div(2500000))
            .div(DECIMAL_PRECISION)
            .div(100);

        emit BlockRewardCalculated(
            block.number,
            currentEpoch,
            remainingPoolReward,
            _blockGasLimit,
            _desiredEgl,
            _tallyVotesGasLimit,
            proximityRewardPercent,
            totalRewardPercent, 
            blockReward,
            block.timestamp
        );
    }

    /**
     * @notice Calculates the current serialized EGL given a time input
     * 
     * @param _timeSinceOrigin Seconds passed since the first epoch started
     * @param _maxEglSupply The maximum supply of EGL's for the thing we're calculating for
     * @param _timeLocked The minimum lockup period for the thing we're calculating for
     * @return serializedEgl The serialized EGL for the exact second the function was called
     */
    function _calculateSerializedEgl(uint _timeSinceOrigin, uint _maxEglSupply, uint _timeLocked) 
        internal                  
        returns (uint serializedEgl) 
    {
        if (_timeSinceOrigin >= epochLength.mul(WEEKS_IN_YEAR))
            return _maxEglSupply;

        uint timePassedPercentage = _timeSinceOrigin
            .sub(_timeLocked)
            .mul(DECIMAL_PRECISION)
            .div(
                epochLength.mul(WEEKS_IN_YEAR).sub(_timeLocked)
            );

        // Reduced precision so that we don't overflow the uint256 when we raise to 4th power
        serializedEgl = ((timePassedPercentage.div(10**8))**4)
            .mul(_maxEglSupply.div(DECIMAL_PRECISION))
            .mul(10**8)
            .div((10**10)**3);

        emit SerializedEglCalculated(
            currentEpoch, 
            _timeSinceOrigin,
            timePassedPercentage.mul(100), 
            serializedEgl, 
            _maxEglSupply,
            block.timestamp
        );
    }

    /**
     * @notice Calculates the pool tokens due at time of calling
     * 
     * @param _currentEgl The current serialized EGL
     * @param _firstEgl The first serialized EGL of the participant
     * @param _lastEgl The last serialized EGL of the participant
     * @param _totalPoolTokens The total number of pool tokens due to the participant
     * @return poolTokensDue The number of pool tokens due based on the serialized EGL
     */
    function _calculateCurrentPoolTokensDue(
        uint _currentEgl, 
        uint _firstEgl, 
        uint _lastEgl, 
        uint _totalPoolTokens
    ) 
        internal 
        pure
        returns (uint poolTokensDue) 
    {
        require(_firstEgl < _lastEgl, "EGL:INVALID_SERIALIZED_EGLS");

        if (_currentEgl < _firstEgl) 
            return 0;

        uint eglsReleased = (_currentEgl.umin(_lastEgl)).sub(_firstEgl);
        poolTokensDue = _totalPoolTokens
            .mul(eglsReleased)
            .div(
                _lastEgl.sub(_firstEgl)
            );
    }

    /**
     * @notice Calculates bonus EGLs due
     * 
     * @param _firstEgl The first serialized EGL of the participant
     * @param _lastEgl The last serialized EGL of the participant
     * @return bonusEglsDue The number of bonus EGL's due as a result of participating in Genesis
     */
    function _calculateBonusEglsDue(
        uint _firstEgl, 
        uint _lastEgl
    )
        internal    
        pure     
        returns (uint bonusEglsDue)  
    {
        require(_firstEgl < _lastEgl, "EGL:INVALID_SERIALIZED_EGLS");

        bonusEglsDue = (_lastEgl.div(DECIMAL_PRECISION)**4)
            .sub(_firstEgl.div(DECIMAL_PRECISION)**4)
            .mul(DECIMAL_PRECISION)
            .div(
                (81/128)*(10**27)
            );
    }

    /**
     * @notice Calculates voter reward at time of withdrawal
     * 
     * @param _voter The voter to calculate rewards for
     * @param _currentEpoch The current epoch to calculate rewards for
     * @param _voterEpoch The epoch the vote was originally entered
     * @param _lockupDuration The number of epochs the vote is locked up for
     * @param _voteWeight The vote weight for this vote (vote amount * lockup duration)
     * @return rewardsDue The total rewards due for all relevant epochs
     */
    function _calculateVoterReward(
        address _voter,
        uint16 _currentEpoch,
        uint16 _voterEpoch,
        uint8 _lockupDuration,
        uint _voteWeight
    ) 
        internal         
        returns(uint rewardsDue) 
    {
        require(_voter != address(0), "EGL:VOTER_ADDRESS_0");

        uint rewardEpochs = _voterEpoch.add(_lockupDuration).umin(_currentEpoch).umin(WEEKS_IN_YEAR);
        for (uint16 i = _voterEpoch; i < rewardEpochs; i++) {
            uint epochReward = voterRewardSums[i] > 0 
                ? Math.umin(
                    _voteWeight.mul(voterRewardMultiplier)
                        .mul(WEEKS_IN_YEAR.sub(i))
                        .div(voterRewardSums[i]),
                    remainingVoterReward
                )
                : 0;
            rewardsDue = rewardsDue.add(epochReward);
            remainingVoterReward = remainingVoterReward.sub(epochReward);
            emit VoterRewardCalculated(
                _voter,
                _currentEpoch,
                rewardsDue,
                epochReward,
                _voteWeight,
                voterRewardMultiplier,
                WEEKS_IN_YEAR.sub(i),
                voterRewardSums[i],
                remainingVoterReward,
                block.timestamp
            );
        }
    }

    /**
     * @notice Calculates the percentage of tokens in circulation for a given total
     *
     * @param _total The total to calculate the percentage of
     * @return votePercentage The percentage of the total
     */
    function _calculatePercentageOfTokensInCirculation(uint _total) 
        internal 
        view 
        returns (uint votePercentage) 
    {
        votePercentage = tokensInCirculation > 0
            ? _total.mul(DECIMAL_PRECISION).mul(100).div(tokensInCirculation)
            : 0;
    }
}
