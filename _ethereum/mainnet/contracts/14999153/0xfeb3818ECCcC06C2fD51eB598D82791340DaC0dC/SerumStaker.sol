pragma solidity ^0.8.4;

import "./IERC721.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./ISucker.sol";

contract VitriolStaker is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    struct SerumPair {
        uint256 suckerId;
    }

    struct UserStake {
        EnumerableSet.UintSet pairSerums;
        EnumerableSet.UintSet singleSerums;
        uint112 lastRewardUpdate;
        uint256 rewardsAccumulated;
    }

    mapping (uint256 => SerumPair) public serumStakes;
    mapping(address => UserStake) private serumUsers;

    IERC721 suckerNft;
    IERC721 serumNft;
    ISucker suckerToken;

    uint256 public REWARD_FOR_SERUM_SINGLE = 567129629629629660000;
    uint256 public REWARD_FOR_SERUM_PAIR = 798611111111111100000;
    
    bool stakingEnd;

    modifier updateRewards(address user) {
        UserStake storage stakerUser = serumUsers[user];
        uint256 rewardBlocks = block.timestamp - stakerUser.lastRewardUpdate;
        uint256 pairSerums = (rewardBlocks * REWARD_FOR_SERUM_PAIR) * stakerUser.pairSerums.length();
        uint256 singleSerums = (rewardBlocks * REWARD_FOR_SERUM_SINGLE) * stakerUser.singleSerums.length();
        stakerUser.lastRewardUpdate = uint112(block.timestamp);
        stakerUser.rewardsAccumulated += (pairSerums + singleSerums);
        _;
    }

    constructor(IERC721 _sucker, IERC721 _serum, ISucker _suckerToken) {
        suckerNft = _sucker;
        serumNft = _serum;
        suckerToken = _suckerToken;
    }

    function stakePairSerum(uint256[] memory serumIds, uint256[] memory suckerIds) external updateRewards(msg.sender) {
        require(serumIds.length == suckerIds.length, "NO_PAIR");

        UserStake storage user = serumUsers[msg.sender];

        for(uint256 i; i < serumIds.length;) {
            uint256 serumId = serumIds[i];
            uint256 suckerId = suckerIds[i];
            require(serumNft.ownerOf(serumId) == msg.sender && suckerNft.ownerOf(suckerId) == msg.sender, "NOT_OWNER");
            user.pairSerums.add(serumId);
            serumStakes[serumId].suckerId = suckerId;
            serumNft.transferFrom(msg.sender, address(this), serumId);
            suckerNft.transferFrom(msg.sender, address(this), suckerId);
            unchecked {
                ++i;
            }
        }
    }

    function stakeSingleSerums(uint256[] memory serumIds) external updateRewards(msg.sender) {
        UserStake storage user = serumUsers[msg.sender];
        
        for(uint256 i; i < serumIds.length;) {
            uint256 serumId = serumIds[i];
            require(serumNft.ownerOf(serumId) == msg.sender, "NOT_OWNER");
            user.singleSerums.add(serumId);
            serumNft.transferFrom(msg.sender, address(this), serumId);
            unchecked {
                ++i;
            }
        }
    }

    function unstakeSerumPairs(uint256[] memory serumIds) external updateRewards(msg.sender) {
        UserStake storage user = serumUsers[msg.sender];

        for(uint256 i; i < serumIds.length;) {
            uint256 serumId = serumIds[i];
            require(user.pairSerums.contains(serumId), "NOT_OWNER");
            serumUsers[msg.sender].pairSerums.remove(serumId);
            uint256 suckerIdPair = serumStakes[serumId].suckerId;
            serumStakes[serumId].suckerId = 0;
            suckerNft.transferFrom(address(this), msg.sender, suckerIdPair); 
            serumNft.transferFrom(address(this), msg.sender, serumId);
            unchecked {
                ++i;
            }
        }
    }

    function unstakeSingleSerums(uint256[] memory serumIds) external updateRewards(msg.sender) {
        UserStake storage user = serumUsers[msg.sender];

        for(uint256 i; i < serumIds.length;) {
            uint256 serumId = serumIds[i];
            require(user.singleSerums.contains(serumId), "NOT_OWNER");
            serumUsers[msg.sender].singleSerums.remove(serumId);
            serumNft.transferFrom(address(this),msg.sender, serumId);
            unchecked {
                ++i;
            }
        }
    }

    function claimRewards() external updateRewards(msg.sender) {
        require(!stakingEnd, "STAKING_END");
        UserStake storage user = serumUsers[msg.sender];
        uint256 userRewards = user.rewardsAccumulated;
        require(userRewards > 0, "NO_REWARDS");
        user.rewardsAccumulated = 0;
        suckerToken.mint(msg.sender, userRewards);
    }

    function editTokenEmissions(uint256 serumPair, uint256 noPair) external onlyOwner {
        REWARD_FOR_SERUM_PAIR = serumPair;
        REWARD_FOR_SERUM_SINGLE = noPair;
    }

    function editTokenAddresses(IERC721 _sucker, IERC721 _serum, ISucker _suck) external onlyOwner {
        suckerNft = _sucker;
        serumNft = _serum;
        suckerToken = _suck;
    }

    function endStaking(bool _end) external onlyOwner {
        stakingEnd = _end;
    }

    function getUser(address userAddress) view external returns(uint[] memory, uint[] memory, uint, uint) {
        UserStake storage user = serumUsers[userAddress];
        uint[] memory serumsPaired = user.pairSerums.values();
        uint[] memory singleSerums = user.singleSerums.values();
        return (serumsPaired, singleSerums, user.lastRewardUpdate, user.rewardsAccumulated);
    }

}
