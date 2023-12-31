// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity 0.8.9;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity 0.8.9;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeERC20 {
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(token.approve(spender, value));
    }
}

pragma solidity 0.8.9;

contract SMD_v5 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant SECONDS_PER_HOUR = 3600; // 60 * 60

    /// @notice LP token address to deposit to earn rewards.
    address public tokenAddress;
    /// @notice token address to in which rewards will be paid in.
    address public rewardTokenAddress;
    uint256 public stakedTotal;
    uint256 public stakedBalance;
    uint256 public rewardBalance;
    uint256 public totalReward;

    /// @dev expressed in UNIX timestamp. Will be compareed to block.timestamp.
    uint256 public startingDate;
    /// @dev expressed in UNIX timestamp. Will be compareed to block.timestamp.
    uint256 public endingDate;
    /**
      * @notice periodCounter is used to keep track of the farming periods, which allow participants to
      *         earn a certain amount of rewards by staking their LP for a certain period of time. Then, 
      *         a new period can be opened with a different or equal amount to earn.
      * @dev counts the amount of farming periods.
      */
    uint256 public periodCounter;
    /// @notice should be the last amount of rewards per wei of deposited LP token {tokenAddress}.
    uint256 public accShare;
    /// @notice timestamp of the last period start date, expressed in UNIX timestamp.
    uint256 public lastPeriodStartedAt;
    /**
    * @notice amount of participant in current period.
    * @dev {resetAndsetStartEndBlock} will reset this value to 0.
    */
    uint256 public totalParticipants;
    /// @dev expressed in hours, e.g. 7 days = 24 * 7 = 168.
    uint256 public lockDuration;
    bool public isPaused;

    IERC20 public ERC20Interface;

    struct Deposits {
        uint256 amount;
        uint256 initialStake;
        uint256 latestClaim;
        uint256 userAccShare;
        uint256 currentPeriod;
    }

    struct PeriodDetails {
        uint256 periodCounter;
        uint256 accShare;
        uint256 rewPerSecond;
        uint256 startingDate;
        uint256 endingDate;
        uint256 rewards;
    }

    mapping(address => Deposits) private deposits;

    mapping(address => bool) public isPaid;
    mapping(address => bool) public hasStaked;
    mapping(uint256 => PeriodDetails) public endAccShare;

    event NewPeriodSet(
        uint256 periodCounter,
        uint256 startDate,
        uint256 endDate,
        uint256 lockDuration,
        uint256 rewardAmount
    );
    event PeriodExtended(uint256 periodCounter, uint256 endDate, uint256 rewards);
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

    constructor(address _tokenAddress, address _rewardTokenAddress) Ownable() {
        require(_tokenAddress != address(0), "Zero token address");
        tokenAddress = _tokenAddress;
        require(_rewardTokenAddress != address(0), "Zero reward token address");
        rewardTokenAddress = _rewardTokenAddress;
        isPaused = true;
    }

    /*
        -   To set the start and end blocks for each periodCounter
    */

    function setStartEnd(uint256 _start, uint256 _end) private {
        require(totalReward > 0, "Add rewards for this periodCounter");
        startingDate = _start;
        endingDate = _end;
        periodCounter++;
        isPaused = false;
        lastPeriodStartedAt = _start;
    }

    /**
     * @notice Add rewards to the contract, without transfering them to the contract. They stay in 
     *         `msg.sender` wallet, so be sure `msg.sender` has approved the this contract to transfer
     *         the `_rewardAmount` of `rewardTokenAddress`.
     */
    function addReward(uint256 _rewardAmount)
        private
        _hasAllowance(msg.sender, _rewardAmount, rewardTokenAddress)
        returns (bool)
    {
        totalReward = totalReward.add(_rewardAmount);
        rewardBalance = rewardBalance.add(_rewardAmount);
        if (!_payMe(msg.sender, _rewardAmount, rewardTokenAddress)) {
            return false;
        }
        return true;
    }

    /*
        -   To reset the contract at the end of each periodCounter.
    */

    function reset() private {
        require(block.timestamp > endingDate, "Wait till end of this period");
        updateShare();
        endAccShare[periodCounter] = PeriodDetails(
            periodCounter,
            accShare,
            rewPerSecond(),
            startingDate,
            endingDate,
            rewardBalance
        );
        totalReward = 0;
        stakedBalance = 0;
        isPaused = true;
    }

    /**
     * @notice Function to set the start and end blocks for each new period and add rewards to be 
     *         earned within this period. Previous period must have ended, otherwise use 
     *         {extendCurrentPeriod} to update current period.
     * @dev Easier to pass seconds to wait until start and end of period, instead of passing the start and
     *      end timestamp. 
     *
     * @param _rewardAmount Amount of rewards to be earned within this period.
     * @param _start Seconds at which the period starts - in UNIX timestamp.
     * @param _end Seconds at which the period ends - in UNIX timestamp.
     * @param _lockDuration Duration in hours to wait before being able to withdraw.
     */
    function resetAndsetStartEndBlock(
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
        reset();
        bool rewardAdded = addReward(_rewardAmount);
        require(rewardAdded, "Rewards error");
        setStartEnd(_start, _end);
        lockDuration = _lockDuration;
        totalParticipants = 0;
        emit NewPeriodSet(periodCounter, _start, _end, _lockDuration, _rewardAmount);
        return true;
    }

    /*
        -   Function to update rewards and state parameters
    */

    function updateShare() private {
        if (block.timestamp <= lastPeriodStartedAt) {
            return;
        }
        if (stakedBalance == 0) {
            lastPeriodStartedAt = block.timestamp;
            return;
        }

        uint256 secSinceLastPeriod;

        if (block.timestamp >= endingDate) {
            secSinceLastPeriod = endingDate.sub(lastPeriodStartedAt);
        } else {
            secSinceLastPeriod = block.timestamp.sub(lastPeriodStartedAt);
        }

        uint256 rewards = secSinceLastPeriod.mul(rewPerSecond());

        accShare = accShare.add((rewards.mul(1e6).div(stakedBalance)));
        if (block.timestamp >= endingDate) {
            lastPeriodStartedAt = endingDate;
        } else {
            lastPeriodStartedAt = block.timestamp;
        }
    }

    function rewPerSecond() public view returns (uint256) {
        if (totalReward == 0 || rewardBalance == 0) return 0;
        uint256 rewardPerSecond = totalReward.div(
            (endingDate.sub(startingDate))
        );
        return (rewardPerSecond);
    }

    function stake(uint256 amount)
        external
        _hasAllowance(msg.sender, amount, tokenAddress)
        returns (bool)
    {
        require(!isPaused, "Contract is paused");
        require(
            block.timestamp >= startingDate && block.timestamp < endingDate,
            "No active pool (time)"
        );
        require(amount > 0, "Can't stake 0 amount");
        return (_stake(msg.sender, amount));
    }

    function _stake(address from, uint256 amount) private returns (bool) {
        updateShare();

        if (!hasStaked[from]) {
            deposits[from] = Deposits(
                amount,
                block.timestamp,
                block.timestamp,
                accShare,
                periodCounter
            );
            totalParticipants = totalParticipants.add(1);
            hasStaked[from] = true;
        } else {
            if (deposits[from].currentPeriod != periodCounter) {
                bool renew_ = _renew(from);
                require(renew_, "Error renewing");
            } else {
                bool claim = _claimRewards(from);
                require(claim, "Error paying rewards");
            }

            uint256 userAmount = deposits[from].amount;

            deposits[from] = Deposits(
                userAmount.add(amount),
                block.timestamp,
                block.timestamp,
                accShare,
                periodCounter
            );
        }
        stakedBalance = stakedBalance.add(amount);
        stakedTotal = stakedTotal.add(amount);
        if (!_payMe(from, amount, tokenAddress)) {
            return false;
        }
        emit Staked(tokenAddress, from, amount);
        return true;
    }

    function userDeposits(address from)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        if (hasStaked[from]) {
            return (
                deposits[from].amount,
                deposits[from].initialStake,
                deposits[from].latestClaim,
                deposits[from].currentPeriod
            );
        } else {
            return (0, 0, 0, 0);
        }
    }

    function fetchUserShare(address from) public view returns (uint256) {
        require(hasStaked[from], "No stakes found for user");
        if (stakedBalance == 0) {
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

    function claimRewards() public returns (bool) {
        require(fetchUserShare(msg.sender) > 0, "No stakes found for user");
        return (_claimRewards(msg.sender));
    }

    function _claimRewards(address from) private returns (bool) {
        uint256 userAccShare = deposits[from].userAccShare;
        updateShare();
        uint256 amount = deposits[from].amount;
        uint256 rewDebt = amount.mul(userAccShare).div(1e6);
        uint256 rew = (amount.mul(accShare).div(1e6)).sub(rewDebt);
        require(rew > 0, "No rewards generated");
        require(rew <= rewardBalance, "Not enough rewards in the contract");
        deposits[from].userAccShare = accShare;
        deposits[from].latestClaim = block.timestamp;
        rewardBalance = rewardBalance.sub(rew);
        bool payRewards = _payDirect(from, rew, rewardTokenAddress);
        require(payRewards, "Rewards transfer failed");
        emit PaidOut(tokenAddress, rewardTokenAddress, from, amount, rew);
        return true;
    }

    /// @notice Should take into account staking rewards from previous periods into the current new period.
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
        return (_renew(msg.sender));
    }

    function _renew(address from) private returns (bool) {
        updateShare();
        if (viewOldRewards(from) > 0) {
            bool claimed = claimOldRewards();
            require(claimed, "Error paying old rewards");
        }
        deposits[from].currentPeriod = periodCounter;
        deposits[from].initialStake = block.timestamp;
        deposits[from].latestClaim = block.timestamp;
        deposits[from].userAccShare = accShare;
        stakedBalance = stakedBalance.add(deposits[from].amount);
        totalParticipants = totalParticipants.add(1);
        return true;
    }

    function viewOldRewards(address from) public view returns (uint256) {
        require(!isPaused, "Contract paused");
        require(hasStaked[from], "No stakings found, please stake");

        if (deposits[from].currentPeriod == periodCounter) {
            return 0;
        }

        uint256 userPeriod = deposits[from].currentPeriod;

        uint256 accShare1 = endAccShare[userPeriod].accShare;
        uint256 userAccShare = deposits[from].userAccShare;

        if (deposits[from].latestClaim >= endAccShare[userPeriod].endingDate)
            return 0;
        uint256 amount = deposits[from].amount;
        uint256 rewDebt = amount.mul(userAccShare).div(1e6);
        uint256 rew = (amount.mul(accShare1).div(1e6)).sub(rewDebt);

        require(rew <= rewardBalance, "Not enough rewards");

        return (rew);
    }

    /// @notice Should claim rewards from previous periods.
    function claimOldRewards() public returns (bool) {
        require(!isPaused, "Contract paused");
        require(hasStaked[msg.sender], "No stakings found, please stake");
        require(
            deposits[msg.sender].currentPeriod != periodCounter,
            "Already renewed"
        );

        uint256 userPeriod = deposits[msg.sender].currentPeriod;

        uint256 accShare1 = endAccShare[userPeriod].accShare;
        uint256 userAccShare = deposits[msg.sender].userAccShare;

        require(
            deposits[msg.sender].latestClaim <
                endAccShare[userPeriod].endingDate,
            "Already claimed old rewards"
        );
        uint256 amount = deposits[msg.sender].amount;
        uint256 rewDebt = amount.mul(userAccShare).div(1e6);
        uint256 rew = (amount.mul(accShare1).div(1e6)).sub(rewDebt);

        require(rew <= rewardBalance, "Not enough rewards");
        deposits[msg.sender].latestClaim = endAccShare[userPeriod].endingDate;
        rewardBalance = rewardBalance.sub(rew);
        bool paidOldRewards = _payDirect(msg.sender, rew, rewardTokenAddress);
        require(paidOldRewards, "Error paying");
        emit PaidOut(tokenAddress, rewardTokenAddress, msg.sender, amount, rew);
        return true;
    }

    function calculate(address from) public view returns (uint256) {
        if (fetchUserShare(from) == 0) return 0;
        return (_calculate(from));
    }

    function _calculate(address from) private view returns (uint256) {
        uint256 userAccShare = deposits[from].userAccShare;
        uint256 currentAccShare = accShare;
        //Simulating updateShare() to calculate rewards
        if (block.timestamp <= lastPeriodStartedAt) {
            return 0;
        }
        if (stakedBalance == 0) {
            return 0;
        }

        uint256 secSinceLastPeriod;

        if (block.timestamp >= endingDate) {
            secSinceLastPeriod = endingDate.sub(lastPeriodStartedAt);
        } else {
            secSinceLastPeriod = block.timestamp.sub(lastPeriodStartedAt);
        }

        uint256 rewards = secSinceLastPeriod.mul(rewPerSecond());

        uint256 newAccShare = currentAccShare.add(
            (rewards.mul(1e6).div(stakedBalance))
        );
        uint256 amount = deposits[from].amount;
        uint256 rewDebt = amount.mul(userAccShare).div(1e6);
        uint256 rew = (amount.mul(newAccShare).div(1e6)).sub(rewDebt);
        return (rew);
    }

    function emergencyWithdraw() external returns (bool) {
        require(
            block.timestamp >
                deposits[msg.sender].initialStake.add(
                    lockDuration.mul(SECONDS_PER_HOUR)
                ),
            "Can't withdraw before lock duration"
        );
        require(hasStaked[msg.sender], "No stakes available for user");
        require(!isPaid[msg.sender], "Already Paid");
        return (_withdraw(msg.sender, deposits[msg.sender].amount));
    }

    function _withdraw(address from, uint256 amount) private returns (bool) {
        updateShare();
        deposits[from].amount = deposits[from].amount.sub(amount);
        if (!isPaused && deposits[from].currentPeriod == periodCounter) {
            stakedBalance = stakedBalance.sub(amount);
        }
        bool paid = _payDirect(from, amount, tokenAddress);
        require(paid, "Error during withdraw");
        if (deposits[from].amount == 0) {
            isPaid[from] = true;
            hasStaked[from] = false;
            if (deposits[from].currentPeriod == periodCounter) {
                totalParticipants = totalParticipants.sub(1);
            }
            delete deposits[from];
        }
        return true;
    }

    function withdraw(uint256 amount) external returns (bool) {
        require(
            block.timestamp >
                deposits[msg.sender].initialStake.add(
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

        if (viewOldRewards(msg.sender) > 0) {
            bool oldRewardsPaid = claimOldRewards();
            require(oldRewardsPaid, "Error paying old rewards");
        }
        return (_withdraw(msg.sender, amount));
    }

    function extendCurrentPeriod(uint256 rewardsToBeAdded)
        external
        onlyOwner
        returns (bool)
    {
        require(
            block.timestamp > startingDate && block.timestamp < endingDate,
            "No active pool (time)"
        );
        require(rewardsToBeAdded > 0, "Zero rewards");
        bool addedRewards = _payMe(
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

    function _payMe(
        address payer,
        uint256 amount,
        address token
    ) private returns (bool) {
        return _payTo(payer, address(this), amount, token);
    }

    function _payTo(
        address allower,
        address receiver,
        uint256 amount,
        address token
    ) private returns (bool) {
        // Request to transfer amount from the contract to receiver.
        // contract does not own the funds, so the allower must have added allowance to the contract
        // Allower is the original owner.
        ERC20Interface = IERC20(token);
        ERC20Interface.safeTransferFrom(allower, receiver, amount);
        return true;
    }

    function _payDirect(
        address to,
        uint256 amount,
        address token
    ) private returns (bool) {
        require(
            token == tokenAddress || token == rewardTokenAddress,
            "Invalid token address"
        );
        ERC20Interface = IERC20(token);
        ERC20Interface.safeTransfer(to, amount);
        return true;
    }

    modifier _hasAllowance(
        address allower,
        uint256 amount,
        address token
    ) {
        // Make sure the allower has provided the right allowance.
        require(
            token == tokenAddress || token == rewardTokenAddress,
            "Invalid token address"
        );
        ERC20Interface = IERC20(token);
        uint256 ourAllowance = ERC20Interface.allowance(allower, address(this));
        require(amount <= ourAllowance, "Make sure to add enough allowance");
        _;
    }
}
