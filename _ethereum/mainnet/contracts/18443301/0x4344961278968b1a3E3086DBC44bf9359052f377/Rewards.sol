/* solhint-disable private-vars-leading-underscore */

pragma solidity 0.8.18;

import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./TBARegistry.sol";

contract Rewards is ReentrancyGuard {
    IERC721 public immutable miladysContract;
    address public immutable avatarContractAddress;

    constructor(address _avatarContractAddress, IERC721 _miladysContract) 
        ReentrancyGuard()
    {
        avatarContractAddress = _avatarContractAddress;
        miladysContract = _miladysContract;
    }

    // indexed by accessoryId
    mapping (uint => RewardInfoForAccessory) public rewardInfoForAccessory;
    struct RewardInfoForAccessory {
        uint rewardsPerWearerAccrued;
        uint totalWearers;
        // indexed by miladyId
        mapping (uint => MiladyRewardInfo) miladyRewardInfo;
    }
    struct MiladyRewardInfo {
        bool isRegistered;
        uint amountClaimed;
    }

    event RewardsAccrued(uint indexed _accessoryId, uint _amount);

    function addRewardsForAccessory(uint _accessoryId)
        payable
        external
        nonReentrant
    {
        require(msg.value > 0, "No ether included");
        require(rewardInfoForAccessory[_accessoryId].totalWearers > 0, "No eligible recipients");

        rewardInfoForAccessory[_accessoryId].rewardsPerWearerAccrued += msg.value / rewardInfoForAccessory[_accessoryId].totalWearers;

        emit RewardsAccrued(_accessoryId, msg.value);
    }

    event MiladyRegisteredForRewards(uint indexed _miladyId, uint indexed _accessoryId);

    function registerMiladyForRewardsForAccessory(uint _miladyId, uint _accessoryId)
        external
    {
        require(msg.sender == avatarContractAddress, "Not avatarContractAddress");
        
        MiladyRewardInfo storage miladyRewardInfo = rewardInfoForAccessory[_accessoryId].miladyRewardInfo[_miladyId];

        require(! miladyRewardInfo.isRegistered, "Milady already registered");

        // when a new Milady is registered, we pretend they've been here the whole time and have already claimed all they could
        // this essentially starts out this Milady with 0 claimable rewards, which will go up as revenue increases
        miladyRewardInfo.amountClaimed = rewardInfoForAccessory[_accessoryId].rewardsPerWearerAccrued;
        rewardInfoForAccessory[_accessoryId].totalWearers ++;

        miladyRewardInfo.isRegistered = true;

        emit MiladyRegisteredForRewards(_miladyId, _accessoryId);
    }

    event MiladyDeregisteredForRewards(uint indexed _miladyId, uint indexed _accessoryId);

    function deregisterMiladyForRewardsForAccessoryAndClaim(uint _miladyId, uint _accessoryId, address payable _recipient)
        external
        nonReentrant
    {
        require(msg.sender == avatarContractAddress, "Not avatarContractAddress");

        MiladyRewardInfo storage miladyRewardInfo = rewardInfoForAccessory[_accessoryId].miladyRewardInfo[_miladyId];

        require(miladyRewardInfo.isRegistered, "Milady not registered");

        _claimRewardsForMiladyForAccessory(_miladyId, _accessoryId, _recipient);

        rewardInfoForAccessory[_accessoryId].totalWearers --;
        miladyRewardInfo.isRegistered = false;

        emit MiladyDeregisteredForRewards(_miladyId, _accessoryId);
    }

    function claimRewardsForMilady(uint _miladyId, uint[] calldata _accessoriesToClaimFor, address payable _recipient)
        external
        nonReentrant
    {
        require(msg.sender == miladysContract.ownerOf(_miladyId), "Not Milady owner");

        for (uint i=0; i<_accessoriesToClaimFor.length;) {
            _claimRewardsForMiladyForAccessory(_miladyId, _accessoriesToClaimFor[i], _recipient);

            unchecked { i++; }
        }
    }

    event RewardsClaimed(uint indexed _miladyId, uint indexed _accessoryId, address indexed _recipient);

    function _claimRewardsForMiladyForAccessory(uint _miladyId, uint _accessoryId, address payable _recipient)
        internal
        // all calls to this must be nonreentrant
        // did not make this nonreentrant to prevent gas churn
    {
        RewardInfoForAccessory storage rewardInfo = rewardInfoForAccessory[_accessoryId];

        uint amountToSend = getAmountClaimableForMiladyAndAccessory(_miladyId, _accessoryId);

        rewardInfo.miladyRewardInfo[_miladyId].amountClaimed = rewardInfo.rewardsPerWearerAccrued;

        (bool success,) = _recipient.call{ value: amountToSend }("");
        require(success, "Transfer failed");

        emit RewardsClaimed(_miladyId, _accessoryId, _recipient);
    }

    function getAmountClaimableForMiladyAndAccessory(uint _miladyId, uint _accessoryId)
        public
        view
        returns (uint amountClaimable)
    {
        if (! rewardInfoForAccessory[_accessoryId].miladyRewardInfo[_miladyId].isRegistered) {
            return 0;
        }
        
        RewardInfoForAccessory storage rewardInfo = rewardInfoForAccessory[_accessoryId];
        
        amountClaimable = rewardInfo.rewardsPerWearerAccrued - rewardInfo.miladyRewardInfo[_miladyId].amountClaimed;
    }

    function getAmountClaimableForMiladyAndAccessories(uint _miladyId, uint[] memory _accessoryIds)
        public
        view
        returns (uint amountClaimable)
    {
        for (uint i=0; i<_accessoryIds.length;) {
            amountClaimable += getAmountClaimableForMiladyAndAccessory(_miladyId, _accessoryIds[i]);

            unchecked { i++; }
        }
    }
}