// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./Ownable.sol";

contract  IRewardDistributionRecipient is Ownable {
    //Init as owner address
    address public rewardDistribution = msg.sender;

    function notifyRewardAmount(uint256 reward) virtual external {}

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}