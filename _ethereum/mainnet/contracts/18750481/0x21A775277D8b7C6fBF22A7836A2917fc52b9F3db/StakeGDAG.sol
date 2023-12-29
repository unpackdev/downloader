//SPDX-License-Identifier: MIT

// Decentralized LP Distribution Stake for GhostDAG.org
// Please refer to Ghostpaper.GhostDAG.org 

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function approve(address spender, uint tokens) external returns (bool success);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function totalSupply() external view returns (uint);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    }

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    }

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
    }

contract StakeGDAG is Owned {
    
    using SafeMath for uint;
    address public GDAG;
    address public GDAG_LP;
                         
    uint public feeOnUnstake;                   
    uint public feeOnStake;                     
    uint public minimumStake;
    uint public totalStaked;
    bool public active = true;
    
    mapping(address => uint) public referralCount;
    mapping(address => uint) public referralRewards;
    mapping(address => uint) public stakes;
    mapping(address => uint) public stakeRewards;
    mapping(address => uint) private lastClock;
    
    event OnWithdrawal(address sender, uint amount);
    event OnStake(address sender, uint amount, uint tax);
    event OnUnstake(address sender, uint amount, uint tax);
    
    constructor(
        address _gdag,
        address _gdagLP,
        uint _feeOnStake, 
        uint _feeOnUnstake,
        uint _minimumStake) {
            
        GDAG = _gdag;
        GDAG_LP = _gdagLP;
        feeOnStake = _feeOnStake;
        feeOnUnstake = _feeOnUnstake;
        minimumStake = _minimumStake;
    }
    
    modifier whenActive() {
        require(active == true, "Staking yet to open");
        _;
    }
    
    function checkEarnings(address _stakeholder) public view returns (uint) {
    uint activeDays = (block.timestamp.sub(lastClock[_stakeholder])).div(86400);
    uint gdagLPBalance = IERC20(GDAG_LP).balanceOf(address(this));
    uint rewards = 0;
    uint stakeAmount = stakes[_stakeholder].div(10**18); 
    
    if (stakeAmount >= 287000000) {
        rewards = gdagLPBalance.mul(10).mul(activeDays).mul(30).div(100000000);
    } else if (stakeAmount >= 143500000) {
        rewards = gdagLPBalance.mul(9).mul(activeDays).mul(24).div(100000000);
    } else if (stakeAmount >= 28700000) {
        rewards = gdagLPBalance.mul(8).mul(activeDays).mul(19).div(100000000);
    } else if (stakeAmount >= 2870000) {
        rewards = gdagLPBalance.mul(7).mul(activeDays).mul(14).div(100000000);
    } else if (stakeAmount >= 287000) {
        rewards = gdagLPBalance.mul(6).mul(activeDays).mul(8).div(100000000);
    } else if (stakeAmount >= 28700) {
        rewards = gdagLPBalance.mul(5).mul(activeDays).mul(5).div(100000000);
    }

    return rewards;
    }

    function stakeGDAG(uint _amount) external {
        require(_amount >= minimumStake, "Check minimum stake");
        require(IERC20(GDAG).balanceOf(msg.sender) >= _amount, "Insufficient GDAG Balance");
        require(IERC20(GDAG).transferFrom(msg.sender, address(this), _amount), "Staking Failed");

        uint stakingTax = (feeOnStake.mul(_amount)).div(1000);
        uint afterTax = _amount.sub(stakingTax);

        totalStaked = totalStaked.add(afterTax);
        stakeRewards[msg.sender] = (stakeRewards[msg.sender]).add(checkEarnings(msg.sender));

        uint remainder = (block.timestamp.sub(lastClock[msg.sender])).mod(86400);
        lastClock[msg.sender] = block.timestamp.sub(remainder);
        stakes[msg.sender] = (stakes[msg.sender]).add(afterTax);
        
        emit OnStake(msg.sender, afterTax, stakingTax);
    }
    
    function unstakeGDAG(uint _amount) external {
        require(_amount <= stakes[msg.sender] && _amount > 0, "Not enough GDAG");

        uint unstakingTax = (feeOnUnstake.mul(_amount)).div(1000);
        uint afterTax = _amount.sub(unstakingTax);

        stakeRewards[msg.sender] = (stakeRewards[msg.sender]).add(checkEarnings(msg.sender));
        stakes[msg.sender] = (stakes[msg.sender]).sub(_amount);

        uint remainder = (block.timestamp.sub(lastClock[msg.sender])).mod(86400);
        lastClock[msg.sender] = block.timestamp.sub(remainder);
        totalStaked = totalStaked.sub(_amount);
        IERC20(GDAG).transfer(msg.sender, afterTax);

        emit OnUnstake(msg.sender, _amount, unstakingTax);
    }
    
    function claimEarnings() external returns (bool success) {
    uint totalReward = (referralRewards[msg.sender]).add(stakeRewards[msg.sender]).add(checkEarnings(msg.sender));
    require((block.timestamp - lastClock[msg.sender]) >= 86400, "Minimum claim time not reached");
    require(totalReward > 0, "No rewards to claim"); 
    require(IERC20(GDAG_LP).balanceOf(address(this)) >= totalReward, "Not enough Tokens in Pool");
    
    stakeRewards[msg.sender] = 0;
    referralRewards[msg.sender] = 0;
    referralCount[msg.sender] = 0;

    uint remainder = (block.timestamp.sub(lastClock[msg.sender])).mod(86400);
    lastClock[msg.sender] = block.timestamp.sub(remainder);
    IERC20(GDAG_LP).transfer(msg.sender, totalReward);

    emit OnWithdrawal(msg.sender, totalReward);
    return true;
    }

    function rewardPool() external view returns (uint) {
    return IERC20(GDAG_LP).balanceOf(address(this));
    }
    
    function changePoolStatus() external onlyOwner() {
        if(active) {
            active = false;
        } else {
            active = true;
        }
    }
    
    function setFeeOnStake(uint _feeOnStake) external onlyOwner() {
        feeOnStake = _feeOnStake;
    }

    function setFeeOnUnstake(uint _feeOnUnstake) external onlyOwner() {
        feeOnUnstake = _feeOnUnstake;
    }
    
    function setMinimumStake(uint _minimumStake) external onlyOwner() {
        minimumStake = _minimumStake;
    }
    
    function rescueGDAG(uint _amount) external onlyOwner returns (bool success) {
        require((IERC20(GDAG).balanceOf(address(this))).sub(totalStaked) >= _amount, "Not enough GDAG");
        IERC20(GDAG).transfer(msg.sender, _amount);
        emit OnWithdrawal(msg.sender, _amount);
        return true;
    }
    
    function rescueLP(uint _amount) external onlyOwner returns (bool success) {
    require(IERC20(GDAG_LP).balanceOf(address(this)) >= _amount, "Not enough LP");
    IERC20(GDAG_LP).transfer(msg.sender, _amount);
    emit OnWithdrawal(msg.sender, _amount);
    return true;
    }
    }