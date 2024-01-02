// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Staking.sol";
import "./TransferHelper.sol";
import "./IveORN.sol";
import "./IOrionVoting.sol";
import "./IOrionFarmV2.sol";

//import "./console.sol";

contract OrionVoting is Staking
{
    uint256 constant MAX_PERCENT=10000;

    uint256 public countPool;//number of pools
    mapping(uint256 => address) public poolList;//list of pools
    mapping(address => uint256) public poolIndex;//whether there is a pool in the list (index numbers starting from 1)

    mapping(address => uint256) public users;//user votes across all pools
    mapping(address => mapping(address => uint256)) public usersPool;//user votes by pool

    mapping(address => bool) public smarts;//white list of trusted farm contracts

    address public immutable veORN;
    address public immutable ORN;
    address public immutable smartOwner;

    modifier onlyOwner() {
        require(msg.sender == smartOwner, "Caller is not the owner");
        _;
    }

    event UsePool(address indexed pool, bool bUse);
    event Vote(address indexed pool, address indexed account, uint256 amount);
    event Unvote(address indexed pool, address indexed account, uint256 amount);
    event UnvoteAll(address indexed account);
    

    constructor(address veORN_)
    {
        veORN=veORN_;
        ORN=IveORN(veORN).ORN();
        smartOwner=msg.sender;
    }

    //admin caller

    function setSmart(address addr, bool bUse) onlyOwner external
    {
        smarts[addr]=bUse;
    }
    

    function setRewards(uint64 rewards, uint64 duration) onlyOwner external
    {
        _setRewards(rewards,duration);
    }

    function addPool(address pool) onlyOwner public
    {
        countPool++;
        poolIndex[pool]=countPool;
        poolList[countPool]=pool;

        emit UsePool(pool, true);
    }

    function deletePool(address pool) onlyOwner external
    {
        uint256 index=poolIndex[pool];
        require(index>0,"Pool not found");
        delete poolIndex[pool];

        //we move the last element to the place of the deleted one and delete the last element
        poolList[index]=poolList[countPool];
        
        delete poolList[countPool];
        countPool--;

        emit UsePool(pool, false);
    }

    //smart caller

    function claimReward(address pool, address to, uint256 amount) external
    {
        require(smarts[msg.sender],"claimReward: caller not found in white list");

        _claimReward(pool,amount);

        TransferHelper.safeTransfer(ORN,to,amount);
    }


    //user caller
    function votePercent(address pool, uint256 percent) external
    {
        require(percent<=MAX_PERCENT,"Error percent");
        uint256 balanceVeORN=IveORN(veORN).balanceOf0(msg.sender);
        vote(pool, balanceVeORN*percent/MAX_PERCENT);
    }

    function vote(address pool, uint256 amount) public
    {
        require(poolIndex[pool]>0,"Pool not found");

        //check balance
        uint256 balanceVeORN=IveORN(veORN).balanceOf0(msg.sender);
        uint256 balanceVotes=users[msg.sender];
        //require(balanceVeORN >= balanceVotes+amount,"Error user veORN balance");// and revert if overflow
        uint256 balanceRemained;
        if(balanceVeORN>balanceVotes)
            balanceRemained=balanceVeORN-balanceVotes;
        if(amount>balanceRemained)
            amount=balanceRemained;


        users[msg.sender] += amount;
        usersPool[msg.sender][pool] += amount;

        _stake(pool, amount);

        emit Vote(pool, msg.sender, amount);
    }
    
    function unvotePercent(address pool, uint256 percent) external
    {
        require(percent<=MAX_PERCENT,"Error percent");
        uint256 balanceVeORN=IveORN(veORN).balanceOf0(msg.sender);
        unvote(pool, balanceVeORN*percent/MAX_PERCENT);
    }

    function unvote(address pool, uint256 amount) public
    {
        if(usersPool[msg.sender][pool]>amount)
        {
            usersPool[msg.sender][pool] -= amount;
        }
        else
        {
            amount=usersPool[msg.sender][pool];
            delete usersPool[msg.sender][pool];
        }
        if(users[msg.sender]>amount)
        {
            users[msg.sender] -= amount;
        }
        else
        {
            amount=users[msg.sender];
            delete users[msg.sender];
        }

        _unstake(pool, amount);

        emit Unvote(pool, msg.sender, amount);
    }

    //array call support
    function voteArr(address[] calldata pools, uint256[] calldata amounts) external
    {
        require(pools.length == amounts.length,"Pool not found");

        for(uint256 i=0;i<pools.length;i++)
            vote(pools[i], amounts[i]);
    }


    //user or smart caller

    function unvoteAll(address account) external
    {
        require(msg.sender == veORN || msg.sender==account, "unvoteAll: caller is not the veORN contract");

        uint256 balanceVotes=users[account];
        if(balanceVotes>0)
        {
            uint256 _countPool=countPool;
            for(uint256 i=1; i<=_countPool; i++)
            {
                address pool=poolList[i];
                uint256 amount=usersPool[account][pool];

                if(amount>0)
                {
                    usersPool[account][pool] = 0;
                    _unstake(pool, amount);

                    balanceVotes -= amount;
                    if(balanceVotes==0) 
                        break;
                }

            }
            users[account]=0;

            emit UnvoteAll(account);        
        }
    }

    function addPool2(address pool, address farmv2) external
    {
        //добавление пула и создание смарт-контракта наград для пулов v2
        addPool(pool);//check owner
        IOrionFarmV2(farmv2).createSmartReward(pool);
    }

    //view
    function havePool(address account) external view returns (bool)
    {
        return poolIndex[account]>0;
    }
}
