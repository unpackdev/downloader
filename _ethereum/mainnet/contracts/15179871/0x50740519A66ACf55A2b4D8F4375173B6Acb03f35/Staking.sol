
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract Staking {

    constructor() {

        stakeholders.push();

    }

    struct Stake {
        address user;
        uint256 amount;
        uint256 since;
        uint256 claimable;

    }

    struct Stakeholder {
        address user;
        Stake[] address_stakes;
    }

    struct StakingSummary {
        uint256 total_amount;
        Stake[] stakes;
    }

    uint256 public _rewardRateC1 = 1000;
    uint256 public _rewardRateC2 = 1000;
    uint256 public _rewardRateC3 = 1000;
    uint256 public _rewardRateC4 = 1000;
    uint256 public _rewardRateC5 = 1000;

    Stakeholder[] internal stakeholders;

    mapping(address => uint256) internal stakes;

    event Staked(address indexed user, uint256 amount, uint256 index, uint256 timestamp);

    function _addStakeHolder(address staker) internal returns (uint256){
        stakeholders.push();
        uint256 userIndex = stakeholders.length - 1;

        stakeholders[userIndex].user = staker;

        stakes[staker] = userIndex;

        return userIndex;
    }

    function _stake(uint256 _amount) internal {
        require(_amount > 0);

        uint256 index = stakes[msg.sender];

        uint256 timestamp = block.timestamp;

        if(index == 0){
            // This stakeholder stakes for the first time
            // We need to add him to the stakeHolders and also map it into the Index of the stakes
            // The index returned will be the index of the stakeholder in the stakeholders array
            index = _addStakeHolder(msg.sender);

            stakeholders[index].address_stakes.push(Stake(msg.sender, _amount, timestamp, 0));

            emit Staked(msg.sender, _amount, index,timestamp);
        }
    }

    function calculateStakeReward(Stake memory _current_stake, uint256 clan) internal view returns(uint256){
        if(clan == 1){
            return (((block.timestamp - _current_stake.since) / 1 hours) * _current_stake.amount) / _rewardRateC1;
        }if(clan == 2) {
            return (((block.timestamp - _current_stake.since) / 1 hours) * _current_stake.amount) / _rewardRateC2;
        }if(clan == 3){
            return (((block.timestamp - _current_stake.since) / 1 hours) * _current_stake.amount) / _rewardRateC3;
        }if(clan == 4){
            return (((block.timestamp - _current_stake.since) / 1 hours) * _current_stake.amount) / _rewardRateC4;
        }if(clan == 5){
            return (((block.timestamp - _current_stake.since) / 1 hours) * _current_stake.amount) / _rewardRateC5;
        }
    }

    function _withdrawStake(uint256 amount, uint256 index, uint256 _clan) internal returns(uint256){
         // Grab user_index which is the index to use to grab the Stake[]
        uint256 clan = _clan;
        uint256 user_index = stakes[msg.sender];
        Stake memory current_stake = stakeholders[user_index].address_stakes[index];
        require(current_stake.amount >= amount, "Staking: Cannot withdraw more than you have staked");

         // Calculate available Reward first before we start modifying data
         uint256 reward = calculateStakeReward(current_stake, clan);
         // Remove by subtracting the money unstaked 
         current_stake.amount = current_stake.amount - amount;
         // If stake is empty, 0, then remove it from the array of stakes
         if(current_stake.amount == 0){
             delete stakeholders[user_index].address_stakes[index];
         }else {
             // If not empty then replace the value of it
             stakeholders[user_index].address_stakes[index].amount = current_stake.amount;
             // Reset timer of stake
            stakeholders[user_index].address_stakes[index].since = block.timestamp;    
         }

         return amount+reward;

     }

}