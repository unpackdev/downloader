//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./console.sol";


contract HyveVaults is Ownable {

    IERC20 public hyve_contract;

    uint256[] public availableTiers;

    mapping(uint256 => uint256) public tierAmounts;

    mapping(uint256 => uint256) public tierHyveBalances;
      
    mapping(address=>mapping(uint256 => uint256)) public stakeTimes;
    mapping(address=>mapping(uint256 => uint256)) public stakedAmounts;
  

    constructor(address hyve){
        hyve_contract=IERC20(hyve);
    }

    function stakeHyve(uint256 tier) external {
        
        require(tierAmounts[tier]!=0,"HYVE_VAULTS:TIER_NOT_FOUND");

        hyve_contract.transferFrom(msg.sender, address(this), tierAmounts[tier]);
 
        stakeTimes[msg.sender][tier]=block.timestamp;
        stakedAmounts[msg.sender][tier]+=tierAmounts[tier];
        tierHyveBalances[tier]+=tierAmounts[tier];

    }

    function unstakeHyve(uint256 tier) external {
        
        require(stakedAmounts[msg.sender][tier] > 0,"HYVE_VAULTS:FUNDS_UNAVAILABLE");
        require(stakeTimes[msg.sender][tier] + 30 days <= block.timestamp,"HYVE_VAULTS:UNSTAKE_BEFORE_END");
        
        uint256 unstakeAmount = stakedAmounts[msg.sender][tier];
        stakedAmounts[msg.sender][tier]=0;
        tierHyveBalances[tier]-=unstakeAmount;

        hyve_contract.transfer(msg.sender, unstakeAmount);

    }

    function setTierRequiredAmounts(uint256 tier, uint256 amount) onlyOwner external{
        
        require(tier>0,"HYVE_VAULTS:TIER_0_NOT_ALLOWED");

        if(tierAmounts[tier] > 0 && amount == 0){
            for(uint i=0;i < availableTiers.length; i++){
                if(availableTiers[i]==tier){
                    availableTiers[i]=availableTiers[availableTiers.length-1];
                    availableTiers[availableTiers.length-1]=0;
                }
            }
        } else if(tierAmounts[tier] == 0 && amount > 0){
            availableTiers.push(tier);
        }

        tierAmounts[tier]=amount;
        
    }

}