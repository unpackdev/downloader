//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/*
Contract created by Simon Boccara
Old Twitter: @simon_rice_
New Twitter: @0xSimon_

Deployment By: ______
*/

import "./Ownable.sol";
import "./ReentrancyGuard.sol";


contract Champs_Newsletter is Ownable,ReentrancyGuard{

    bool concurrent = false;
    mapping(address => uint256) public expirationTime;

    mapping(uint256 => subscriptionPolicy) public subscriptionPolicies;

    struct subscriptionPolicy
    {
        uint256 duration;
        uint256 price;
        bool isActive;
    }

    constructor(){
        setSubscriptionPolicy(0,30,.02 ether,true);
        setSubscriptionPolicy(1,90,.045 ether,true);
        // setSubscriptionPolicy(2,365,.2 ether,true);
    }
    

   
    function getPolicyByIndex(uint256 index) public view returns (uint256,uint256,bool){
        subscriptionPolicy memory currPolicy = subscriptionPolicies[index];
        return(currPolicy.duration,currPolicy.price,currPolicy.isActive);
    }


    function setSubscriptionPolicy(uint256 index, uint256 duration_in_days, uint256 price, bool activeStatus) public onlyOwner {
        subscriptionPolicies[index].duration  = duration_in_days *  1 days;
        subscriptionPolicies[index].price = price;
        subscriptionPolicies[index].isActive = activeStatus;
    }

     function subscribe(uint256 subscriptionPolicyIndex) external payable  nonReentrant{
        require(msg.value >= subscriptionPolicies[subscriptionPolicyIndex].price,"Insufficient Funds Sent");
        require(subscriptionPolicies[subscriptionPolicyIndex].isActive,"This Policy Isn't Active");
        
        expirationTime[msg.sender] = subscriptionPolicies[subscriptionPolicyIndex].duration + block.timestamp;
        return;
    }

    function subscribeConcurrent(uint256 subscriptionPolicyIndex) external payable  nonReentrant{
        require(concurrent,"Concurrent Add-On Subscription Not Available");
        require(msg.value >= subscriptionPolicies[subscriptionPolicyIndex].price,"Insufficient Funds Sent");
        require(subscriptionPolicies[subscriptionPolicyIndex].isActive,"This Policy Isn't Active");
        if(isSubscribed()){
             expirationTime[msg.sender] = subscriptionPolicies[subscriptionPolicyIndex].duration + expirationTime[msg.sender] ;
             return;
        }
        expirationTime[msg.sender] = subscriptionPolicies[subscriptionPolicyIndex].duration + block.timestamp;
        return;
    }

    


    function subscribeForAddress(uint256 subscriptionPolicyIndex, address _address) external onlyOwner {
        require(subscriptionPolicies[subscriptionPolicyIndex].isActive,"This Policy Isn't Active");
        if(isAddressSubscribed(_address)){
             expirationTime[_address] = subscriptionPolicies[subscriptionPolicyIndex].duration + expirationTime[_address];
             return;
        }
        expirationTime[_address] = subscriptionPolicies[subscriptionPolicyIndex].duration + block.timestamp;
        return;

    }

    function isAddressSubscribed(address _address) public view returns(bool){
        return (expirationTime[_address] >= block.timestamp);
    }

    function isSubscribed() public view returns(bool){
        return expirationTime[msg.sender] >= block.timestamp;
    }

    function disableSubscriptionPolicy(uint256 index) public onlyOwner{
        subscriptionPolicies[index].isActive = false;
    }

    function enableSubscriptionPolicy(uint256 index) public onlyOwner{
        subscriptionPolicies[index].isActive = true;
    }

    function setConcurrent(bool _state) public onlyOwner{
        concurrent = _state;
    }

  function withdraw() public payable onlyOwner {
    uint256 balance = address(this).balance;
    (bool r1, ) = payable(msg.sender).call{value: balance}("");  //Le Rest
    require(r1);
   

  }


}