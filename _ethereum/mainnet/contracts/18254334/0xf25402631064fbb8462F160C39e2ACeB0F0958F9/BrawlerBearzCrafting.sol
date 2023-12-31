// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./AccessControl.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ERC2771Context.sol";
import "./NativeMetaTransaction.sol";
import "./IBrawlerBearzDynamicItems.sol";
import "./IBrawlerBearzCrafting.sol";

/*******************************************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|,|@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@|,*|&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%,**%@@@@@@@@%|******%&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##*****|||**,(%%%%%**|%@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@***,#%%%%**#&@@@@@#**,|@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@*,(@@@@@@@@@@**,(&@@@@#**%@@@@@@||(%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%|,****&@((@&***&@@@@@@%||||||||#%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&%#*****||||||**#%&@%%||||||||#@&%#(@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@&**,(&@@@@@%|||||*##&&&&##|||||(%@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@**,%@@@@@@@(|*|#%@@@@@@@@#||#%%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#||||#@@@@||*|%@@@@@@@@&|||%%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@#,,,,,,*|**||%|||||||###&@@@@@@@#|||#%@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&#||*|||||%%%@%%%#|||%@@@@@@@@&(|(%&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&&%%(||||@@@@@@&|||||(%&((||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%%(||||||||||#%#(|||||%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&%#######%%@@**||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
********************************************************************************/

/**************************************************
 * @title BrawlerBearzCrafting
 * @author @scottybmitch
 **************************************************/

