/**
    Saltz
    Explore the world’s first yield generating deflationary coin with guaranteed Minimum selling price.
    
    Website: saltz.io
    Twitter: twitter.com/Saltz_io
    Telegram: t.me/saltzofficial
    
**/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;
//import "./ReentrancyGuard.sol";

import "./console.sol";
import "./ISaltsToken.sol";
import "./Ownable.sol";


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
}

interface IVault {
    function setUpdater(address _updater) external;

    function withdraw(uint amount, address _user) external;
}

contract SaltzYard is Ownable{
    using SafeMath for uint256;

    //    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */
    struct LockedStake {
    uint256 amount;
    uint256 lockedTimeStamp;
    uint256 unlockTime;
}

mapping(address => LockedStake) public lockedStakes;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 5 days;
    uint256 public initialBoost = 15;
    uint256 public boost = 38;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => bool) public locking;
    mapping(address => bool) public flexible;

    uint256 private _totalSupply;

    ISaltsToken public immutable rewardsToken;
    IVault Ivault;

    //address public owner;

    address vault;

    address onlyWallet;

    // Duration of rewards to be paid out (in seconds)
    uint public duration;
    // Timestamp of when the rewards finish
    uint public finishAt;
    // Minimum of last updated time and reward finish time
    uint public updatedAt;

    mapping(address => uint) public sevenDayTax;

    // Total staked
    uint256 public totalSupply;
    uint256 public totalSupplyLocked;
    uint256 public totalSupplyWithoutLocked;
    mapping(address => uint) private _balances;


    constructor(address _rewardToken) {
       // owner = msg.sender;
        rewardsToken = ISaltsToken(_rewardToken);
    }

    // modifier onlyOwner() {
    //     require(msg.sender == owner, "not authorized");
    //     _;
    // }

     modifier ownerOrWallet(){
         require(msg.sender == owner() || msg.sender == onlyWallet, "not authorized");
    _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

     function setOnlyWallet(address _address) public onlyOwner {
        onlyWallet = _address;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupplyWithLocked())
            );
    }

    function earned(address account) public view returns (uint256) {
        if(lockedStakes[msg.sender].unlockTime > 0){
            return
            lockedStakes[msg.sender].amount
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
        }
        return
            _balances[account] 
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function stake(uint _amount) external  updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        require(!locking[msg.sender],"You are lock-in mode");
        rewardsToken.transferFrom(msg.sender, address(this), _amount);
        _balances[msg.sender] += _amount;
        totalSupply += _amount;
        totalSupplyWithoutLocked+=_amount;
        sevenDayTax[msg.sender] = block.timestamp;
        flexible[msg.sender] = true;
        emit Staked(msg.sender,_amount);
    }

    function stakeWithLock(uint _amount, uint256 lockinPeriodInSeconds) external updateReward(msg.sender) {  
    require(_amount > 0, "Cannot stake 0 tokens");    
    require(!flexible[msg.sender], "You are in flexible mode");

    // // Convert lock-in period from seconds to weeks
    // uint256 lockinPeriodInWeeks = lockinPeriodInSeconds / (7 days);

    // Transfer tokens and update balances
    rewardsToken.transferFrom(msg.sender, address(this), _amount);
    _balances[msg.sender] += _amount;
    totalSupply += _amount;

    bool isFirstStake = !locking[msg.sender];
    if (isFirstStake) {
        require(lockinPeriodInSeconds>= 2 weeks,"No lock-in period entered!");
        // First time staking in lock-in mode
        lockedStakes[msg.sender].lockedTimeStamp = block.timestamp;
        lockedStakes[msg.sender].unlockTime = lockinPeriodInSeconds;
        locking[msg.sender] = true;
    } else {
        // Ensure lock-in period has not ended for subsequent stakes
        require(block.timestamp < lockedStakes[msg.sender].lockedTimeStamp + lockedStakes[msg.sender].unlockTime, "Lock-in period already ended");
    }

    // Calculate remaining time in lock-in period in weeks
    uint256 timeElapsed = block.timestamp - lockedStakes[msg.sender].lockedTimeStamp;
    uint256 remainingTimeInSeconds = lockedStakes[msg.sender].unlockTime > timeElapsed ? lockedStakes[msg.sender].unlockTime - timeElapsed : 0;
    
    // Prevent restaking if remaining time is less than a week
    require(remainingTimeInSeconds >= 7 days, "Remaining lock-in period is less than a week, cannot restake");

    uint256 remainingTimeInWeeks = remainingTimeInSeconds / (7 days);

    console.log("rema",remainingTimeInWeeks);

    // Recalculate boosted amount based on remaining time in weeks
    totalSupplyLocked -= lockedStakes[msg.sender].amount;
    uint multiplier = isFirstStake ? (15 * 10000) : 0;
    multiplier += multiplier > 1 ? (remainingTimeInWeeks - 2) * (38 * 100) : (remainingTimeInWeeks) * (38 * 100);
    uint boostedAmt = (_balances[msg.sender] * multiplier) / 10000;
    totalSupplyLocked += boostedAmt;
    lockedStakes[msg.sender].amount = boostedAmt;
}


    function extendLockin(uint256 extendedTime) external  updateReward(msg.sender){
        require(locking[msg.sender] == true ,"You have not locked any saltz");
        
            require(extendedTime % (7 days) ==0," Enter time in weeks");
                uint256 newTime = extendedTime + lockedStakes[msg.sender].unlockTime;
                uint256 newTimeinWeeks = extendedTime / (7 days);
                uint256 newBoostedAmt = (_balances[msg.sender] * (newTimeinWeeks * (38 * 100)))/10000;
                totalSupplyLocked += newBoostedAmt;
                lockedStakes[msg.sender].amount += newBoostedAmt;
                lockedStakes[msg.sender].unlockTime = newTime;
            emit LockinExtended(msg.sender, extendedTime);
    }

    function withdraw(uint _amount) external  updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        require(_balances[msg.sender] >= _amount,"Not enough balance");
        require(flexible[msg.sender],"You are not in flexible mode");
       
        uint256 x = block.timestamp - sevenDayTax[msg.sender];
        if (x < 7 days) {
            _balances[msg.sender] -= _amount;
            totalSupply -= _amount;
            totalSupplyWithoutLocked -=_amount;
            uint256 sevenTax = _amount.mul(100).div(10000);
            rewardsToken.transfer(msg.sender, _amount - sevenTax);
            rewardsToken.transfer(address(Ivault), sevenTax);
            if(_balances[msg.sender]==0){
                flexible[msg.sender] = false;
            }
            emit UnStakeWithFine(_amount - sevenTax, _amount, msg.sender);
        } else {
            _balances[msg.sender] -= _amount;
            totalSupply -= _amount;
            totalSupplyWithoutLocked -=_amount;
            rewardsToken.transfer(msg.sender, _amount);
             if(_balances[msg.sender]==0){
                flexible[msg.sender] = false;
            }
            emit UnStake(_amount, msg.sender);
        }
    }

    function withdrawForLockedStackers() external  updateReward(msg.sender) {
        require(block.timestamp  > lockedStakes[msg.sender].lockedTimeStamp + (lockedStakes[msg.sender].unlockTime), "Your lockin period is not over yet");
        require(locking[msg.sender],"You are not in lockin mode");
            uint amount = _balances[msg.sender];
            _balances[msg.sender] = 0;
            totalSupply -= amount;
            rewardsToken.transfer(msg.sender, amount);
            totalSupplyLocked -= lockedStakes[msg.sender].amount;
            lockedStakes[msg.sender].amount = 0;
            lockedStakes[msg.sender].unlockTime = 0;
            lockedStakes[msg.sender].lockedTimeStamp = 0;
            locking[msg.sender]=false;
            emit unstakedLocked(msg.sender,amount);
        
    }

   function getReward() public  updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            Ivault.withdraw(reward, msg.sender);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function setRewardsDuration(uint _rewardsDuration) external ownerOrWallet {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function notifyRewardAmount(uint256 reward) external updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        
        uint balance = rewardsToken.balanceOf(address(Ivault));
        require(
            rewardRate <= balance.div(rewardsDuration),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function updateInitialBoost(uint256 _initialBoost) public ownerOrWallet {
        initialBoost = _initialBoost;
    }

    function updateBoost(uint256 _boost) public ownerOrWallet {
        boost = _boost;
    }

    function addVault(address _vault) public onlyOwner {
        vault = _vault;
        Ivault = IVault(_vault);
    }

    function totalSupplyWithLocked() public view returns(uint){
        return totalSupplyWithoutLocked+totalSupplyLocked;
    }

    function balanceOf(address user) external view returns(uint) {
        return _balances[user];
    }

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event unstakedLocked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event LockinExtended(address indexed user, uint256 time);
    event UnStake(uint256 amount, address account);
    event UnStakeWithFine(uint256 fineAmount, uint256 amount, address account);
}