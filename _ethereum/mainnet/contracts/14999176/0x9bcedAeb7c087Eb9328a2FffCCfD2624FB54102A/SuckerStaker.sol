pragma solidity ^0.8.4;

import "./IERC721.sol";
import "./EnumerableSet.sol";
import "./ISucker.sol";
import "./Ownable.sol";

contract SuckerStaker is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    struct UserStake {
        EnumerableSet.UintSet suckers;
        uint256 lastRewardUpdate;
        uint256 rewardsAccumulated;
    }

    mapping(address => UserStake) private suckerUsers;

    IERC721 suckerNft;
    ISucker suckerToken;

    uint256 public REWARD_PER_SUCKER = 104166666666666670000;

    modifier updateRewards(address user) {
        UserStake storage stakerUser = suckerUsers[user];
        uint256 rewardBlocks = block.timestamp - stakerUser.lastRewardUpdate;
        uint256 suckersRewards = (rewardBlocks * REWARD_PER_SUCKER) * stakerUser.suckers.length();
        stakerUser.lastRewardUpdate = block.timestamp;
        stakerUser.rewardsAccumulated += suckersRewards;
        _;
    }

    constructor(IERC721 _sucker, ISucker _suckerToken) {
        suckerNft = _sucker;
        suckerToken = _suckerToken;
    }

    function stakeSuckers(uint256[] memory suckerIds) external updateRewards(msg.sender) {
        UserStake storage user = suckerUsers[msg.sender];
        
        for(uint256 i; i < suckerIds.length;) {
            uint256 suckerId = suckerIds[i];
            require(suckerNft.ownerOf(suckerId) == msg.sender, "NOT_OWNER");
            user.suckers.add(suckerId);
            suckerNft.transferFrom(msg.sender, address(this), suckerId);
            unchecked {
                ++i;
            }
        }
    }

    function unstakeSuckers(uint256[] memory suckerIds) external updateRewards(msg.sender) {
        UserStake storage user = suckerUsers[msg.sender];

        for(uint256 i; i < suckerIds.length;) {
            uint256 suckerId = suckerIds[i];
            require(user.suckers.contains(suckerId), "NOT_OWNER");
            suckerUsers[msg.sender].suckers.remove(suckerId);
            suckerNft.transferFrom(address(this), msg.sender, suckerId);
            unchecked {
                ++i;
            }
        }
    }

    function claimRewards() external updateRewards(msg.sender) {
        UserStake storage user = suckerUsers[msg.sender];
        uint256 userRewards = user.rewardsAccumulated;
        require(userRewards > 0, "NO_REWARDS");
        user.rewardsAccumulated = 0;
        suckerToken.mint(msg.sender, userRewards);
    }

    function editTokenEmissions(uint256 _sucker) external onlyOwner {
        REWARD_PER_SUCKER = _sucker;
    }

    function getUser(address userAddress) view external returns(uint[] memory, uint, uint) {
        UserStake storage user = suckerUsers[userAddress];
        uint[] memory suckerStaked = user.suckers.values();
        return (suckerStaked, user.lastRewardUpdate, user.rewardsAccumulated);
    }

}
