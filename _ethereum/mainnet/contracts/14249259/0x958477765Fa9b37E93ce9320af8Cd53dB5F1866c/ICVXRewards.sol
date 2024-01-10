pragma solidity ^0.6.0;

interface ICVXRewards {
    function withdraw(uint256 _amount, bool claim) external;
    function getReward(bool _stake) external;
    function stake(uint256 _amount) external;
}
