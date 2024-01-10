// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./ICreatures.sol";
import "./ICreaturesTypes.sol";
import "./DiviniumConfig.sol";

abstract contract DiviniumCreaturesStaker is
    Initializable,
    AccessControlUpgradeable,
    ICreaturesTypes,
    DiviniumConfig
{
    bytes32 public constant CREATURES_ROLE = keccak256("CREATURES");

    struct CreatureUpdate {
        CreaturesAscensionType creatureType;
        uint256 lastUpdatedAt;
    }

    ICreatures public deployedCreature;

    // Yield tracking
    mapping(uint256 => CreatureUpdate) public creaturesIdToUpdate;

    event CreaturesDiviniumClaim(
        uint256 indexed creatureId,
        address indexed user
    );

    /**
     * @dev Chained initializer
     */
    function __DiviniumCreaturesStaker_init() internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __DiviniumCreaturesStaker_init_unchained();
    }

    /**
     * @dev Unchained initializer
     */
    function __DiviniumCreaturesStaker_init_unchained()
        internal
        onlyInitializing
    {}

    /**
     * @notice Sets the Creatures contract address
     * @dev only admin can run this function
     * @param creaturesAddress Address of the contract
     */
    function setCreaturesAddress(address creaturesAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        deployedCreature = ICreatures(creaturesAddress);
        grantRole(CREATURES_ROLE, creaturesAddress);
    }

    /**
     * @notice Get pending Creatures reward for a user
     * @param user The user
     * @return The pending rewards for a user
     */
    function _getCreaturesPendingRewards(address user)
        internal
        view
        returns (uint256)
    {
        uint256[] memory ids = deployedCreature.tokensForOwner(user);
        uint256 cumulRewards;

        // Loop through all indexes of owner,
        for (uint256 index = 0; index < ids.length; index++) {
            cumulRewards += _getCreaturesRewardForId(ids[index]);
        }
        return cumulRewards;
    }

    /**
     * @notice Gets the rate multiplier for a creature holder
     * @param creatureAscensionType The ascension type
     * @return rate multiplier for Creature collection
     */
    function _getCreaturesMultiplierForType(
        CreaturesAscensionType creatureAscensionType
    ) internal pure returns (uint256) {
        if (creatureAscensionType == CreaturesAscensionType.NONE) {
            return 1;
        } else if (
            creatureAscensionType == CreaturesAscensionType.ASCENDED_NONE
        ) {
            return 2;
        } else if (
            creatureAscensionType == CreaturesAscensionType.ASCENDED_SINGLE
        ) {
            return 3;
        } else if (
            creatureAscensionType == CreaturesAscensionType.ASCENDED_DOUBLE
        ) {
            return 4;
        }
        return 5;
    }

    /**
     * @notice Get Creatures reward for Id
     * @param creatureId id of the creature to get rewards from,
     * @return The reward for the type
     */
    function _getCreaturesRewardForId(uint256 creatureId)
        internal
        view
        returns (uint256)
    {
        require(
            creaturesIdToUpdate[creatureId].lastUpdatedAt != 0,
            "Invalid Creature"
        );
        CreatureUpdate memory creatureData = creaturesIdToUpdate[creatureId];
        return
            (BASE_RATE *
                _getCreaturesMultiplierForType(creatureData.creatureType) *
                (block.timestamp - creatureData.lastUpdatedAt)) / 1 days;
    }

    /**
     * @notice Claim the creatures pending reward of a user
     * @param user The user
     * @return The pending rewards for a user
     */
    function _claimCreaturesPendingRewards(address user)
        internal
        returns (uint256)
    {
        uint256[] memory ids = deployedCreature.tokensForOwner(user);
        uint256 cumulRewards;

        // Loop through all indexes of owner,
        for (uint256 index = 0; index < ids.length; index++) {
            uint256 currentId = ids[index];
            cumulRewards += _getCreaturesRewardForId(currentId);
            creaturesIdToUpdate[currentId] = CreatureUpdate(
                creaturesIdToUpdate[currentId].creatureType,
                block.timestamp
            );
        }
        return cumulRewards;
    }

    /**
     * @notice Update the last update timestamp for user
     * @param user The user to update
     * @param creatureId The ID of the creature to update
     * @param creatureType The type of the creature to update
     */
    function _updateCreaturesRewardAndTimestamp(
        address user,
        uint256 creatureId,
        CreaturesAscensionType creatureType
    ) internal returns (uint256 rewards) {
        rewards = 0;
        if (user != address(0)) {
            // We check if the last update is before the current timestamp
            // The creatures contract update the FROM then the TO
            // On a transfer, FROM will get the pending rewards and TO will not
            // because timestamp is set after. On mint, we set it on the TO.
            if (
                creaturesIdToUpdate[creatureId].lastUpdatedAt < block.timestamp
            ) {
                rewards = _getCreaturesRewardForId(creatureId);
                emit CreaturesDiviniumClaim(creatureId, user);
            }
        }
        if (creaturesIdToUpdate[creatureId].lastUpdatedAt < block.timestamp) {
            creaturesIdToUpdate[creatureId] = CreatureUpdate(
                creatureType,
                block.timestamp
            );
        }
    }
}
