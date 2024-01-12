// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Staking {

    uint256 internal rewardPerHour = 1000;
    Stakeholder[] internal stakeholders;
    mapping(address => uint256) internal stakes;
    event Staked(address indexed user, uint256 amount, uint256 index, uint256 timestamp);

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

    function _addStakeholder(address staker) internal returns (uint256) {
        stakeholders.push();
        uint256 userIndex = stakeholders.length - 1;
        stakeholders[userIndex].user = staker;
        stakes[staker] = userIndex;
        return userIndex;
    }

    function _stake(uint256 _amount) internal {
        require(_amount > 0, "Cannot stake nothing");
        uint256 index = stakes[msg.sender];
        uint256 timestamp = block.timestamp;
        if (index == 0) {
            index = _addStakeholder(msg.sender);
        }
        stakeholders[index].address_stakes.push(Stake(msg.sender, _amount, timestamp, 0));
        emit Staked(msg.sender, _amount, index,timestamp);
    }

    function calculateStakeReward(Stake memory _current_stake) internal view returns(uint256){
        return (((block.timestamp - _current_stake.since) / 1 hours) * _current_stake.amount) / rewardPerHour;
    }

    function _withdrawStake(uint256 amount, uint256 index) internal returns(uint256){
        uint256 user_index = stakes[msg.sender];
        Stake memory current_stake = stakeholders[user_index].address_stakes[index];
        require(current_stake.amount >= amount, "Staking: Cannot withdraw more than you have staked");

        uint256 reward = calculateStakeReward(current_stake);
        current_stake.amount = current_stake.amount - amount;
        if (current_stake.amount == 0) {
            delete stakeholders[user_index].address_stakes[index];
        } else {
            stakeholders[user_index].address_stakes[index].amount = current_stake.amount;
            stakeholders[user_index].address_stakes[index].since = block.timestamp;
        }

        return amount+reward;
    }

    function hasStake(address _staker) public view returns(StakingSummary memory){
        uint256 totalStakeAmount;
        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[_staker]].address_stakes);
        for (uint256 s = 0; s < summary.stakes.length; s += 1){
           uint256 availableReward = calculateStakeReward(summary.stakes[s]);
           summary.stakes[s].claimable = availableReward;
           totalStakeAmount = totalStakeAmount+summary.stakes[s].amount;
        }
        summary.total_amount = totalStakeAmount;
        return summary;
    }
}
