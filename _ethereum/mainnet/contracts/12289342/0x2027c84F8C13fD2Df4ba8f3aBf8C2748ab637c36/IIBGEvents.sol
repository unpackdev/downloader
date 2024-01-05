// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IIBGEvents {

    event Registration(address indexed _user, address indexed referrer, uint registrationTime);
    event PackPurchased(address indexed _user, uint indexed _pack, uint _plan, uint currentPackAmount, uint time);
    event StakedToken(address indexed stakedBy, uint amountStaked, uint plan, uint time, uint stakingPeriod);
    event DirectReferralIncome(address indexed _from, address indexed receiver, uint incomeRecieved, uint indexed level, uint time);
    event LostIncome(address indexed _from, address indexed reciever, uint incomeLost, uint indexed level, uint time);
    event YieldIncome(address indexed user, uint yieldRecieved, uint time);
    event YieldMatchingIncome(address indexed _from, address indexed receiver, uint incomeRecieved, uint indexed level, uint time);
    event YieldMatchingLostIncome(address indexed _from, address indexed reciever, uint matchingLostIncome, uint indexed level, uint time);
}