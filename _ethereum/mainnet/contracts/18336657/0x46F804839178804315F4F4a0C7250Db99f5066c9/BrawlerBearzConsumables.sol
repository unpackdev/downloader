// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IBrawlerBearzDynamicItems.sol";
import "./IBrawlerBearzConsumables.sol";
import "./ERC2771ContextUpgradeable.sol";
import "./MinimalForwarderUpgradeable.sol";

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
 * @title BrawlerBearzConsumables
 * @author @scottybmitch
 **************************************************/

contract BrawlerBearzConsumables is
    IBrawlerBearzConsumables,
    Initializable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    ERC2771ContextUpgradeable,
    MinimalForwarderUpgradeable
{
    using StringsUpgradeable for uint256;

    bytes32 constant OWNER_ROLE = keccak256("OWNER_ROLE");

    // Consumable
    bytes32 constant CONSUMABLE_TYPE =
        keccak256(abi.encodePacked("CONSUMABLE"));

    /// @notice parent contract
    IERC721Upgradeable public parentContract;

    /// @notice Vendor contract
    IBrawlerBearzDynamicItems public vendorContract;

    // @notice Token id to array of consumables
    mapping(uint256 => Consumable[]) consumables;

    // @notice Token id to consumable id to consumed
    mapping(uint256 => mapping(uint256 => bool)) appliedConsumables;

    // @notice Token id to consumable id to consumed state
    mapping(uint256 => mapping(uint256 => bool)) consumableActiveState;

    // ========================================
    // Modifiers
    // ========================================

    modifier isTokenOwner(uint256 tokenId) {
        if (parentContract.ownerOf(tokenId) != _msgSender()) {
            revert InvalidOwner();
        }
        _;
    }

    modifier isItemTokenOwner(uint256 itemTokenId) {
        if (vendorContract.balanceOf(_msgSender(), itemTokenId) == 0) {
            revert InvalidOwner();
        }
        _;
    }

    modifier isConsumable(uint256 tokenId, uint256 itemTokenId) {
        IBrawlerBearzDynamicItems.CustomMetadata memory md = vendorContract
            .getMetadata(itemTokenId);
        if (
            CONSUMABLE_TYPE != keccak256(abi.encodePacked(md.usageDuration)) ||
            appliedConsumables[tokenId][itemTokenId]
        ) {
            revert InvalidItemType();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address _trustedForwarder
    ) ERC2771ContextUpgradeable(_trustedForwarder) {}

    function initialize(
        address _parentContractAddress,
        address _vendorContractAddress
    ) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(OWNER_ROLE, _msgSender());

        parentContract = IERC721Upgradeable(_parentContractAddress);
        vendorContract = IBrawlerBearzDynamicItems(_vendorContractAddress);
    }

    function toJSONAttribute(
        string memory key,
        string memory value
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{ "trait_type":"',
                    key,
                    '", "value": "',
                    value,
                    '"}'
                )
            );
    }

    function toJSONAttributeList(
        string[] memory attributes
    ) internal pure returns (string memory) {
        bytes memory attributeListBytes = "[";
        for (uint256 i = 0; i < attributes.length; i++) {
            attributeListBytes = abi.encodePacked(
                attributeListBytes,
                attributes[i],
                i != attributes.length - 1 ? "," : "]"
            );
        }
        return string(attributeListBytes);
    }

    /**
     * @notice Returns a json list of consumable properties
     * @param tokenId The token id of nft
     */
    function toConsumableProperties(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (consumables[tokenId].length == 0) {
            return "[]";
        }

        string[] memory dynamic = new string[](consumables[tokenId].length);

        Consumable memory current;

        for (uint256 i = 0; i < consumables[tokenId].length; i++) {
            current = consumables[tokenId][i];
            dynamic[i] = toJSONAttribute(
                current.name,
                consumableActiveState[tokenId][current.itemId]
                    ? "ACTIVE"
                    : "INACTIVE"
            );
        }
        return toJSONAttributeList(dynamic);
    }

    /**
     * @notice Sets the bearz contract
     * @dev only owner call this function
     * @param _parentContractAddress The new contract address
     */
    function setParentContract(
        address _parentContractAddress
    ) public override onlyRole(OWNER_ROLE) {
        parentContract = IERC721Upgradeable(_parentContractAddress);
    }

    /**
     * @notice Sets the bearz vendor item contract
     * @dev only owner call this function
     * @param _vendorContractAddress The new contract address
     */
    function setVendorContract(
        address _vendorContractAddress
    ) public override onlyRole(OWNER_ROLE) {
        vendorContract = IBrawlerBearzDynamicItems(_vendorContractAddress);
    }

    /**
     * @notice Returns the consumables for a given token id and item id
     * @param tokenId The token id of the bear
     * @param itemTokenId The token item in question
     */
    function isActiveConsumable(
        uint256 tokenId,
        uint256 itemTokenId
    ) external view override returns (bool) {
        return consumableActiveState[tokenId][itemTokenId];
    }

    /**
     * @notice Returns the consumables for a given token id, structured for off-chain usage
     * @param tokenId The token id of the bear
     */
    function getConsumables(
        uint256 tokenId
    ) external view override returns (bytes[] memory) {
        uint256 tokenConsumablesCount = consumables[tokenId].length;
        bytes[] memory all = new bytes[](tokenConsumablesCount);

        Consumable memory current;

        for (uint256 i = 0; i < tokenConsumablesCount; i++) {
            current = consumables[tokenId][i];
            all[i] = abi.encode(
                current.itemId,
                current.name,
                current.description,
                current.consumedAt,
                consumableActiveState[tokenId][current.itemId]
            );
        }

        return all;
    }

    /**
     * @notice Consumes the equipped items of a particular token id and item type
     * @dev only token owner call this function
     * @param tokenId The token id of the bear
     * @param itemTokenId The token id of the item
     * @param isEnabled The consumable state
     */
    function consume(
        uint256 tokenId,
        uint256 itemTokenId,
        bool isEnabled
    )
        public
        override
        isTokenOwner(tokenId)
        isItemTokenOwner(itemTokenId)
        nonReentrant
    {
        require(!appliedConsumables[tokenId][itemTokenId], "Already consumed");

        // Burn item
        vendorContract.burnItemForOwnerAddress(itemTokenId, 1, _msgSender());

        // Set consumed
        appliedConsumables[tokenId][itemTokenId] = true;

        // Add consumable w/ metadata
        IBrawlerBearzDynamicItems.CustomMetadata memory md = vendorContract
            .getMetadata(itemTokenId);

        consumables[tokenId].push(
            Consumable({
                itemId: itemTokenId,
                name: md.name,
                description: md.description,
                consumedAt: block.timestamp
            })
        );

        emit Consumed(tokenId, itemTokenId);

        // If enabled process activation
        if (isEnabled) {
            consumableActiveState[tokenId][itemTokenId] = true;
            emit Activated(tokenId, itemTokenId);
        }
    }

    /**
     * @notice Activates a particular consumble by id
     * @dev only token owner call this function
     * @param tokenId The token id of the bear
     * @param itemTokenId The token id of the item
     */
    function activate(
        uint256 tokenId,
        uint256 itemTokenId
    ) public override isTokenOwner(tokenId) nonReentrant {
        require(!consumableActiveState[tokenId][itemTokenId], "Already active");
        consumableActiveState[tokenId][itemTokenId] = true;
        emit Activated(tokenId, itemTokenId);
    }

    /**
     * @notice Deactivates a particular consumble by id
     * @dev only token owner call this function
     * @param tokenId The token id of the bear
     * @param itemTokenId The token id of the item
     */
    function deactivate(
        uint256 tokenId,
        uint256 itemTokenId
    ) public override isTokenOwner(tokenId) nonReentrant {
        require(consumableActiveState[tokenId][itemTokenId], "Not active");
        consumableActiveState[tokenId][itemTokenId] = false;
        emit Deactivated(tokenId, itemTokenId);
    }

    function _msgSender()
        internal
        view
        virtual
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (address)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}
