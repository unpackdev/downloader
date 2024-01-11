pragma solidity ^0.8.4;

import "./IERC721.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./RoboStaking.sol";

contract OmegaStaking is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    struct OmegaStaker {
        uint16 roboStaked;
        uint112 lastRewardUpdate;
        uint256 rewardsAccumulated;
    }

    mapping(address => OmegaStaker) public stakers;
    mapping(address => EnumerableSet.UintSet) private omegaIds;

    RoboStaking public roboStakingContract;
    IERC721 public stakingToken;

    uint256 public REWARD_PER_SECOND = 231481480000000;

    modifier updateStake(address user) {
        //@notice Load User Info
        OmegaStaker memory stakerUser = stakers[user];
        uint256 getUserCount = omegaIds[user].length();
        uint256 fullReward = ((block.timestamp - stakerUser.lastRewardUpdate) * REWARD_PER_SECOND) * getUserCount;
        //@notice Do bonus calc shiz
        uint16 nowUserRoboCount = uint16(roboStakingContract.getStakedCount(user));
        uint256 userRoboStaked = nowUserRoboCount >= stakerUser.roboStaked ? nowUserRoboCount : 0;
        uint256 newReward = userRoboStaked > 0 ? fullReward + (userRoboStaked * fullReward / 100)  : fullReward;
        //@notice Update
        stakers[user] = OmegaStaker({
            roboStaked: nowUserRoboCount,
            lastRewardUpdate: uint112(block.timestamp),
            rewardsAccumulated: stakerUser.rewardsAccumulated + newReward
        });   
        _;
    }

    constructor(RoboStaking _roboStakingContract, IERC721 _stakingToken) {
        roboStakingContract = _roboStakingContract;
        stakingToken = _stakingToken;
    }

    //@notice Allows users to stake their nfts
    //@param tokenIds, pass token ids you want to stake
    function stake(uint256[] calldata tokenIds) external updateStake(msg.sender) {
        unchecked {
            for(uint256 i; i < tokenIds.length; i++) {
                uint256 currentId = tokenIds[i];
                require(stakingToken.ownerOf(currentId) == msg.sender, "NOT_OWNER");
                omegaIds[msg.sender].add(currentId);
                stakingToken.transferFrom(msg.sender, address(this), currentId);
            }       
        }
    }
    //@notice Allows users to unstake their nfts
    //@param tokenIds, pass token ids you want to unstake
    function unstake(uint256[] calldata tokenIds) external updateStake(msg.sender) {
        unchecked {
            for(uint256 i; i < tokenIds.length; i++) {
                uint256 currentId = tokenIds[i];
                require(omegaIds[msg.sender].contains(currentId));
                omegaIds[msg.sender].remove(currentId);
                stakingToken.transferFrom(address(this), msg.sender, currentId);
            }
        }
    }
    //@notice Claim Rewards 
    function claimRewards() external updateStake(msg.sender) {
        uint256 userClaim = stakers[msg.sender].rewardsAccumulated;
        require(userClaim > 0, "NO_REWARDS");
        require(roboStakingContract.balanceOf(address(this)) > userClaim, "STAKING_END");
        stakers[msg.sender].rewardsAccumulated = 0;
        roboStakingContract.transfer(msg.sender, userClaim);
    }

    function setTokens(RoboStaking _robo, IERC721 _staking) external onlyOwner {
        roboStakingContract = _robo;
        stakingToken = _staking;
    }
    
    function editRPM(uint256 _rpm) external onlyOwner {
        REWARD_PER_SECOND = _rpm;
    }

    function getStakedOmegas(address user) public view returns (uint256[] memory) {
        return omegaIds[user].values();
    }

    function getStakedOmegasCount(address user) external view returns(uint256) {
        return omegaIds[user].length();
    }

    //@notice Get rewards for users staked assets
    //@param user to lookup
    function getEarned(address user) public view returns (uint256) {
        OmegaStaker memory stakerUser = stakers[user];
        uint256 getUserCount = omegaIds[user].length();
        uint256 fullReward = ((block.timestamp - stakerUser.lastRewardUpdate) * REWARD_PER_SECOND) * getUserCount;
        uint256 nowUserRoboCount = roboStakingContract.getStakedCount(user);
        uint256 userRoboStaked = nowUserRoboCount >= stakerUser.roboStaked ? stakerUser.roboStaked : 0;
        uint256 newReward = userRoboStaked > 0 ? fullReward + (userRoboStaked * fullReward / 100)  : fullReward;
        return newReward + stakerUser.rewardsAccumulated;
    }
}



