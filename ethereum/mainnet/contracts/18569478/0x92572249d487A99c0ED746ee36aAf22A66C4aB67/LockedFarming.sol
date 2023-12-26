// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./IERC20.sol";

import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./Context.sol";
import "./Ownable.sol";

/**
 * @title Farming
 * @notice Seedify's farming contract: stake LP token and earn rewards.
 * @custom:audit This contract is NOT made to be used with deflationary tokens at all.
 */
contract SMD_v5 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant SECONDS_PER_HOUR = 3600; // 60 * 60

    /// @notice LP token address to deposit to earn rewards.
    address public tokenAddress;
    /// @notice token address to in which rewards will be paid in.
    address public rewardTokenAddress;
    /// @notice total amount of {tokenAddress} staked in the contract over its whole existence.
    uint256 public totalStaked;
    /**
     * @notice current amount of {tokenAddress} staked in the contract accross all periods. Use to
     *         calculate lost LP tokens.
     */
    uint256 public currentStakedBalance;
    /// @notice amount of {tokenAddress} staked in the contract for the current period.
    uint256 public stakedBalanceCurrPeriod;
    /// @notice should be the amount of rewards available in the contract accross all periods.
    uint256 public rewardBalance;
    /// @notice should be the amount of rewards for current period.
    uint256 public totalReward;

    /**
     * @notice start date of current period.
     * @dev expressed in UNIX timestamp. Will be compareed to block.timestamp.
     */
    uint256 public startingDate;
    /**
     * @notice end date of current period.
     * @dev expressed in UNIX timestamp. Will be compareed to block.timestamp.
     */
    uint256 public endingDate;
    /**
     * @notice periodCounter is used to keep track of the farming periods, which allow participants to
     *         earn a certain amount of rewards by staking their LP for a certain period of time. Then,
     *         a new period can be opened with a different or equal amount to earn.
     * @dev counts the amount of farming periods.
     */
    uint256 public periodCounter;
    /**
     * @notice should be the amount of rewards per wei of deposited LP token {tokenAddress} for current
     *         period.
     */
    uint256 public accShare;
    /// @notice timestamp of at which shares have been updated at last, expressed in UNIX timestamp.
    uint256 public lastSharesUpdateTime;
    /**
     * @notice amount of participant in current period.
     * @dev {setNewPeriod} will reset this value to 0.
     */
    uint256 public totalParticipants;
    /// @dev expressed in hours, e.g. 7 days = 24 * 7 = 168.
    uint256 public lockDuration;
    /**
     * @notice whether prevent or not, wallets from staking, renewing staking, viewing old rewards,
     *         claiming rewards (old and current period) and withdrawing. Only admin functions are allowed.
     */
    bool public isPaused;

    /// @notice should be the last transfered token which is either {tokenAddress} or {rewardTokenAddress}.
    IERC20 internal _erc20Interface;

    /**
     * @notice struct which represent deposits made by a wallet based on a specific period. Each period has
     *         its own deposit data.
     *
     * @param amount amount of LP {tokenAddress} deposited accross all period.
     * @param latestStakeAt timestamp at which the latest stake has been made by the wallet for current
     *        period. Maturity date will be re-calculated from this timestamp which means each time the
     *        wallet stakes a new amount it has to wait for `lockDuration` before being able to withdraw.
     * @param latestClaimAt latest timestamp at which the wallet claimed their rewards.
     * @param userAccShare should be the amount of rewards per wei of deposited LP token {tokenAddress}
     *        accross all periods.
     * @param currentPeriod should be the lastest periodCounter at which the wallet participated.
     */
    struct Deposits {
        uint256 amount;
        uint256 latestStakeAt;
        uint256 latestClaimAt;
        uint256 userAccShare;
        uint256 currentPeriod;
    }

    /**
     * @notice struct which should represent the details of ended periods.
     * @dev period 0 should contain nullish values.
     *
     * @param periodCounter counter to track the period id.
     * @param accShare should be the amount of rewards per wei of deposited LP token {tokenAddress} for
                       this ended period.
     * @param rewPerSecond should be the amount of rewards per second for this ended period.
     * @param startingDate should be the start date of this ended period.
     * @param endingDate should be the end date of this ended period.
     * @param rewards should be the total amount of rewards left until this ended period, which might
     *        include previous rewards from previous closed periods.
     */
    struct PeriodDetails {
        uint256 periodCounter;
        uint256 accShare;
        uint256 rewPerSecond;
        uint256 startingDate;
        uint256 endingDate;
        uint256 rewards;
    }

    /// @notice should be the deposit data made by a wallet for accorss period if the wallet called {renew}.
    mapping(address => Deposits) private deposits;

    /// @notice whether a wallet has staked or not.
    mapping(address => bool) public isPaid;
    /// @notice whether a wallet has staked some LP {tokenAddress} or not.
    mapping(address => bool) public hasStaked;
    /// @notice should be the details of ended periods.
    mapping(uint256 => PeriodDetails) public endAccShare;

    event NewPeriodSet(
        uint256 periodCounter,
        uint256 startDate,
        uint256 endDate,
        uint256 lockDuration,
        uint256 rewardAmount
    );
    event Paused(
        uint256 indexed periodCounter,
        uint256 indexed totalParticipants,
        uint256 indexed currentStakedBalance,
        uint256 totalReward
    );
    event UnPaused(
        uint256 indexed periodCounter,
        uint256 indexed totalParticipants,
        uint256 indexed currentStakedBalance,
        uint256 totalReward
    );
    event PeriodExtended(
        uint256 periodCounter,
        uint256 endDate,
        uint256 rewards
    );
    event Staked(
        address indexed token,
        address indexed staker_,
        uint256 stakedAmount_
    );
    event PaidOut(
        address indexed token,
        address indexed rewardToken,
        address indexed staker_,
        uint256 amount_,
        uint256 reward_
    );

    /**
     * @notice by default the contract is paused, so the owner can set the first period without anyone
     *         staking before it opens.
     * @param _tokenAddress LP token address to deposit to earn rewards.
     * @param _rewardTokenAddress token address into which rewards will be paid in.
     */
    constructor(address _tokenAddress, address _rewardTokenAddress) Ownable() {
        require(_tokenAddress != address(0), "Zero token address");
        tokenAddress = _tokenAddress;
        require(
            _rewardTokenAddress != address(0),
            "Zero reward token address"
        );
        rewardTokenAddress = _rewardTokenAddress;
        isPaused = true;
    }

    /**
     * @notice Config new period details according to {setNewPeriod} parameters.
     *
     * @param _start Seconds at which the period starts - in UNIX timestamp.
     * @param _end Seconds at which the period ends - in UNIX timestamp.
     * @param _lockDuration Duration in hours to wait before being able to withdraw staked LP.
     */
    function __configNewPeriod(
        uint256 _start,
        uint256 _end,
        uint256 _lockDuration
    ) private {
        require(totalReward > 0, "Add rewards for this periodCounter");
        startingDate = _start;
        endingDate = _end;
        lockDuration = _lockDuration;
        periodCounter++;
        lastSharesUpdateTime = _start;
    }

    /// @notice Add rewards to the contract and transfer them in it.
    function __addReward(
        uint256 _rewardAmount
    )
        private
        hasAllowance(msg.sender, _rewardAmount, rewardTokenAddress)
        returns (bool)
    {
        totalReward = totalReward.add(_rewardAmount);
        rewardBalance = rewardBalance.add(_rewardAmount);
        if (!__payMe(msg.sender, _rewardAmount, rewardTokenAddress)) {
            return false;
        }
        return true;
    }

    /// save the details of the last ended period.
    function __saveOldPeriod() private {
        // only save old period if it has ended & not been saved before
        if (
            block.timestamp > endingDate &&
            endAccShare[periodCounter].startingDate == 0
        ) {
            endAccShare[periodCounter] = PeriodDetails(
                periodCounter,
                accShare,
                rewPerSecond(),
                startingDate,
                endingDate,
                rewardBalance
            );
        }
    }

    /// reset contracts's deposit data at the end of period and pause it.
    function __reset() private {
        totalReward = 0;
        stakedBalanceCurrPeriod = 0;
        totalParticipants = 0;
    }

    /**
     * @notice set the start and end timestamp for the new period and add rewards to be
     *         earned within this period. Previous period must have ended, otherwise use
     *         {extendCurrentPeriod} to update current period.
     *         also calls {__addReward} to add rewards to this contract so be sure to approve this contract
     *         to spend your ERC20 before calling this function.
     *
     * @param _rewardAmount Amount of rewards to be earned within this period.
     * @param _start Seconds at which the period starts - in UNIX timestamp.
     * @param _end Seconds at which the period ends - in UNIX timestamp.
     * @param _lockDuration Duration in hours to wait before being able to withdraw staked LP.
     */
    function setNewPeriod(
        uint256 _rewardAmount,
        uint256 _start,
        uint256 _end,
        uint256 _lockDuration
    ) external onlyOwner returns (bool) {
        require(
            _start > block.timestamp,
            "Start should be more than block.timestamp"
        );
        require(_end > _start, "End block should be greater than start");
        require(_rewardAmount > 0, "Reward must be positive");
        require(block.timestamp > endingDate, "Wait till end of this period");

        __updateShare();
        __saveOldPeriod();

        __reset();
        bool rewardAdded = __addReward(_rewardAmount);

        require(rewardAdded, "Rewards error");

        __configNewPeriod(_start, _end, _lockDuration);

        emit NewPeriodSet(
            periodCounter,
            _start,
            _end,
            _lockDuration,
            _rewardAmount
        );

        isPaused = false;

        return true;
    }

    function pause() external onlyOwner {
        isPaused = true;

        emit Paused(
            periodCounter,
            totalParticipants,
            currentStakedBalance,
            totalReward
        );
    }

    function unPause() external onlyOwner {
        isPaused = false;

        emit UnPaused(
            periodCounter,
            totalParticipants,
            currentStakedBalance,
            totalReward
        );
    }

    /// @notice update {accShare} and {lastSharesUpdateTime} for current period.
    function __updateShare() private {
        if (block.timestamp <= lastSharesUpdateTime) {
            return;
        }
        if (stakedBalanceCurrPeriod == 0) {
            lastSharesUpdateTime = block.timestamp;
            return;
        }

        uint256 secSinceLastPeriod;

        if (block.timestamp >= endingDate) {
            secSinceLastPeriod = endingDate.sub(lastSharesUpdateTime);
        } else {
            secSinceLastPeriod = block.timestamp.sub(lastSharesUpdateTime);
        }

        uint256 rewards = secSinceLastPeriod.mul(rewPerSecond());

        accShare = accShare.add(
            (rewards.mul(1e6).div(stakedBalanceCurrPeriod))
        );
        if (block.timestamp >= endingDate) {
            lastSharesUpdateTime = endingDate;
        } else {
            lastSharesUpdateTime = block.timestamp;
        }
    }

    /// @notice calculate rewards to get per second for current period.
    function rewPerSecond() public view returns (uint256) {
        if (totalReward == 0 || rewardBalance == 0) return 0;
        uint256 rewardPerSecond = totalReward.div(
            (endingDate.sub(startingDate))
        );
        return (rewardPerSecond);
    }

    function stake(
        uint256 amount
    ) external hasAllowance(msg.sender, amount, tokenAddress) returns (bool) {
        require(!isPaused, "Contract is paused");
        require(
            block.timestamp >= startingDate && block.timestamp < endingDate,
            "No active pool (time)"
        );
        require(amount > 0, "Can't stake 0 amount");
        return (__stake(msg.sender, amount));
    }

    function __stake(address from, uint256 amount) private returns (bool) {
        __updateShare();
        // if never staked, create new deposit
        if (!hasStaked[from]) {
            deposits[from] = Deposits({
                amount: amount,
                latestStakeAt: block.timestamp,
                latestClaimAt: block.timestamp,
                userAccShare: accShare,
                currentPeriod: periodCounter
            });
            totalParticipants = totalParticipants.add(1);
            hasStaked[from] = true;
        }
        // otherwise update deposit details and claim pending rewards
        else {
            // if user has staked in previous period, renew and claim rewards from previous period
            if (deposits[from].currentPeriod != periodCounter) {
                bool renew_ = __renew(from);
                require(renew_, "Error renewing");
            }
            // otherwise on each new stake claim pending rewards of current period
            else {
                bool claim = __claimRewards(from);
                require(claim, "Error paying rewards");
            }

            uint256 userAmount = deposits[from].amount;

            deposits[from] = Deposits({
                amount: userAmount.add(amount),
                latestStakeAt: block.timestamp,
                latestClaimAt: block.timestamp,
                userAccShare: accShare,
                currentPeriod: periodCounter
            });
        }
        stakedBalanceCurrPeriod = stakedBalanceCurrPeriod.add(amount);
        totalStaked = totalStaked.add(amount);
        currentStakedBalance += amount;
        if (!__payMe(from, amount, tokenAddress)) {
            return false;
        }
        emit Staked(tokenAddress, from, amount);
        return true;
    }

    /// @notice get user deposit details
    function userDeposits(
        address from
    ) external view returns (Deposits memory deposit) {
        return deposits[from];
    }

    /// @custom:audit seems like a duplicate of {hasStaked}.
    function fetchUserShare(address from) public view returns (uint256) {
        require(hasStaked[from], "No stakes found for user");
        if (stakedBalanceCurrPeriod == 0) {
            return 0;
        }
        require(
            deposits[from].currentPeriod == periodCounter,
            "Please renew in the active valid periodCounter"
        );
        uint256 userAmount = deposits[from].amount;
        require(userAmount > 0, "No stakes available for user"); //extra check
        return 1;
    }

    /// @dev claim pending rewards of current period.
    function claimRewards() public returns (bool) {
        require(!isPaused, "Contract paused");
        require(fetchUserShare(msg.sender) > 0, "No stakes found for user");
        return (__claimRewards(msg.sender));
    }

    function __claimRewards(address from) private returns (bool) {
        uint256 userAccShare = deposits[from].userAccShare;
        __updateShare();
        uint256 amount = deposits[from].amount;
        uint256 rewDebt = amount.mul(userAccShare).div(1e6);
        uint256 rew = (amount.mul(accShare).div(1e6)).sub(rewDebt);
        require(rew > 0, "No rewards generated");
        require(rew <= rewardBalance, "Not enough rewards in the contract");
        deposits[from].userAccShare = accShare;
        deposits[from].latestClaimAt = block.timestamp;
        rewardBalance = rewardBalance.sub(rew);
        bool payRewards = __payDirect(from, rew, rewardTokenAddress);
        require(payRewards, "Rewards transfer failed");
        emit PaidOut(tokenAddress, rewardTokenAddress, from, amount, rew);
        return true;
    }

    /**
     * @notice Should take into account farming rewards and LP staked from previous periods into the new
     *         current period.
     */
    function renew() public returns (bool) {
        require(!isPaused, "Contract paused");
        require(hasStaked[msg.sender], "No stakings found, please stake");
        require(
            deposits[msg.sender].currentPeriod != periodCounter,
            "Already renewed"
        );
        require(
            block.timestamp > startingDate && block.timestamp < endingDate,
            "Wrong time"
        );
        return (__renew(msg.sender));
    }

    function __renew(address from) private returns (bool) {
        __updateShare();
        if (_viewOldRewards(from) > 0) {
            bool claimed = claimOldRewards();
            require(claimed, "Error paying old rewards");
        }
        deposits[from].currentPeriod = periodCounter;
        deposits[from].latestStakeAt = block.timestamp;
        deposits[from].latestClaimAt = block.timestamp;
        deposits[from].userAccShare = accShare;
        stakedBalanceCurrPeriod = stakedBalanceCurrPeriod.add(
            deposits[from].amount
        );
        totalParticipants = totalParticipants.add(1);
        return true;
    }

    /// @notice get rewards from previous periods for `from` wallet.
    function viewOldRewards(address from) public view returns (uint256) {
        require(!isPaused, "Contract paused");
        require(hasStaked[from], "No stakings found, please stake");

        return _viewOldRewards(from);
    }

    function _viewOldRewards(address from) internal view returns (uint256) {
        if (deposits[from].currentPeriod == periodCounter) {
            return 0;
        }

        uint256 userPeriod = deposits[from].currentPeriod;

        uint256 accShare1 = endAccShare[userPeriod].accShare;
        uint256 userAccShare = deposits[from].userAccShare;

        if (deposits[from].latestClaimAt >= endAccShare[userPeriod].endingDate)
            return 0;
        uint256 amount = deposits[from].amount;
        uint256 rewDebt = amount.mul(userAccShare).div(1e6);
        uint256 rew = (amount.mul(accShare1).div(1e6)).sub(rewDebt);

        require(rew <= rewardBalance, "Not enough rewards");

        return (rew);
    }

    /// @notice save old period details and claim pending rewards from previous periods.
    function claimOldRewards() public returns (bool) {
        require(!isPaused, "Contract paused");
        require(hasStaked[msg.sender], "No stakings found, please stake");
        require(
            deposits[msg.sender].currentPeriod != periodCounter,
            "Already renewed"
        );

        __saveOldPeriod();

        uint256 userPeriod = deposits[msg.sender].currentPeriod;

        uint256 accShare1 = endAccShare[userPeriod].accShare;
        uint256 userAccShare = deposits[msg.sender].userAccShare;

        require(
            deposits[msg.sender].latestClaimAt <
                endAccShare[userPeriod].endingDate,
            "Already claimed old rewards"
        );
        uint256 amount = deposits[msg.sender].amount;
        uint256 rewDebt = amount.mul(userAccShare).div(1e6);
        uint256 rew = (amount.mul(accShare1).div(1e6)).sub(rewDebt);

        require(rew <= rewardBalance, "Not enough rewards");
        deposits[msg.sender].latestClaimAt = endAccShare[userPeriod]
            .endingDate;
        rewardBalance = rewardBalance.sub(rew);
        bool paidOldRewards = __payDirect(msg.sender, rew, rewardTokenAddress);
        require(paidOldRewards, "Error paying");
        emit PaidOut(
            tokenAddress,
            rewardTokenAddress,
            msg.sender,
            amount,
            rew
        );
        return true;
    }

    /// @notice should calculate current pending rewards for `from` wallet for current period.
    function calculate(address from) public view returns (uint256) {
        if (fetchUserShare(from) == 0) return 0;
        return (__calculate(from));
    }

    function __calculate(address from) private view returns (uint256) {
        uint256 userAccShare = deposits[from].userAccShare;
        uint256 currentAccShare = accShare;
        //Simulating __updateShare() to calculate rewards
        if (block.timestamp <= lastSharesUpdateTime) {
            return 0;
        }
        if (stakedBalanceCurrPeriod == 0) {
            return 0;
        }

        uint256 secSinceLastPeriod;

        if (block.timestamp >= endingDate) {
            secSinceLastPeriod = endingDate.sub(lastSharesUpdateTime);
        } else {
            secSinceLastPeriod = block.timestamp.sub(lastSharesUpdateTime);
        }

        uint256 rewards = secSinceLastPeriod.mul(rewPerSecond());

        uint256 newAccShare = currentAccShare.add(
            (rewards.mul(1e6).div(stakedBalanceCurrPeriod))
        );
        uint256 amount = deposits[from].amount;
        uint256 rewDebt = amount.mul(userAccShare).div(1e6);
        uint256 rew = (amount.mul(newAccShare).div(1e6)).sub(rewDebt);
        return (rew);
    }

    function emergencyWithdraw() external returns (bool) {
        require(
            block.timestamp >
                deposits[msg.sender].latestStakeAt.add(
                    lockDuration.mul(SECONDS_PER_HOUR)
                ),
            "Can't withdraw before lock duration"
        );
        require(hasStaked[msg.sender], "No stakes available for user");
        require(!isPaid[msg.sender], "Already Paid");
        return (__withdraw(msg.sender, deposits[msg.sender].amount));
    }

    function __withdraw(address from, uint256 amount) private returns (bool) {
        __updateShare();
        deposits[from].amount = deposits[from].amount.sub(amount);
        if (deposits[from].currentPeriod == periodCounter) {
            stakedBalanceCurrPeriod -= amount;
        }
        bool paid = __payDirect(from, amount, tokenAddress);
        require(paid, "Error during withdraw");
        if (deposits[from].amount == 0) {
            isPaid[from] = true;
            hasStaked[from] = false;
            if (deposits[from].currentPeriod == periodCounter) {
                totalParticipants = totalParticipants.sub(1);
            }
            delete deposits[from];
        }

        currentStakedBalance -= amount;

        return true;
    }

    /// Withdraw `amount` deposited LP token after lock duration.
    function withdraw(uint256 amount) external returns (bool) {
        require(!isPaused, "Contract paused");
        require(
            block.timestamp >
                deposits[msg.sender].latestStakeAt.add(
                    lockDuration.mul(SECONDS_PER_HOUR)
                ),
            "Can't withdraw before lock duration"
        );
        require(amount <= deposits[msg.sender].amount, "Wrong value");
        if (deposits[msg.sender].currentPeriod == periodCounter) {
            if (calculate(msg.sender) > 0) {
                bool rewardsPaid = claimRewards();
                require(rewardsPaid, "Error paying rewards");
            }
        }

        if (_viewOldRewards(msg.sender) > 0) {
            bool oldRewardsPaid = claimOldRewards();
            require(oldRewardsPaid, "Error paying old rewards");
        }
        return (__withdraw(msg.sender, amount));
    }

    /**
     * @notice add rewards to current period and extend its runing time.
     * @dev running should be updated based on the amount of rewards added and current rewards per second,
     *      e.g.: 1000 rewards per second, then if we add 1000 rewards then we increase running time by
     *      1 second.
     */
    function extendCurrentPeriod(
        uint256 rewardsToBeAdded
    ) external onlyOwner returns (bool) {
        require(
            block.timestamp > startingDate && block.timestamp < endingDate,
            "No active pool (time)"
        );
        require(rewardsToBeAdded > 0, "Zero rewards");
        bool addedRewards = __payMe(
            msg.sender,
            rewardsToBeAdded,
            rewardTokenAddress
        );
        require(addedRewards, "Error adding rewards");
        endingDate = endingDate.add(rewardsToBeAdded.div(rewPerSecond()));
        totalReward = totalReward.add(rewardsToBeAdded);
        rewardBalance = rewardBalance.add(rewardsToBeAdded);
        emit PeriodExtended(periodCounter, endingDate, rewardsToBeAdded);
        return true;
    }

    /// @notice deposit rewards to this farming contract.
    function __payMe(
        address payer,
        uint256 amount,
        address token
    ) private returns (bool) {
        return __payTo(payer, address(this), amount, token);
    }

    /// @notice should transfer rewards to farming contract.
    function __payTo(
        address allower,
        address receiver,
        uint256 amount,
        address token
    ) private returns (bool) {
        // Request to transfer amount from the contract to receiver.
        // contract does not own the funds, so the allower must have added allowance to the contract
        // Allower is the original owner.
        _erc20Interface = IERC20(token);
        _erc20Interface.safeTransferFrom(allower, receiver, amount);
        return true;
    }

    /// @notice should pay rewards to `to` wallet and in certain case withdraw deposited LP token.
    function __payDirect(
        address to,
        uint256 amount,
        address token
    ) private returns (bool) {
        require(
            token == tokenAddress || token == rewardTokenAddress,
            "Invalid token address"
        );
        _erc20Interface = IERC20(token);
        _erc20Interface.safeTransfer(to, amount);
        return true;
    }

    /// @notice check whether `allower` has approved this contract to spend at least `amount` of `token`.
    modifier hasAllowance(
        address allower,
        uint256 amount,
        address token
    ) {
        // Make sure the allower has provided the right allowance.
        require(
            token == tokenAddress || token == rewardTokenAddress,
            "Invalid token address"
        );
        _erc20Interface = IERC20(token);
        uint256 ourAllowance = _erc20Interface.allowance(
            allower,
            address(this)
        );
        require(amount <= ourAllowance, "Make sure to add enough allowance");
        _;
    }

    function recoverLostERC20(address token, address to) external onlyOwner {
        if (token == address(0)) revert("Token_Zero_Address");
        if (to == address(0)) revert("To_Zero_Address");

        uint256 amount = IERC20(token).balanceOf(address(this));

        // only retrieve lost {rewardTokenAddress}
        if (token == rewardTokenAddress) amount -= rewardBalance;
        // only retrieve lost LP tokens
        if (token == tokenAddress) amount -= currentStakedBalance;

        IERC20(token).safeTransfer(to, amount);
    }
}
