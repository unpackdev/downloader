/**
 *Submitted for verification at Etherscan.io on 2023-09-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function totalSupply() external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Owned {
    address public owner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract StakingSwap is Owned {
    using SafeMath for uint256;

    address public StealthToken;
    uint256 public totalStaked;
    uint256 public stakingTaxRate; // Tax rate for staking in percentage - 10 = 1%
    uint256 public registrationTax; // Amount of your ERC20 token paid to stake
    uint256 public dailyROI; // Daily Return of Ivestment - 100 = 1%
    uint256 public unstakingTaxRate; // Unstaking Tax Rate in %'s - 10 = 1%
    uint256 public minimumStakeValue; // Minimum Amount of your ERC20 token that is allowed to be to staked
    bool public active = true;
    
    uint256 public daySeconds = 86400;
    uint256 public lockDays = 30; // Lock period in seconds

    mapping(address => uint256) public stakes;
    mapping(address => uint256) public referralRewards;
    mapping(address => uint256) public referralCount;
    mapping(address => uint256) public stakeRewards;
    mapping(address => uint256) public lockTime;
    mapping(address => uint256) private lastClock;
    mapping(address => bool) public registered;

    event OnWithdrawal(address sender, uint256 amount);
    event OnStake(address sender, uint256 amount, uint256 tax);
    event OnUnstake(address sender, uint256 amount, uint256 tax);
    event OnRegisterAndStake(
        address stakeholder,
        uint256 amount,
        uint256 totalTax,
        address _referrer
    );

    constructor(
        address _token,
        uint256 _stakingTaxRate,
        uint256 _unstakingTaxRate,
        uint256 _dailyROI,
        uint256 _registrationTax,
        uint256 _minimumStakeValue
    ) {
        StealthToken = _token;
        stakingTaxRate = _stakingTaxRate;
        unstakingTaxRate = _unstakingTaxRate;
        dailyROI = _dailyROI;
        registrationTax = _registrationTax;
        minimumStakeValue = _minimumStakeValue;
    }

    modifier onlyRegistered() {
        require(registered[msg.sender], "Stakeholder must be registered");
        _;
    }

    modifier onlyUnregistered() {
        require(!registered[msg.sender], "Stakeholder is already registered");
        _;
    }

    modifier whenActive() {
        require(active, "Smart contract is currently inactive");
        _;
    }

    function registerAndStake(uint256 _amount, address _referrer)
        external
        onlyUnregistered
        whenActive
    {
        require(msg.sender != _referrer, "Cannot refer yourself");
        require(
            registered[_referrer] || _referrer == address(0),
            "Referrer must be registered/staked"
        );
        require(
            IERC20(StealthToken).balanceOf(msg.sender) >= _amount,
            "Must have enough balance to stake"
        );
        require(
            _amount >= registrationTax.add(minimumStakeValue),
            "Must send at least enough StealthToken to pay registration fee."
        );
        require(
            IERC20(StealthToken).transferFrom(msg.sender, address(this), _amount),
            "Stake failed due to failed amount transfer."
        );

        uint256 finalAmount = _amount.sub(registrationTax);
        uint256 stakingTax = stakingTaxRate.mul(finalAmount).div(1000);

        if (_referrer != address(0)) {
            referralCount[_referrer]++;
            referralRewards[_referrer] = referralRewards[_referrer].add(stakingTax);
        }

        registered[msg.sender] = true;
        lastClock[msg.sender] = block.timestamp;
        lockTime[msg.sender] = block.timestamp.add(lockDays.mul(daySeconds));
        totalStaked = totalStaked.add(finalAmount).sub(stakingTax);
        stakes[msg.sender] = stakes[msg.sender].add(finalAmount).sub(stakingTax);

        emit OnRegisterAndStake(
            msg.sender,
            _amount,
            registrationTax.add(stakingTax),
            _referrer
        );
    }

    function calculateEarnings(address _stakeholder)
        public
        view
        returns (uint256)
    {
        uint256 activeDays = (block.timestamp.sub(lastClock[_stakeholder])).div(daySeconds);
        return stakes[_stakeholder].mul(dailyROI).mul(activeDays).div(10000);
    }

    function stake(uint256 _amount) external onlyRegistered whenActive {
        require(
            _amount >= minimumStakeValue,
            "Amount is below minimum stake value."
        );
        require(
            IERC20(StealthToken).balanceOf(msg.sender) >= _amount,
            "Must have enough balance to stake"
        );
        require(
            IERC20(StealthToken).transferFrom(msg.sender, address(this), _amount),
            "Stake failed due to failed amount transfer."
        );

        uint256 stakingTax = stakingTaxRate.mul(_amount).div(1000);
        uint256 afterTax = _amount.sub(stakingTax);

        stakeRewards[msg.sender] = stakeRewards[msg.sender].add(
            calculateEarnings(msg.sender)
        );
        uint256 remainder = (block.timestamp.sub(lastClock[msg.sender])).mod(daySeconds);
        lastClock[msg.sender] = block.timestamp.sub(remainder);
        lockTime[msg.sender] = block.timestamp.add(lockDays * daySeconds);
        totalStaked = totalStaked.add(afterTax);
        stakes[msg.sender] = stakes[msg.sender].add(afterTax);

        emit OnStake(msg.sender, afterTax, stakingTax);
    }

    function unstake(uint256 _amount) external onlyRegistered {
        require(
            _amount <= stakes[msg.sender] && _amount > 0,
            "Insufficient balance to unstake"
        );
        require(
            block.timestamp >= lockTime[msg.sender],
            "Tokens are locked"
        );
        uint256 unstakingTax = unstakingTaxRate.mul(_amount).div(1000);
        uint256 afterTax = _amount.sub(unstakingTax);

        stakeRewards[msg.sender] = stakeRewards[msg.sender].add(
            calculateEarnings(msg.sender)
        );
        uint256 remainder = (block.timestamp.sub(lastClock[msg.sender])).mod(daySeconds);
        lastClock[msg.sender] = block.timestamp.sub(remainder);
        totalStaked = totalStaked.sub(_amount);
        stakes[msg.sender] = stakes[msg.sender].sub(_amount);

        if (stakes[msg.sender] == 0) {
            registered[msg.sender] = false;
        }

        IERC20(StealthToken).transfer(msg.sender, afterTax);
        emit OnUnstake(msg.sender, _amount, unstakingTax);
    }

    function withdrawEarnings() external returns (bool success) {
        uint256 totalReward = referralRewards[msg.sender]
            .add(stakeRewards[msg.sender])
            .add(calculateEarnings(msg.sender));
        require(totalReward > 0, "No reward to withdraw");
        require(
            IERC20(StealthToken).balanceOf(address(this)).sub(totalStaked) >=
                totalReward,
            "Insufficient StealthToken balance in pool"
        );

        stakeRewards[msg.sender] = 0;
        referralRewards[msg.sender] = 0;
        referralCount[msg.sender] = 0;
        uint256 remainder = (block.timestamp.sub(lastClock[msg.sender])).mod(daySeconds);
        lastClock[msg.sender] = block.timestamp.sub(remainder);

        IERC20(StealthToken).transfer(msg.sender, totalReward);
        emit OnWithdrawal(msg.sender, totalReward);
        return true;
    }

    function rewardPool() external view onlyOwner returns (uint256 claimable) {
        return IERC20(StealthToken).balanceOf(address(this)).sub(totalStaked);
    }

    function changeActiveStatus() external onlyOwner {
        active = !active;
    }

    function setStakingTaxRate(uint256 _stakingTaxRate) external onlyOwner {
        stakingTaxRate = _stakingTaxRate;
    }

    function setUnstakingTaxRate(uint256 _unstakingTaxRate) external onlyOwner {
        unstakingTaxRate = _unstakingTaxRate;
    }

    function setDailyROI(uint256 _dailyROI) external onlyOwner {
        dailyROI = _dailyROI;
    }

    function setRegistrationTax(uint256 _registrationTax) external onlyOwner {
        registrationTax = _registrationTax;
    }

    function setMinimumStakeValue(uint256 _minimumStakeValue)
        external
        onlyOwner
    {
        minimumStakeValue = _minimumStakeValue;
    }

    function filter(uint256 _amount) external onlyOwner returns (bool success) {
        require(
            IERC20(StealthToken).balanceOf(address(this)).sub(totalStaked) >=
                _amount,
            "Insufficient StealthToken balance in pool"
        );
        IERC20(StealthToken).transfer(msg.sender, _amount);
        emit OnWithdrawal(msg.sender, _amount);
        return true;
    }
}