contract BrawlerBearzCrafting is
    AccessControl,
    ERC2771Context,
    ReentrancyGuard,
    VRFConsumerBaseV2,
    NativeMetaTransaction,
    IBrawlerBearzCrafting
{
    bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 private constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    bytes32 public constant CRAFTING_TYPE =
        keccak256(abi.encodePacked("CRAFTING"));
    bytes32 public constant TRADE_UP_TYPE =
        keccak256(abi.encodePacked("TRADE_UP"));

    // Chainklink VRF V2
    VRFCoordinatorV2Interface immutable COORDINATOR;
    bytes32 public immutable keyHash;
    uint64 public immutable subscriptionId;
    uint16 constant numWords = 1;

    // Craft global properties
    bool public isPaused = true;
    bool public useVRF = false;

    /// @notice Nonce counter for pseudo requests
    uint256 private requestNonce;

    /// @dev requestId => type of request
    mapping(uint256 => bytes32) private requestIdToType;

    /// @dev requestId => drop config at time of request
    mapping(uint256 => CraftingRequest) private requestIdToRequestConfig;

    /// @dev crafting hash => Craft config
    mapping(bytes32 => CraftConfig) public craftingConfiguration;

    /// @dev tradeUpId => Trade Up config
    mapping(uint256 => TradeUpConfig) public tradeUpConfiguration;

    /// @dev requestId => drop config at time of request
    mapping(uint256 => TradeUpRequest) private requestIdToTradeUpRequestConfig;

    /// @dev tradeUpId => uint256 => bool
    mapping(uint256 => mapping(uint256 => bool))
        private tradeUpItemIdConfiguration;

    /// @notice trade up ids
    uint256[] public validTradeUpIds;

    /// @notice Crafting hashes
    bytes32[] public validCraftingHashes;

    /// @notice Vendor item contract
    IBrawlerBearzDynamicItems public vendorContract;

    constructor(
        address _vendorContractAddress,
        address _vrfV2Coordinator,
        address _trustedForwarder,
        bytes32 keyHash_,
        uint64 subscriptionId_
    ) VRFConsumerBaseV2(_vrfV2Coordinator) ERC2771Context(_trustedForwarder) {
        // Chainlink integration
        COORDINATOR = VRFCoordinatorV2Interface(_vrfV2Coordinator);
        keyHash = keyHash_;
        subscriptionId = subscriptionId_;

        // Item contract
        vendorContract = IBrawlerBearzDynamicItems(_vendorContractAddress);

        // Contract roles
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
        _setupRole(MODERATOR_ROLE, _msgSender());
    }

    /// @dev AJ-walker alias algo selection O(1), probabilities and alias computed off-chain and saved as configuration
    function _chooseItem(
        uint256 seed,
        uint256[] memory probabilities,
        uint256[] memory aliases
    ) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = seed & 0xFFFF;
            uint256 trait = traitSeed % probabilities.length;
            if (traitSeed >> 8 < probabilities[trait]) return trait;
            return aliases[trait];
        }
    }

    function _processCraftFulfillment(
        uint256 requestId,
        CraftConfig memory config,
        uint256 randomness,
        address requester
    ) internal {
        uint256[] memory ids = new uint256[](config.craftQuantity);
        uint256 seed;
        uint256 indexChosen;

        for (uint256 i = 0; i < config.craftQuantity; ) {
            seed = (randomness / ((i + 1) * 10)) % 2**32;

            indexChosen = _chooseItem(
                seed,
                config.probabilities,
                config.aliases
            );

            ids[i] = config.craftItemIds[indexChosen];

            unchecked {
                ++i;
            }
        }

        // Drop items from item contract to requester
        vendorContract.dropItems(requester, ids);

        emit CraftItemsDropped(
            requestId,
            randomness,
            config.craftingHash,
            requester,
            ids
        );
    }

    function _processTradeUpFulfillment(
        uint256 requestId,
        TradeUpConfig memory config,
        uint256 randomness,
        address requester
    ) internal {
        uint256[] memory ids = new uint256[](1);
        uint256 seed = randomness % 2**32;
        uint256 indexChosen = _chooseItem(
            seed,
            config.probabilities,
            config.aliases
        );

        ids[0] = config.itemIds[indexChosen];

        // Drop items from item contract to requester
        vendorContract.dropItems(requester, ids);

        emit TradeUpItemsDropped(
            requestId,
            randomness,
            config.tradeUpId,
            requester,
            ids
        );
    }

    /// @dev Handle setting request configuration for a given request id
    function _handleCraftRequest(
        uint256 requestId,
        bytes32 craftingHash,
        address requester
    ) internal {
        // Stores intermediate request state for later consumption
        requestIdToRequestConfig[requestId] = CraftingRequest({
            requester: requester,
            craftingHash: craftingHash
        });
        requestIdToType[requestId] = CRAFTING_TYPE;
    }

    /// @dev Handle setting request configuration for a given request id
    function _handleTradeUpRequest(
        uint256 requestId,
        uint256 tradeUpId,
        address requester
    ) internal {
        // Stores intermediate request state for later consumption
        requestIdToTradeUpRequestConfig[requestId] = TradeUpRequest({
            requester: requester,
            tradeUpId: tradeUpId
        });
        requestIdToType[requestId] = TRADE_UP_TYPE;
    }

    /// @dev Handle minting items related to a craft request
    function _handleCraftFulfillment(uint256 requestId, uint256 randomness)
        internal
    {
        CraftingRequest storage requestConfig = requestIdToRequestConfig[
            requestId
        ];
        _processCraftFulfillment(
            requestId,
            craftingConfiguration[requestConfig.craftingHash],
            randomness,
            requestConfig.requester
        );
    }

    /// @dev Handle minting items related to a trade up request
    function _handleTradeUpFulfillment(uint256 requestId, uint256 randomness)
        internal
    {
        TradeUpRequest storage requestConfig = requestIdToTradeUpRequestConfig[
            requestId
        ];
        _processTradeUpFulfillment(
            requestId,
            tradeUpConfiguration[requestConfig.tradeUpId],
            randomness,
            requestConfig.requester
        );
    }

    /// @notice Craft based on crafting hash
    function craft(
        bytes32 craftingHash,
        uint256[] calldata itemIds,
        uint256[] calldata quantities
    ) public nonReentrant {
        require(!isPaused, "!live");

        address requester = _msgSender();

        require(
            craftingHash == keccak256(abi.encodePacked(itemIds, quantities)),
            "!valid"
        );

        CraftConfig storage config = craftingConfiguration[craftingHash];

        require(uint256(config.craftingHash) != 0, "!exists");

        // Burn tokens for crafting exchange
        vendorContract.burnItemsForOwnerAddress(itemIds, quantities, requester);

        uint256 requestId;

        // Process crafting sequence thru chainlink vrf or pseudorandom randomness
        if (useVRF == true) {
            requestId = COORDINATOR.requestRandomWords(
                _keyHash(),
                _subscriptionId(),
                3,
                300000,
                numWords
            );

            _processCraftRandomnessRequest(requestId, craftingHash, requester);
            emit CraftRandomnessRequest(requestId, craftingHash);
        } else {
            // Bump internal request nonce for request id usage
            unchecked {
                requestNonce++;
            }

            _processCraftFulfillment(
                requestNonce,
                craftingConfiguration[craftingHash],
                pseudorandom(requestNonce),
                requester
            );
        }
    }

    /// @notice Trade up based on trade up id
    function tradeUp(
        uint256 tradeUpId,
        uint256[] calldata itemIds,
        uint256[] calldata quantities
    ) public nonReentrant {
        require(!isPaused, "!live");

        address requester = _msgSender();

        TradeUpConfig storage config = tradeUpConfiguration[tradeUpId];

        require(config.tradeUpId > 0 && config.itemIds.length > 0, "!exists");

        // Validate item ids are valid
        for (uint256 i; i < itemIds.length; ) {
            require(
                tradeUpItemIdConfiguration[tradeUpId][itemIds[i]],
                "!valid"
            );
            unchecked {
                ++i;
            }
        }

        uint256 totalQuantity;

        // Validate there is enough burnable assets
        for (uint256 j; j < quantities.length; ) {
            totalQuantity += quantities[j];
            unchecked {
                ++j;
            }
        }

        require(totalQuantity >= config.requiredQuantity, "!enough");

        // Burn tokens for trade up exchange
        vendorContract.burnItemsForOwnerAddress(itemIds, quantities, requester);

        uint256 requestId;

        // Process crafting sequence thru chainlink vrf or pseudorandom randomness
        if (useVRF == true) {
            requestId = COORDINATOR.requestRandomWords(
                _keyHash(),
                _subscriptionId(),
                3,
                300000,
                numWords
            );

            _processTradeUpRandomnessRequest(requestId, tradeUpId, requester);
            emit TradeUpRandomnessRequest(requestId, tradeUpId);
        } else {
            // Bump internal request nonce for request id usage
            unchecked {
                requestNonce++;
            }

            _processTradeUpFulfillment(
                requestNonce,
                tradeUpConfiguration[tradeUpId],
                pseudorandom(requestNonce),
                requester
            );
        }
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        bytes32 requestType = requestIdToType[requestId];
        if (requestType == CRAFTING_TYPE) {
            _processCraftRandomnessFulfillment(requestId, randomWords[0]);
        } else if (requestType == TRADE_UP_TYPE) {
            _processTradeUpRandomnessFulfillment(requestId, randomWords[0]);
        }
    }

    /// @dev Bastardized "randomness"
    function pseudorandom(uint256 nonce) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, block.prevrandao, nonce)
                )
            );
    }

    /**
     * @notice Returns the config information of specific set of crafting hashes
     * @param craftingHashes - hashes for crafting
     * @return bytes[]
     */
    function configurationOf(bytes32[] memory craftingHashes)
        external
        view
        returns (bytes[] memory)
    {
        bytes[] memory configs = new bytes[](craftingHashes.length);
        CraftConfig storage config;

        for (uint256 i; i < craftingHashes.length; i++) {
            bytes32 craftingHash = craftingHashes[i];
            config = craftingConfiguration[craftingHash];
            configs[i] = abi.encode(
                config.craftingHash,
                config.craftQuantity,
                config.craftItemIds
            );
        }
        return configs;
    }

    /**
     * @notice Returns the trade up config information for trade up ids
     * @param tradeUpIds - ids for trade ups
     * @return bytes[]
     */
    function tradeUpConfigurationOf(uint256[] memory tradeUpIds)
        external
        view
        returns (bytes[] memory)
    {
        bytes[] memory configs = new bytes[](tradeUpIds.length);
        TradeUpConfig storage config;
        for (uint256 i; i < tradeUpIds.length; i++) {
            uint256 tradeUpId = tradeUpIds[i];
            config = tradeUpConfiguration[tradeUpId];
            configs[i] = abi.encode(
                config.tradeUpId,
                config.requiredQuantity,
                config.itemIds
            );
        }
        return configs;
    }

    /**
     * Moderator functions
     */

    /**
     * @dev Set moderator address by owner
     * @param moderator address of moderator
     * @param approved true to add, false to remove
     */
    function setModerator(address moderator, bool approved)
        external
        onlyRole(OWNER_ROLE)
    {
        require(moderator != address(0), "!valid");

        if (approved) {
            _grantRole(MODERATOR_ROLE, moderator);
        } else {
            _revokeRole(MODERATOR_ROLE, moderator);
        }
    }

    /**
     * @notice Sets crafting configuration
     * @param config The config object representing the crafting exchange
     * @param itemIds item ids
     * @param quantities quantities for item ids
     * @param addValid Whether to set config validity or not
     */
    function setCraftingConfig(
        CraftConfig calldata config,
        uint256[] calldata itemIds,
        uint256[] calldata quantities,
        bool addValid
    ) public onlyRole(MODERATOR_ROLE) {
        require(
            config.craftingHash ==
                keccak256(abi.encodePacked(itemIds, quantities)),
            "Invalid crafting hash"
        );
        require(
            config.craftQuantity > 0,
            "Outcome quantity should be greater than 0"
        );
        require(
            config.probabilities.length == config.aliases.length,
            "Invalid config"
        );
        require(itemIds.length == quantities.length, "Invalid config");

        craftingConfiguration[config.craftingHash] = config;

        // Track valid crafting hashes
        if (addValid) {
            validCraftingHashes.push(config.craftingHash);
        }

        emit SetCraftConfig(config.craftingHash, itemIds, quantities);
    }

    /**
     * @notice Sets trade up configuration
     * @param config The config object representing the trade up exchange
     * @param addValid Whether to set config validity or not
     */
    function setTradeUpConfig(TradeUpConfig calldata config, bool addValid)
        public
        onlyRole(MODERATOR_ROLE)
    {
        require(config.tradeUpId > 0, "Trade up id must be greater than 0");
        require(
            config.requiredQuantity > 0,
            "Required quantity should be greater than 0"
        );
        require(
            config.probabilities.length == config.aliases.length &&
                config.probabilities.length == config.itemIds.length,
            "Invalid config"
        );

        tradeUpConfiguration[config.tradeUpId] = config;

        // Track valid trade ups
        if (addValid) {
            validTradeUpIds.push(config.tradeUpId);
        }

        emit SetTradeUpConfig(
            config.tradeUpId,
            config.requiredQuantity,
            config.itemIds
        );
    }

    /**
     * @notice Sets trade up item id validation
     * @param tradeUpId The trade up id config to set
     * @param itemIds The item ids to toggle
     * @param isValid The bool value to set for being valid
     */
    function setTradeUpItemIdValidation(
        uint256 tradeUpId,
        uint256[] calldata itemIds,
        bool isValid
    ) public onlyRole(MODERATOR_ROLE) {
        TradeUpConfig storage config = tradeUpConfiguration[tradeUpId];
        require(config.tradeUpId > 0 && config.requiredQuantity > 0, "!valid");
        uint256 itemId;
        for (uint256 i; i < itemIds.length; ) {
            itemId = itemIds[i];
            tradeUpItemIdConfiguration[tradeUpId][itemId] = isValid;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Sets the pause state
     * @param _isPaused The pause state
     */
    function setPaused(bool _isPaused) external onlyRole(MODERATOR_ROLE) {
        isPaused = _isPaused;
    }

    /**
     * Chainlink integration
     */

    /// @dev Handle randomness request
    function _processCraftRandomnessRequest(
        uint256 requestId,
        bytes32 craftingHash,
        address requester
    ) internal {
        _handleCraftRequest(requestId, craftingHash, requester);
    }

    /// @dev Handles randomness fulfillment
    function _processCraftRandomnessFulfillment(
        uint256 requestId,
        uint256 randomness
    ) internal {
        _handleCraftFulfillment(requestId, randomness);
    }

    /// @dev Handle randomness request
    function _processTradeUpRandomnessRequest(
        uint256 requestId,
        uint256 tradeUpId,
        address requester
    ) internal {
        _handleTradeUpRequest(requestId, tradeUpId, requester);
    }

    /// @dev Handles randomness fulfillment
    function _processTradeUpRandomnessFulfillment(
        uint256 requestId,
        uint256 randomness
    ) internal {
        _handleTradeUpFulfillment(requestId, randomness);
    }

    function _keyHash() internal view returns (bytes32) {
        return keyHash;
    }

    function _subscriptionId() internal view returns (uint64) {
        return subscriptionId;
    }

    /**
     * Owner functions
     */

    /// @dev Sets the contract address for the item to burn
    function setVendorContract(address _vendorContractAddress)
        external
        onlyRole(OWNER_ROLE)
    {
        vendorContract = IBrawlerBearzDynamicItems(_vendorContractAddress);
    }

    /// @dev Determines whether to use VRF or not
    function setUseVRF(bool _useVRF) external onlyRole(OWNER_ROLE) {
        useVRF = _useVRF;
    }

    /**
     * Native meta transactions
     */

    function _msgSender()
        internal
        view
        virtual
        override(ERC2771Context, Context)
        returns (address)
    {
        return ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ERC2771Context, Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }
}
