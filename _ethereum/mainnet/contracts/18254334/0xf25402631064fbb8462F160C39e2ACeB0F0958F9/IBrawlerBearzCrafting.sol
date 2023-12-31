// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBrawlerBearzCrafting {
    struct CraftConfig {
        bytes32 craftingHash;
        uint256 craftQuantity;
        uint256[] craftItemIds;
        uint256[] probabilities;
        uint256[] aliases;
    }

    struct CraftingRequest {
        address requester;
        bytes32 craftingHash;
    }

    struct TradeUpConfig {
        uint256 tradeUpId;
        uint256 requiredQuantity;
        uint256[] itemIds;
        uint256[] probabilities;
        uint256[] aliases;
    }

    struct TradeUpRequest {
        address requester;
        uint256 tradeUpId;
    }

    event CraftRandomnessRequest(
        uint256 indexed requestId,
        bytes32 craftingHash
    );

    event TradeUpRandomnessRequest(
        uint256 indexed requestId,
        uint256 tradeUpId
    );

    event CraftItemsDropped(
        uint256 indexed requestId,
        uint256 randomness,
        bytes32 craftingHash,
        address to,
        uint256[] itemIds
    );

    event TradeUpItemsDropped(
        uint256 indexed requestId,
        uint256 randomness,
        uint256 tradeUpId,
        address to,
        uint256[] itemIds
    );

    event SetCraftConfig(
        bytes32 craftingHash,
        uint256[] itemIds,
        uint256[] quantities
    );

    event SetTradeUpConfig(
        uint256 tradeUpId,
        uint256 requiredQuantity,
        uint256[] itemIds
    );

    function craft(
        bytes32 craftingHash,
        uint256[] memory itemIds,
        uint256[] memory quantities
    ) external;

    function tradeUp(
        uint256 tradeUpId,
        uint256[] calldata itemIds,
        uint256[] calldata quantities
    ) external;

    function configurationOf(bytes32[] memory craftingHashes)
        external
        view
        returns (bytes[] memory);

    function tradeUpConfigurationOf(uint256[] memory tradeUpIds)
        external
        view
        returns (bytes[] memory);

    function setModerator(address moderator, bool approved) external;

    function setCraftingConfig(
        CraftConfig calldata config,
        uint256[] calldata itemIds,
        uint256[] calldata quantities,
        bool addValid
    ) external;

    function setTradeUpConfig(TradeUpConfig calldata config, bool addValid)
        external;

    function setTradeUpItemIdValidation(
        uint256 tradeUpId,
        uint256[] calldata itemIds,
        bool isValid
    ) external;

    function setPaused(bool _isPaused) external;

    function setVendorContract(address _vendorContractAddress) external;

    function setUseVRF(bool _useVRF) external;
}
