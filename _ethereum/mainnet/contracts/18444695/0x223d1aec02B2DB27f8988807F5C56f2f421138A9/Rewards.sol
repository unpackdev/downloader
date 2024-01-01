/* solhint-disable private-vars-leading-underscore */

pragma solidity 0.8.18;

import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./TBARegistry.sol";

/**
 * @title Rewards contract for distributing rewards based on accessory holdings.
 * @notice This contract handles registration, accrual, and claiming of rewards for Milady Avatars based on the accessories they are wearing.
 * @author Logan Brutsche
 */
contract Rewards is ReentrancyGuard {
    IERC721 public immutable miladysContract;
    address public immutable avatarContractAddress;

    /**
     * @notice Creates a new instance of the Rewards contract.
     * @param _avatarContractAddress The address of the Avatar contract.
     * @param _miladysContract The IERC721 contract of the Miladys.
     */
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

    /**
     * @notice Emitted when rewards are accrued for an accessory.
     * @param _accessoryId The ID of the accessory that accrued rewards.
     * @param _amount The amount of rewards accrued.
     */
    event RewardsAccrued(uint indexed _accessoryId, uint _amount);

    /**
     * @notice Allows adding rewards for an accessory.
     * @param _accessoryId The ID of the accessory.
     */
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

    /**
     * @notice Emitted when a Milady is registered for rewards for an accessory.
     * @param _miladyId The ID of the Milady being registered.
     * @param _accessoryId The ID of the accessory the Milady is being registered for.
     */
    event MiladyRegisteredForRewards(uint indexed _miladyId, uint indexed _accessoryId);

    /**
     * @notice Registers a Milady for rewards for a particular accessory.
     * @param _miladyId The ID of the Milady.
     * @param _accessoryId The ID of the accessory.
     * @dev Only callable by the avatarContractAddress. See `MiladyAvatar._equipAccessoryIfOwned`
     */
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

    /**
     * @notice Emitted when a Milady is deregistered for rewards for an accessory.
     * @param _miladyId The ID of the Milady being deregistered.
     * @param _accessoryId The ID of the accessory the Milady is being deregistered for.
     */
    event MiladyDeregisteredForRewards(uint indexed _miladyId, uint indexed _accessoryId);

    /**
     * @notice Deregisters a Milady for rewards for a particular accessory and claims any accrued rewards.
     * @param _miladyId The ID of the Milady.
     * @param _accessoryId The ID of the accessory.
     * @param _recipient The address to receive the claimed rewards.
     * @dev Only callable by the avatarContractAddress. See `MiladyAvatar._unequipAccessoryByTypeIfEquipped`
     */
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

    /**
     * @notice Allows a Milady owner to claim rewards for multiple accessories.
     * @param _miladyId The ID of the Milady.
     * @param _accessoriesToClaimFor The IDs of the accessories to claim rewards for.
     * @param _recipient The address to receive the claimed rewards.
     */
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

    /**
     * @notice Emitted when rewards are claimed for a Milady for an accessory.
     * @param _miladyId The Milady claiming rewards.
     * @param _accessoryId The accessory the Milady is claiming rewards for.
     * @param _recipient The address that received the claimed rewards.
     */
    event RewardsClaimed(uint indexed _miladyId, uint indexed _accessoryId, address indexed _recipient);

    /**
     * @notice Internal function to claim rewards for a Milady for a particular accessory.
     * @param _miladyId The ID of the Milady.
     * @param _accessoryId The ID of the accessory.
     * @param _recipient The address to receive the claimed rewards.
     */
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

    /**
     * @notice Computes the amount of rewards claimable for a Milady for a particular accessory.
     * @param _miladyId The ID of the Milady.
     * @param _accessoryId The ID of the accessory.
     * @return amountClaimable The amount of rewards claimable.
     */
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

    /**
     * @notice Computes the total amount of rewards claimable for a Milady for a list of accessories.
     * @param _miladyId The ID of the Milady.
     * @param _accessoryIds The IDs of the accessories.
     * @return amountClaimable The total amount of rewards claimable.
     */
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