// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract CorvusStaking {

    uint256 internal rewardPerHour = 1000;
    Stakeholder[] internal stakeHolders;
    mapping(address => uint256) internal stakes;
    event Staked(address indexed user, uint256 amount, uint256 index, uint256 timestamp);

    constructor() {
        stakeHolders.push();
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
        stakeHolders.push();
        uint256 userIndex = stakeHolders.length - 1;
        stakeHolders[userIndex].user = staker;
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
        stakeHolders[index].address_stakes.push(Stake(msg.sender, _amount, timestamp, 0));
        emit Staked(msg.sender, _amount, index,timestamp);
    }

    function calculateStakeReward(Stake memory _current_stake) internal view returns(uint256){
        return (((block.timestamp - _current_stake.since) / 1 hours) * _current_stake.amount) / rewardPerHour;
    }

    function _withdrawStake(uint256 amount, uint256 index) internal returns(uint256){
        uint256 user_index = stakes[msg.sender];
        Stake memory current_stake = stakeHolders[user_index].address_stakes[index];
        require(current_stake.amount >= amount, "Cannot withdraw more than you have staked");

        uint256 reward = calculateStakeReward(current_stake);
        current_stake.amount = current_stake.amount - amount;
        if (current_stake.amount == 0) {
            delete stakeHolders[user_index].address_stakes[index];
        } else {
            stakeHolders[user_index].address_stakes[index].amount = current_stake.amount;
            stakeHolders[user_index].address_stakes[index].since = block.timestamp;
        }

        return amount+reward;
    }

    function hasStake(address _staker) public view returns(StakingSummary memory){
        uint256 totalStakeAmount;
        StakingSummary memory summary = StakingSummary(0, stakeHolders[stakes[_staker]].address_stakes);
        for (uint256 s = 0; s < summary.stakes.length; s += 1){
           uint256 availableReward = calculateStakeReward(summary.stakes[s]);
           summary.stakes[s].claimable = availableReward;
           totalStakeAmount = totalStakeAmount+summary.stakes[s].amount;
        }
        summary.total_amount = totalStakeAmount;
        return summary;
    }
}
