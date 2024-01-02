// SPDX-License-Identifier: NONE
pragma solidity ^0.8.18;

import "Ownable.sol";

contract MkongStaker is Ownable {
    struct Staker {
        uint256 stakedBalance;
        uint256 stakeStartTimestamp;
        uint256 totalStakingInterest;
        uint256 totalBurnt;
        bool activeUser;
        uint256 lastDepositTime;
        uint256 unstakeStartTime;
        uint256 pendingAmount;
    }

    mapping(address => bool) public allowedContracts;
    mapping(address => Staker) public stakers;

    modifier onlyAllowedContract() {
        require(allowedContracts[msg.sender] == true, "Not allowed");
        _;
    }

    constructor() Ownable(msg.sender) {}

    function setStaker(
        address _address,
        Staker memory _staker
    ) public onlyAllowedContract {
        stakers[_address] = _staker;
    }

    function getStaker(address _address) public view returns (Staker memory) {
        return stakers[_address];
    }

    function allowContract(address _contract) public onlyOwner {
        allowedContracts[_contract] = true;
    }

    function disallowContract(address _contract) public onlyOwner {
        allowedContracts[_contract] = false;
    }

    // You can add more getter and setter functions here to manipulate individual fields
}
