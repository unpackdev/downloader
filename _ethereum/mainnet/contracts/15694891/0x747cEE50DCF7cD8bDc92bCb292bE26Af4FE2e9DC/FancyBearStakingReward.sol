// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeERC20.sol";
import "./AccessControlEnumerable.sol";
import "./IHoneyToken.sol";

contract FancyBearStakingReward is AccessControlEnumerable {
    using SafeERC20 for IHoneyToken;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    enum ClaimingStatus {
        Off,
        Active
    }

    struct Reward {
        uint256 rewardAmount;
        bool set;
    }

    IHoneyToken public honeyContract;
    ClaimingStatus public claimingStatus;
    uint256 public maxRewardAmount;

    mapping(address => Reward) private rewards;

    event HoneyRewardClaimed(address indexed _to, uint256 _rewardAmount);

    constructor(IHoneyToken _honeyContractAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
        honeyContract = _honeyContractAddress;
        claimingStatus = ClaimingStatus.Active;
        maxRewardAmount = 2000000 ether;
    }

    function setClaimingStatus(ClaimingStatus _claimingStatus)
        public
        onlyRole(MANAGER_ROLE)
    {
        claimingStatus = _claimingStatus;
    }

    function setMaxRewardAmount(uint256 amount) public onlyRole(MANAGER_ROLE) {
        maxRewardAmount = amount;
    }

    function getRewardForClaiming(address _wallet) public view returns (uint256) {
        //require(rewards[_wallet].set, "getRewardForClaiming: reward not set");
        return rewards[_wallet].rewardAmount;
    }

    function addRewardsForClaiming(
        address[] calldata _wallets,
        uint256[] calldata _rewardsAmount
    ) public onlyRole(MANAGER_ROLE) {
        
        require(
            _wallets.length == _rewardsAmount.length,
            "addRewardsForClaiming: the length of the input arrays must be the same."
        );

        uint256 loopLength = _wallets.length;

        for (uint256 i; i < loopLength; i++) {

            require(
                _rewardsAmount[i] != 0 && _rewardsAmount[i] <= maxRewardAmount,
                "addRewardsForClaiming: amount to reward must be greater than zero and lower than maxRewardAmount."
            );

            if(rewards[_wallets[i]].set) {                
                rewards[_wallets[i]].rewardAmount += _rewardsAmount[i];
            } else {
                rewards[_wallets[i]] = Reward({
                    rewardAmount: _rewardsAmount[i],
                    set: true
                });
            }

        }

    }

    function removeReward(address _wallet) public onlyRole(MANAGER_ROLE) {
        require(rewards[_wallet].set, "removeReward: reward not set");
        delete(rewards[_wallet]);      
    }

    function claimHoneyReward() external {

        require(claimingStatus == ClaimingStatus.Active, "claimHoneyReward: claiming is off!");
        require(rewards[msg.sender].set, "claimHoneyReward: reward not set");

        uint256 rewardAmount = rewards[msg.sender].rewardAmount;

        delete(rewards[msg.sender]);  

        emit HoneyRewardClaimed(msg.sender, rewardAmount);

        honeyContract.safeTransfer(msg.sender, rewardAmount);

    }

}
