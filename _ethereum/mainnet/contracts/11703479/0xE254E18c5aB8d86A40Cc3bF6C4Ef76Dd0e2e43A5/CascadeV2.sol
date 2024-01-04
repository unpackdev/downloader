pragma solidity 0.6.12;

import "./Ownable.sol";
import "./Initializable.sol";
import "./BaseToken.sol";

interface ICascadeV1 {
    function depositInfo(address user) external view
        returns (
            uint256 _lpTokensDeposited,
            uint256 _depositTimestamp,
            uint8   _multiplierLevel,
            uint256 _mostRecentBASEWithdrawal,
            uint256 _userDepositSeconds,
            uint256 _totalDepositSeconds
        );
}

/**
 * @title CascadeV2 is a liquidity mining contract.
 */
contract CascadeV2 is OwnableUpgradeSafe {
    using SafeMath for uint256;

    mapping(address => uint256)   public userDepositsNumDeposits;
    mapping(address => uint256[]) public userDepositsNumLPTokens;
    mapping(address => uint256[]) public userDepositsDepositTimestamp;
    mapping(address => uint8[])   public userDepositsMultiplierLevel;
    mapping(address => uint256)   public userTotalLPTokensLevel1;
    mapping(address => uint256)   public userTotalLPTokensLevel2;
    mapping(address => uint256)   public userTotalLPTokensLevel3;
    mapping(address => uint256)   public userDepositSeconds;
    mapping(address => uint256)   public userLastAccountingUpdateTimestamp;

    uint256 public totalDepositedLevel1;
    uint256 public totalDepositedLevel2;
    uint256 public totalDepositedLevel3;
    uint256 public totalDepositSeconds;
    uint256 public lastAccountingUpdateTimestamp;

    uint256[] public rewardsNumShares;
    uint256[] public rewardsVestingStart;
    uint256[] public rewardsVestingDuration;
    uint256[] public rewardsSharesWithdrawn;

    IERC20 public lpToken;
    BaseToken public BASE;
    ICascadeV1 public cascadeV1;

    event Deposit(address indexed user, uint256 tokens, uint256 timestamp);
    event Withdraw(address indexed user, uint256 withdrawnLPTokens, uint256 withdrawnBASETokens, uint256 timestamp);
    event UpgradeMultiplierLevel(address indexed user, uint256 depositIndex, uint256 oldLevel, uint256 newLevel, uint256 timestamp);
    event Migrate(address indexed user, uint256 lpTokens, uint256 rewardTokens);
    event AddRewards(uint256 tokens, uint256 shares, uint256 vestingStart, uint256 vestingDuration, uint256 totalTranches);
    event SetBASEToken(address token);
    event SetLPToken(address token);
    event SetCascadeV1(address cascadeV1);
    event UpdateDepositSeconds(address user, uint256 totalDepositSeconds, uint256 userDepositSeconds);
    event AdminRescueTokens(address token, address recipient, uint256 amount);

    /**
     * @dev Called by the OpenZeppelin "upgrades" library to initialize the contract in lieu of a constructor.
     */
    function initialize() external initializer {
        __Ownable_init();

        // Copy over the rewards tranche from Cascade v1
        rewardsNumShares.push(0);
        rewardsVestingStart.push(1606763901);
        rewardsVestingDuration.push(7776000);
        rewardsSharesWithdrawn.push(0);
    }

    /**
     * Admin
     */

    /**
     * @notice Changes the address of the LP token for which staking is allowed.
     * @param _lpToken The address of the LP token.
     */
    function setLPToken(address _lpToken) external onlyOwner {
        require(_lpToken != address(0x0), "zero address");
        lpToken = IERC20(_lpToken);
        emit SetLPToken(_lpToken);
    }

    /**
     * @notice Changes the address of the BASE token.
     * @param _baseToken The address of the BASE token.
     */
    function setBASEToken(address _baseToken) external onlyOwner {
        require(_baseToken != address(0x0), "zero address");
        BASE = BaseToken(_baseToken);
        emit SetBASEToken(_baseToken);
    }

    /**
     * @notice Changes the address of Cascade v1 (for purposes of migration).
     * @param _cascadeV1 The address of Cascade v1.
     */
    function setCascadeV1(address _cascadeV1) external onlyOwner {
        require(address(_cascadeV1) != address(0x0), "zero address");
        cascadeV1 = ICascadeV1(_cascadeV1);
        emit SetCascadeV1(_cascadeV1);
    }

    /**
     * @notice Allows the admin to withdraw tokens mistakenly sent into the contract.
     * @param token The address of the token to rescue.
     * @param recipient The recipient that the tokens will be sent to.
     * @param amount How many tokens to rescue.
     */
    function adminRescueTokens(address token, address recipient, uint256 amount) external onlyOwner {
        require(token != address(0x0), "zero address");
        require(recipient != address(0x0), "bad recipient");
        require(amount > 0, "zero amount");

        bool ok = IERC20(token).transfer(recipient, amount);
        require(ok, "transfer");

        emit AdminRescueTokens(token, recipient, amount);
    }

    /**
     * @notice Allows the owner to add another tranche of rewards.
     * @param numTokens How many tokens to add to the tranche.
     * @param vestingStart The timestamp upon which vesting of this tranche begins.
     * @param vestingDuration The duration over which the tokens fully unlock.
     */
    function addRewards(uint256 numTokens, uint256 vestingStart, uint256 vestingDuration) external onlyOwner {
        require(numTokens > 0, "zero amount");
        require(vestingStart > 0, "zero vesting start");

        uint256 numShares = tokensToShares(numTokens);
        rewardsNumShares.push(numShares);
        rewardsVestingStart.push(vestingStart);
        rewardsVestingDuration.push(vestingDuration);
        rewardsSharesWithdrawn.push(0);

        bool ok = BASE.transferFrom(msg.sender, address(this), numTokens);
        require(ok, "transfer");

        emit AddRewards(numTokens, numShares, vestingStart, vestingDuration, rewardsNumShares.length);
    }

    /**
     * Public methods
     */

    /**
     * @notice Allows a user to deposit LP tokens into the Cascade.
     * @param amount How many tokens to stake.
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "zero amount");

        uint256 allowance = lpToken.allowance(msg.sender, address(this));
        require(amount <= allowance, "allowance");

        updateDepositSeconds(msg.sender);

        totalDepositedLevel1 = totalDepositedLevel1.add(amount);
        userDepositsNumDeposits[msg.sender] = userDepositsNumDeposits[msg.sender].add(1);
        userTotalLPTokensLevel1[msg.sender] = userTotalLPTokensLevel1[msg.sender].add(amount);
        userDepositsNumLPTokens[msg.sender].push(amount);
        userDepositsDepositTimestamp[msg.sender].push(now);
        userDepositsMultiplierLevel[msg.sender].push(1);

        bool ok = lpToken.transferFrom(msg.sender, address(this), amount);
        require(ok, "transferFrom");

        emit Deposit(msg.sender, amount, now);
    }

    /**
     * @notice Allows a user to withdraw LP tokens from the Cascade.
     * @param numLPTokens How many tokens to unstake.
     */
    function withdrawLPTokens(uint256 numLPTokens) external {
        require(numLPTokens > 0, "zero tokens");

        updateDepositSeconds(msg.sender);

        (
            uint256 totalAmountToWithdraw,
            uint256 totalDepositSecondsToBurn,
            uint256 amountToWithdrawLevel1,
            uint256 amountToWithdrawLevel2,
            uint256 amountToWithdrawLevel3
        ) = removeDepositSeconds(numLPTokens);

        uint256 totalRewardShares = unlockedRewardsPoolShares().mul(totalDepositSecondsToBurn).div(totalDepositSeconds);
        removeRewardShares(totalRewardShares);

        totalDepositedLevel1 = totalDepositedLevel1.sub(amountToWithdrawLevel1);
        totalDepositedLevel2 = totalDepositedLevel2.sub(amountToWithdrawLevel2);
        totalDepositedLevel3 = totalDepositedLevel3.sub(amountToWithdrawLevel3);

        userDepositSeconds[msg.sender] = userDepositSeconds[msg.sender].sub(totalDepositSecondsToBurn);
        totalDepositSeconds = totalDepositSeconds.sub(totalDepositSecondsToBurn);

        uint256 rewardTokens = sharesToTokens(totalRewardShares);

        bool ok = lpToken.transfer(msg.sender, totalAmountToWithdraw);
        require(ok, "transfer deposit");
        ok = BASE.transfer(msg.sender, rewardTokens);
        require(ok, "transfer rewards");

        emit Withdraw(msg.sender, totalAmountToWithdraw, rewardTokens, block.timestamp);
    }

    function removeDepositSeconds(uint256 numLPTokens) private
        returns (
            uint256 totalAmountToWithdraw,
            uint256 totalDepositSecondsToBurn,
            uint256 amountToWithdrawLevel1,
            uint256 amountToWithdrawLevel2,
            uint256 amountToWithdrawLevel3
        )
    {
        for (uint256 i = userDepositsNumLPTokens[msg.sender].length; i > 0; i--) {
            uint256 lpTokensToRemove;
            uint256 age = now.sub(userDepositsDepositTimestamp[msg.sender][i-1]);
            uint8   multiplier = userDepositsMultiplierLevel[msg.sender][i-1];

            if (totalAmountToWithdraw.add(userDepositsNumLPTokens[msg.sender][i-1]) <= numLPTokens) {
                lpTokensToRemove = userDepositsNumLPTokens[msg.sender][i-1];
                userDepositsNumDeposits[msg.sender] = userDepositsNumDeposits[msg.sender].sub(1);
                userDepositsNumLPTokens[msg.sender].pop();
                userDepositsDepositTimestamp[msg.sender].pop();
                userDepositsMultiplierLevel[msg.sender].pop();
            } else {
                lpTokensToRemove = numLPTokens.sub(totalAmountToWithdraw);
                userDepositsNumLPTokens[msg.sender][i-1] = userDepositsNumLPTokens[msg.sender][i-1].sub(lpTokensToRemove);
            }

            if (multiplier == 1) {
                userTotalLPTokensLevel1[msg.sender] = userTotalLPTokensLevel1[msg.sender].sub(lpTokensToRemove);
                amountToWithdrawLevel1 = amountToWithdrawLevel1.add(lpTokensToRemove);
                totalDepositSecondsToBurn = totalDepositSecondsToBurn.add(age.mul(lpTokensToRemove));
            } else if (multiplier == 2) {
                userTotalLPTokensLevel2[msg.sender] = userTotalLPTokensLevel2[msg.sender].sub(lpTokensToRemove);
                amountToWithdrawLevel2 = amountToWithdrawLevel2.add(lpTokensToRemove);
                totalDepositSecondsToBurn = totalDepositSecondsToBurn.add(lpTokensToRemove.mul(30 days + (age - 30 days).mul(2)));
            } else if (multiplier == 3) {
                userTotalLPTokensLevel3[msg.sender] = userTotalLPTokensLevel3[msg.sender].sub(lpTokensToRemove);
                amountToWithdrawLevel3 = amountToWithdrawLevel3.add(lpTokensToRemove);
                totalDepositSecondsToBurn = totalDepositSecondsToBurn.add(lpTokensToRemove.mul(30 days + uint256(30 days).mul(2) + (age - 60 days).mul(3)));
            }
            totalAmountToWithdraw = totalAmountToWithdraw.add(lpTokensToRemove);

            if (totalAmountToWithdraw >= numLPTokens) {
                break;
            }
        }
        return (
            totalAmountToWithdraw,
            totalDepositSecondsToBurn,
            amountToWithdrawLevel1,
            amountToWithdrawLevel2,
            amountToWithdrawLevel3
        );
    }

    function removeRewardShares(uint256 totalSharesToRemove) private {
        uint256 totalSharesRemovedSoFar;

        for (uint256 i = rewardsNumShares.length; i > 0; i--) {
            uint256 sharesAvailable = unlockedRewardSharesInTranche(i-1);
            if (sharesAvailable == 0) {
                continue;
            }

            uint256 sharesStillNeeded = totalSharesToRemove.sub(totalSharesRemovedSoFar);
            if (sharesAvailable > sharesStillNeeded) {
                rewardsSharesWithdrawn[i-1] = rewardsSharesWithdrawn[i-1].add(sharesStillNeeded);
                return;
            }

            rewardsSharesWithdrawn[i-1] = rewardsSharesWithdrawn[i-1].add(sharesAvailable);
            totalSharesRemovedSoFar = totalSharesRemovedSoFar.add(sharesAvailable);
            if (rewardsNumShares[i-1].sub(rewardsSharesWithdrawn[i-1]) == 0) {
                rewardsNumShares.pop();
                rewardsVestingStart.pop();
                rewardsVestingDuration.pop();
                rewardsSharesWithdrawn.pop();
            }
        }
    }

    /**
     * @notice Allows a user to upgrade their deposit-seconds multipler for the given deposits.
     * @param deposits A list of the indices of deposits to be upgraded.
     */
    function upgradeMultiplierLevel(uint256[] memory deposits) external {
        require(deposits.length > 0, "no deposits");

        updateDepositSeconds(msg.sender);

        for (uint256 i = 0; i < deposits.length; i++) {
            uint256 idx = deposits[i];
            uint256 age = now.sub(userDepositsDepositTimestamp[msg.sender][idx]);

            if (age <= 30 days || userDepositsMultiplierLevel[msg.sender][idx] == 3) {
                continue;
            }

            uint8 oldLevel = userDepositsMultiplierLevel[msg.sender][idx];
            uint256 tokensDeposited = userDepositsNumLPTokens[msg.sender][idx];

            if (age > 30 days && userDepositsMultiplierLevel[msg.sender][idx] == 1) {
                uint256 secondsSinceLevel2 = age - 30 days;
                uint256 extraDepositSeconds = tokensDeposited.mul(secondsSinceLevel2);
                totalDepositedLevel1 = totalDepositedLevel1.sub(tokensDeposited);
                totalDepositedLevel2 = totalDepositedLevel2.add(tokensDeposited);
                totalDepositSeconds  = totalDepositSeconds.add(extraDepositSeconds);

                userTotalLPTokensLevel1[msg.sender] = userTotalLPTokensLevel1[msg.sender].sub(tokensDeposited);
                userTotalLPTokensLevel2[msg.sender] = userTotalLPTokensLevel2[msg.sender].add(tokensDeposited);
                userDepositSeconds[msg.sender] = userDepositSeconds[msg.sender].add(extraDepositSeconds);
                userDepositsMultiplierLevel[msg.sender][idx] = 2;
            }

            if (age > 60 days && userDepositsMultiplierLevel[msg.sender][idx] == 2) {
                uint256 secondsSinceLevel3 = age - 60 days;
                uint256 extraDepositSeconds = tokensDeposited.mul(secondsSinceLevel3);
                totalDepositedLevel2 = totalDepositedLevel2.sub(tokensDeposited);
                totalDepositedLevel3 = totalDepositedLevel3.add(tokensDeposited);
                totalDepositSeconds  = totalDepositSeconds.add(extraDepositSeconds);

                userTotalLPTokensLevel2[msg.sender] = userTotalLPTokensLevel2[msg.sender].sub(tokensDeposited);
                userTotalLPTokensLevel3[msg.sender] = userTotalLPTokensLevel3[msg.sender].add(tokensDeposited);
                userDepositSeconds[msg.sender] = userDepositSeconds[msg.sender].add(extraDepositSeconds);
                userDepositsMultiplierLevel[msg.sender][idx] = 3;
            }
            emit UpgradeMultiplierLevel(msg.sender, idx, oldLevel, userDepositsMultiplierLevel[msg.sender][idx], block.timestamp);
        }
    }

    /**
     * @notice Called by Cascade v1 to migrate funds into Cascade v2.
     * @param user The user for whom to migrate funds.
     */
    function migrate(address user) external {
        require(msg.sender == address(cascadeV1), "only cascade v1");
        require(user != address(0x0), "zero address");

        (
            uint256 numLPTokens,
            uint256 depositTimestamp,
            uint8   multiplier,
            ,
            uint256 userDS,
            uint256 totalDS
        ) = cascadeV1.depositInfo(user);
        uint256 numRewardShares = BASE.sharesOf(address(cascadeV1)).mul(userDS).div(totalDS);

        require(numLPTokens > 0, "no stake");
        require(multiplier > 0, "zero multiplier");
        require(depositTimestamp > 0, "zero timestamp");
        require(userDS > 0, "zero seconds");

        updateDepositSeconds(user);

        userDepositsNumDeposits[msg.sender] = userDepositsNumDeposits[msg.sender].add(1);
        userDepositsNumLPTokens[user].push(numLPTokens);
        userDepositsMultiplierLevel[user].push(multiplier);
        userDepositsDepositTimestamp[user].push(depositTimestamp);
        userDepositSeconds[user] = userDS;
        userLastAccountingUpdateTimestamp[user] = now;
        totalDepositSeconds = totalDepositSeconds.add(userDS);

        rewardsNumShares[0] = rewardsNumShares[0].add(numRewardShares);

        if (multiplier == 1) {
            totalDepositedLevel1 = totalDepositedLevel1.add(numLPTokens);
            userTotalLPTokensLevel1[user] = userTotalLPTokensLevel1[user].add(numLPTokens);
        } else if (multiplier == 2) {
            totalDepositedLevel2 = totalDepositedLevel2.add(numLPTokens);
            userTotalLPTokensLevel2[user] = userTotalLPTokensLevel2[user].add(numLPTokens);
        } else if (multiplier == 3) {
            totalDepositedLevel3 = totalDepositedLevel3.add(numLPTokens);
            userTotalLPTokensLevel3[user] = userTotalLPTokensLevel3[user].add(numLPTokens);
        }

        emit Migrate(user, numLPTokens, sharesToTokens(numRewardShares));
    }

    /**
     * @notice Updates the global deposit-seconds accounting as well as that of the given user.
     * @param user The user for whom to update the accounting.
     */
    function updateDepositSeconds(address user) public {
        (totalDepositSeconds, userDepositSeconds[user]) = getUpdatedDepositSeconds(user);
        lastAccountingUpdateTimestamp = now;
        userLastAccountingUpdateTimestamp[user] = now;
        emit UpdateDepositSeconds(user, totalDepositSeconds, userDepositSeconds[user]);
    }

    /**
     * Getters
     */

    /**
     * @notice Returns the global deposit-seconds as well as that of the given user.
     * @param user The user for whom to fetch the current deposit-seconds.
     */
    function getUpdatedDepositSeconds(address user) public view returns (uint256 _totalDepositSeconds, uint256 _userDepositSeconds) {
        uint256 delta = now.sub(lastAccountingUpdateTimestamp);
        _totalDepositSeconds = totalDepositSeconds.add(delta.mul(totalDepositedLevel1
                                                                       .add( totalDepositedLevel2.mul(2) )
                                                                       .add( totalDepositedLevel3.mul(3) ) ));

        delta = now.sub(userLastAccountingUpdateTimestamp[user]);
        _userDepositSeconds  = userDepositSeconds[user].add(delta.mul(userTotalLPTokensLevel1[user]
                                                                       .add( userTotalLPTokensLevel2[user].mul(2) )
                                                                       .add( userTotalLPTokensLevel3[user].mul(3) ) ));
        return (_totalDepositSeconds, _userDepositSeconds);
    }

    /**
     * @notice Returns the BASE rewards owed to the given user.
     * @param user The user for whom to fetch the current rewards.
     */
    function owedTo(address user) public view returns (uint256) {
        require(user != address(0x0), "zero address");

        (uint256 totalDS, uint256 userDS) = getUpdatedDepositSeconds(user);
        if (totalDS == 0) {
            return 0;
        }
        return sharesToTokens(unlockedRewardsPoolShares().mul(userDS).div(totalDS));
    }

    /**
     * @notice Returns the total number of unlocked BASE in the rewards pool.
     */
    function unlockedRewardsPoolTokens() public view returns (uint256) {
        return sharesToTokens(unlockedRewardsPoolShares());
    }

    function unlockedRewardsPoolShares() private view returns (uint256) {
        uint256 totalShares;
        for (uint256 i = 0; i < rewardsNumShares.length; i++) {
            totalShares = totalShares.add(unlockedRewardSharesInTranche(i));
        }
        return totalShares;
    }

    function unlockedRewardSharesInTranche(uint256 rewardsIdx) private view returns (uint256) {
        if (rewardsVestingStart[rewardsIdx] >= now || rewardsNumShares[rewardsIdx].sub(rewardsSharesWithdrawn[rewardsIdx]) == 0) {
            return 0;
        }
        uint256 secondsIntoVesting = now.sub(rewardsVestingStart[rewardsIdx]);
        if (secondsIntoVesting > rewardsVestingDuration[rewardsIdx]) {
            return rewardsNumShares[rewardsIdx].sub(rewardsSharesWithdrawn[rewardsIdx]);
        } else {
            return rewardsNumShares[rewardsIdx].mul( secondsIntoVesting )
                                               .div( rewardsVestingDuration[rewardsIdx] == 0 ? 1 : rewardsVestingDuration[rewardsIdx] )
                                               .sub( rewardsSharesWithdrawn[rewardsIdx] );
        }
    }

    function sharesToTokens(uint256 shares) private view returns (uint256) {
        return shares.mul(BASE.totalSupply()).div(BASE.totalShares());
    }

     function tokensToShares(uint256 tokens) private view returns (uint256) {
        return tokens.mul(BASE.totalShares().div(BASE.totalSupply()));
    }

    /**
     * @notice Returns various statistics about the given user and deposit.
     * @param user The user to fetch.
     * @param depositIdx The index of the given user's deposit to fetch.
     */
    function depositInfo(address user, uint256 depositIdx) public view
        returns (
            uint256 _numLPTokens,
            uint256 _depositTimestamp,
            uint8   _multiplierLevel,
            uint256 _userDepositSeconds,
            uint256 _totalDepositSeconds,
            uint256 _owed
        )
    {
        require(user != address(0x0), "zero address");

        (_totalDepositSeconds, _userDepositSeconds) = getUpdatedDepositSeconds(user);
        return (
            userDepositsNumLPTokens[user][depositIdx],
            userDepositsDepositTimestamp[user][depositIdx],
            userDepositsMultiplierLevel[user][depositIdx],
            _userDepositSeconds,
            _totalDepositSeconds,
            owedTo(user)
        );
    }
}
