// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./UUPSUpgradeable.sol";
import "./IDivinium.sol";
import "./DiviniumGenesisStaker.sol";
import "./DiviniumCreaturesStaker.sol";

contract DiviniumStaker is
    UUPSUpgradeable,
    DiviniumGenesisStaker,
    DiviniumCreaturesStaker
{
    string public constant VERSION = "1.0";
    bytes32 public constant SPENDER_ROLE = keccak256("SPENDER");

    IDivinium public deployedDivinium;

    // Yield tracking
    mapping(address => uint256) public addressToCumulatedRewards;

    /*
     * @dev Replaces the constructor for upgradeable contracts
     */
    function initialize(
        address deployedPowerAddress,
        address deployedGenesisAddress,
        address deployedGenesisSupplyAddress
    ) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __DiviniumGenesisStaker_init_unchained(
            deployedGenesisAddress,
            deployedGenesisSupplyAddress
        );
        deployedDivinium = IDivinium(deployedPowerAddress);
    }

    /**
     * @notice Claim $DVN from Genesis and Creatures
     * @param genesisIds Array containing all genesis ids. These are validated on chain
     * @dev genesisIds can be empty
     */
    function claim(uint256[] memory genesisIds) external {
        updateRewards(genesisIds);
        deployedDivinium.mint(
            msg.sender,
            addressToCumulatedRewards[msg.sender]
        );
        addressToCumulatedRewards[msg.sender] = 0;
    }

    /**
     * @notice Update $DNV from Genesis and Creatures
     * @param genesisIds Array containing all genesis ids. These are validated on chain
     * @dev genesisIds can be empty
     */
    function updateRewards(uint256[] memory genesisIds) public {
        // Only run genesis claim if needed
        if (genesisIds.length > 0) {
            addressToCumulatedRewards[msg.sender] += _claimGenesisRewards(
                genesisIds
            );
        }
        // Only run creature update if creature exists
        if (address(deployedCreature) != address(0)) {
            addressToCumulatedRewards[
                msg.sender
            ] += _claimCreaturesPendingRewards(msg.sender);
        }
    }

    /**
     * @notice Get pending Creatures reward for a user
     * @param user The user
     * @return The pending rewards for a user
     */
    function getCreaturesPendingRewards(address user)
        external
        view
        returns (uint256)
    {
        return
            _getCreaturesPendingRewards(user) + addressToCumulatedRewards[user];
    }

    /**
     * @notice Update the creatures rewards
     * @dev Called on transfers from Creatures and ascension
     * @param from The user who transfered
     * @param to The user who received
     * @param creatureId The ID of the creature to update
     * @param creatureType The type of the creature to update
     */
    function updateCreaturesReward(
        address from,
        address to,
        uint256 creatureId,
        CreaturesAscensionType creatureType
    ) external onlyRole(CREATURES_ROLE) {
        uint256 rewardsToAdd = _updateCreaturesRewardAndTimestamp(
            from,
            creatureId,
            creatureType
        );
        if (rewardsToAdd > 0) {
            addressToCumulatedRewards[from] += rewardsToAdd;
        }
        // No need to cumulate rewards here because they've been claimed already above
        _updateCreaturesRewardAndTimestamp(to, creatureId, creatureType);
    }

    /**
     * @notice Update the creatures rewards form ascension
     * @dev Called on transfers from Creatures and ascension
     * @param from The user who transfered
     * @param creatureId The ID of the creature to update
     * @param creatureType The type of the creature to update
     */
    function updateCreaturesRewardFromAscension(
        address from,
        uint256 creatureId,
        CreaturesAscensionType creatureType
    ) external onlyRole(CREATURES_ROLE) {
        addressToCumulatedRewards[from] += _updateCreaturesRewardAndTimestamp(
            from,
            creatureId,
            creatureType
        );
    }

    function spendUnclaimedRewards(address from, uint256 amount)
        external
        onlyRole(SPENDER_ROLE)
        returns (uint256 spent)
    {
        require(addressToCumulatedRewards[from] > 0, "No unclaimed fund");
        spent = amount;
        if (addressToCumulatedRewards[from] > amount) {
            addressToCumulatedRewards[from] -= amount;
        } else {
            spent = addressToCumulatedRewards[from];
            addressToCumulatedRewards[from] = 0;
        }
    }

    /**
     * UUPS upgradeable
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}
