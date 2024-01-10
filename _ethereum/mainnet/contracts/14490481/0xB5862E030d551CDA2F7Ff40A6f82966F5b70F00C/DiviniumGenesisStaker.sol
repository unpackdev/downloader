// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Initializable.sol";
import "./IGenesisTypes.sol";
import "./IGenesisSupply.sol";
import "./IGenesis.sol";
import "./DiviniumConfig.sol";

abstract contract DiviniumGenesisStaker is
    Initializable,
    IGenesisTypes,
    DiviniumConfig
{
    uint256 public constant GENESIS_START_TIMESTAMP = 1641627068;

    struct GenesisUpdate {
        TokenType genesisType;
        uint256 lastUpdatedAt;
    }

    IGenesis public deployedGenesis;
    IGenesisSupply public deployedGenesisSupply;

    // Yield tracking
    mapping(uint256 => GenesisUpdate) public genesisIdToUpdate;

    event GenesisDiviniumClaim(uint256 indexed tokenId, address indexed user);

    /**
     * @dev Chained initializer
     */
    function __DiviniumGenesisStaker_init(
        address deployedGenesisAddress,
        address deployedGenesisSupplyAddress
    ) internal onlyInitializing {
        __DiviniumGenesisStaker_init_unchained(
            deployedGenesisAddress,
            deployedGenesisSupplyAddress
        );
    }

    /**
     * @dev Unchained initializer
     */
    function __DiviniumGenesisStaker_init_unchained(
        address deployedGenesisAddress,
        address deployedGenesisSupplyAddress
    ) internal onlyInitializing {
        deployedGenesis = IGenesis(deployedGenesisAddress);
        deployedGenesisSupply = IGenesisSupply(deployedGenesisSupplyAddress);
    }

    /**
     * @notice Gets the rate multiplier for a genesis holder
     * @param genesisType The type of genesis
     * @return rate multiplier for Genesis collection
     */
    function _getGenesisMultiplierForType(TokenType genesisType)
        internal
        pure
        returns (uint256)
    {
        require(genesisType != TokenType.NONE, "Invalid Type");
        if (genesisType == TokenType.GOD) {
            return 16;
        } else if (genesisType == TokenType.DEMI_GOD) {
            return 8;
        }
        return 6;
    }

    /**
     * @notice Get Genesis reward for specific ID
     * @param id The ID to check reward
     * @param genesisType The type of genesis
     * @return The reward for an ID
     */
    function _getGenesisRewardForId(uint256 id, TokenType genesisType)
        internal
        view
        returns (uint256)
    {
        uint256 startTimestamp = genesisIdToUpdate[id].lastUpdatedAt;
        if (startTimestamp == 0) {
            startTimestamp = GENESIS_START_TIMESTAMP;
        }
        return
            (BASE_RATE *
                _getGenesisMultiplierForType(genesisType) *
                (block.timestamp - startTimestamp)) / 1 days;
    }

    /**
     * @notice Claim $DVN from Genesis
     * @param genesisIds Array containing all genesis ids. These are validated on chain
     * @return The total Genesis $DVN rewards for ids
     */
    function _claimGenesisRewards(uint256[] memory genesisIds)
        internal
        returns (uint256)
    {
        uint256 totalRewards;
        uint256 totalIds = genesisIds.length;
        TokenTraits memory traits;
        for (uint256 index = 0; index < totalIds; index++) {
            require(
                deployedGenesis.ownerOf(genesisIds[index]) == msg.sender,
                "Not owner of Genesis"
            );
            traits = deployedGenesisSupply.getMetadataForTokenId(
                genesisIds[index]
            );
            totalRewards += _getGenesisRewardForId(
                genesisIds[index],
                traits.tokenType
            );
            genesisIdToUpdate[genesisIds[index]] = GenesisUpdate(
                traits.tokenType,
                block.timestamp
            );
            emit GenesisDiviniumClaim(genesisIds[index], msg.sender);
        }
        return totalRewards;
    }
}
