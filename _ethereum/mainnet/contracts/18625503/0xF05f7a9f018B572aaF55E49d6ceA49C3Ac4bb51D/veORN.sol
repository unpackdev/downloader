// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./TransferHelper.sol";
import "./Math.sol";
import "./Staking.sol";
import "./TWBalance.sol";

import "./IERC20Minimal.sol";

import "./IveORN.sol";
import "./IOrionVoting.sol";


//import "./console.sol";


contract veORN is TWBalance, Staking
{
    using Math for uint128;
    using Math for uint256;

    uint256 public constant  START_TIME = 1690848000;//Aug 01 2023 00:00:00 UTC
    uint128 constant DAY = 86400;
    uint128 constant WEEK = 7 * 86400;
    uint128 constant YEAR = 365 * 86400;
    uint256 constant MAXTIME = 2 * YEAR;

    uint128 constant public ALPHA7 = 0x268e511cc4915e0000;//ALPHA=730/(30-Math.sqrt(730/7))**(1/3)/7;



    uint256 private totalSupplyT0;
    address public smartVote;
    
    uint8 public immutable decimals;


    address public immutable ORN;
    address public immutable smartOwner;

    struct UserInfo
    {
        uint48  time_lock;
        uint128 balance;
        uint128 amount_token;
    }

    mapping(address => UserInfo) private tokenMap;

    event Deposit(address indexed provider, uint256 value, uint256 indexed locktime, int128 mode, uint256 ts);//old
    event Withdraw(address indexed provider, uint256 value, uint256 ts);
    event UpdateDeposit(address indexed provider, uint48  time_lock, uint128 balance, uint128 amount_token, uint256 value, uint256 totalSupplyT0, uint256 ts);


    modifier onlyOwner() {
        require(msg.sender == smartOwner, "Caller is not the owner");
        _;
    }

    constructor(address ORN_)
    {
        ORN=ORN_;
        decimals=IERC20Minimal(ORN).decimals();
        smartOwner=msg.sender;
    }

    //erc20
    function name() pure external returns(string memory)
    {
        return "veORN";
    }
    function symbol() pure external returns(string memory)
    {
        return "veORN";
    }


    function setSmartVote(address addrVote) onlyOwner external
    {
        smartVote=addrVote;
    }
    

    //--------------------------------------Staking support

    function setRewards(uint64 rewards, uint64 duration) onlyOwner external
    {
        _setRewards(rewards,duration);
    }

    function claimReward() public
    {
        uint256 amount=getReward(msg.sender);
        if(amount>0)
        {
            _claimReward(msg.sender,amount);

            TransferHelper.safeTransfer(ORN,msg.sender,amount);            
        }
    }

    //internal
    function unstake(uint256 amount) internal
    {
        claimReward();
        _unstake(msg.sender, amount);
    }



    //--------------------------------------Exp Balance support

    //util

    function getK(uint256 time) public pure returns (uint128) 
    {
        if(time<START_TIME)
            time=START_TIME;
        uint128 deltaYears=(time-START_TIME).from_uint()/YEAR;
        return Math.exp_2(deltaYears*2);
    }
    
    function amountAt(uint256 amount,uint256 time) public pure override returns (uint256) 
    {
        return amount.div256(getK(time));
    }
    
    function amountByTokenAt(uint128 amount_token,uint256 time_lock) public view returns (uint128 balance) 
    {
        uint128 K1=getK(block.timestamp);

        uint128 deltaWeeks=(time_lock-block.timestamp).from_uint()/WEEK;
        //balance=amount_token.mul(Math.sqrt(deltaWeeks)).mul(K1);

        uint128 MultiplicatorSQRT=Math.sqrt(deltaWeeks);
        uint128 Multiplicator1=deltaWeeks.div(ALPHA7);
        uint128 Multiplicator2=Multiplicator1.mul(Multiplicator1);
        uint128 Multiplicator3=Multiplicator2.mul(Multiplicator1);

        balance=amount_token.mul(MultiplicatorSQRT + Multiplicator3).mul(K1);
    }



    //view

    function totalSupply0() public view override returns (uint256) {
        return totalSupplyT0;
    }
    function balanceOf0(address account) public view override returns (uint256) {
        return tokenMap[account].balance;
    }
    function balanceTokenOf(address account) public view  returns (uint256) {
        return tokenMap[account].amount_token ;
    }
    
    function totalSupply() public view override returns (uint256) {
        return amountAt(totalSupply0(),block.timestamp);
    }
    function balanceOf(address account) public view override  returns (uint256) {
        return amountAt(balanceOf0(account),block.timestamp);
    }
    function totalSupply(uint256 time) external view returns (uint256) {
        return amountAt(totalSupply0(),time);
    }
    function balanceOf(address account,uint256 time) external view returns (uint256) {
        return amountAt(balanceOf0(account),time);
    }

    function lockTime(address account) external view returns (uint48) {
        return tokenMap[account].time_lock;
    }

    //external
    
    function create_lock(uint256 _value, uint256 unlock_time) public
    {
        UserInfo memory item=tokenMap[msg.sender];

        require(_value > 0,"need non-zero value");
        require(item.amount_token == 0, "Withdraw old tokens first");
        require(unlock_time > block.timestamp, "Can only lock until time in the future");
        require(unlock_time <= block.timestamp + MAXTIME, "Voting lock can be 2 years max");
        require(unlock_time >= block.timestamp + WEEK, "Voting lock can be 1 week min");

        _deposit_for(msg.sender, _value, unlock_time);
    }


    function increase_amount(uint256 _value) external
    {
        UserInfo memory item=tokenMap[msg.sender];

        require(_value > 0,"need non-zero value");
        require(item.amount_token > 0, "No existing lock found");
        require(item.time_lock > block.timestamp, "Cannot add to expired lock");

        _deposit_for(msg.sender, _value, 0);
    }

    function increase_unlock_time(uint256 unlock_time) public
    {
        UserInfo memory item=tokenMap[msg.sender];
        //require(item.time_lock > block.timestamp, "Lock expired"); - убрано чтобы уменьшить число транзакций для повторного стейкинга
        require(item.amount_token > 0, "No existing lock found");

        require(unlock_time > item.time_lock, "Can only increase lock duration");
        require(unlock_time <= block.timestamp + MAXTIME, "Voting lock can be 2 years max");
        require(unlock_time >= block.timestamp + WEEK, "Voting lock can be 1 week min");

        _deposit_for(msg.sender, 0, unlock_time);
    }
    function increase_unlock_period(uint256 unlock_period) external
    {
        increase_unlock_time(block.timestamp + unlock_period);
    }
    function create_lock_period(uint256 _value, uint256 unlock_period) external
    {
        create_lock(_value, block.timestamp + unlock_period);
    }


    function withdraw() external
    {
        writeTWBalances(msg.sender);

        UserInfo memory item=tokenMap[msg.sender];
        require(block.timestamp >= item.time_lock, "The lock didn't expire");

        //automatic removal of all votes
        if(smartVote != address(0))
            IOrionVoting(smartVote).unvoteAll(msg.sender);

        //staking
        unstake(item.balance);

        uint256 balance=item.amount_token;
        totalSupplyT0 -= item.balance;
        delete tokenMap[msg.sender];

        TransferHelper.safeTransfer(ORN,msg.sender,balance);

        emit Withdraw(msg.sender, balance, block.timestamp);
    }

    //internal
    function _deposit_for(address account, uint256 value, uint256 unlock_time) internal
    {
        writeTWBalances(account);


        UserInfo storage item=tokenMap[account];


        uint128 delta;

        if(unlock_time>0)
        {
            item.time_lock=uint48(unlock_time);
            item.amount_token += uint128(value);
            uint128 balance=amountByTokenAt(item.amount_token, item.time_lock);

            require(balance > item.balance,"_deposit_for: Only increase amount");

            delta = balance-item.balance;
        }
        else
        {
            item.amount_token += uint128(value);
            delta=amountByTokenAt(uint128(value), item.time_lock);
        }

        //staking
        _stake(account, delta);

        item.balance += delta;
        totalSupplyT0 += delta;

        if(value>0)
        {
            TransferHelper.safeTransferFrom(ORN,msg.sender,address(this),value);
        }

        //emit Deposit(account, value, item.time_lock, mode, block.timestamp);//old
        emit UpdateDeposit(account, item.time_lock, item.balance, item.amount_token, value, totalSupplyT0, block.timestamp);
        
    }


 
}


