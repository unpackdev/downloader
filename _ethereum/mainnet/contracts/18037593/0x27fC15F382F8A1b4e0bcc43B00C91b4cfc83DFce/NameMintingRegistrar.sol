//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "./Controllable.sol";
import "./NameRegistry.sol";
import "./WhitelistRegistry.sol";
import "./NameRegistry.sol";
import "./ReservedRegistry.sol";
import "./NameWrapperDelegate.sol";
import "./DataTypes.sol";

/**
 * @title Namespace Mint Registrar
 * @author namespace.ninja
 * @notice Provides functionality for adding and updating domain names listings,
 * which will allow their subnames to be minted.
 */
contract NameMintingRegistrar is Controllable {
    struct ListingRegistration {
        bytes32 node;
        DomainListingDetails config;
        ReservedListing[] reservations;
        address[] whitelisted;
        uint8 whitelistType;
    }

    NameRegistry public nameRegistry;
    WhitelistRegistry public whitelistRegistry;
    ReservedRegistry public reservedRegistry;
    INameWrapper public nameWrapper;
    NameWrapperDelegate public nameWrapperDelegate;

    uint8[] public whitelistTypes;

    modifier nodeAuthorization(bytes32 node) {
        require(
            nameWrapper.canModifyName(node, msg.sender),
            "Only owner can list with registrar"
        );
        _;
    }

    constructor(
        NameRegistry _nameRegistry,
        WhitelistRegistry _whitelistRegistry,
        ReservedRegistry _reservedRegistry,
        INameWrapper _nameWrapper,
        NameWrapperDelegate _nameWrapperDelegate
    ) {
        nameRegistry = _nameRegistry;
        whitelistRegistry = _whitelistRegistry;
        reservedRegistry = _reservedRegistry;
        nameWrapper = _nameWrapper;
        nameWrapperDelegate = _nameWrapperDelegate;
        whitelistTypes.push(WHITELIST_CAN_BUY);
        whitelistTypes.push(WHITELIST_NO_FEES);
    }

    /**
     * @notice Updates existing listing
     * @param node The node for which to update the listing
     * @param newConfig New listing config
     * @param newReservations New reservation list
     * @param newWhitelist New whitelist
     * @param newWhitelistType New whitelist type
     */
    function updateNameListing(
        bytes32 node,
        DomainListingDetails calldata newConfig,
        ReservedListing[] calldata newReservations,
        address[] calldata newWhitelist,
        uint8 newWhitelistType
    ) external nodeAuthorization(node) {
        if (newConfig.listed) {
            nameRegistry.addListing(node, newConfig);
        }

        if (newReservations.length > 0) {
            reservedRegistry.update(node, newReservations);
        }

        if (newWhitelist.length > 0) {
            whitelistRegistry.update(node, newWhitelist);
        }

        if (_validWhitelist(newWhitelistType)) {
            whitelistRegistry.updateWhitelistType(node, newWhitelistType);
        }
    }

    function addNameListings(ListingRegistration[] calldata listings) external {
        for (uint i = 0; i < listings.length; i++) {
            addNameListing(
                listings[i].node,
                listings[i].config,
                listings[i].reservations,
                listings[i].whitelisted,
                listings[i].whitelistType
            );
        }
    }

    /**
     * @notice Creates a new listing record, and invalidates previous listings.
     * @param node Parent node with label reservations
     * @param config Configuration details
     * @param reservations Reservations details
     * @param whitelist Whitelisted addresses
     * @param whitelistType The type of whitelisting
     */
    function addNameListing(
        bytes32 node,
        DomainListingDetails calldata config,
        ReservedListing[] calldata reservations,
        address[] calldata whitelist,
        uint8 whitelistType
    ) public nodeAuthorization(node) {
        // CANNOT_UNWRAP needs to be burned to allow minting unraggable subnames
        nameWrapperDelegate.setFuses(node, uint16(CANNOT_UNWRAP));

        nameRegistry.addListing(node, config);

        if (reservations.length > 0) {
            reservedRegistry.reserve(node, reservations);
        } else if (reservedRegistry.getVersions(node).length > 0) {
            // update to empty reservation list if previous reservations exist
            // doing this will invalidate previous reservation, since this is a new listing
            reservedRegistry.update(node, reservations);
        }

        if (whitelist.length > 0) {
            require(
                _validWhitelist(whitelistType),
                "Unsupported whitelist type"
            );
            whitelistRegistry.addWhitelisting(node, whitelist, whitelistType);
        } else if (whitelistRegistry.getVersions(node).length > 0) {
            // update to empty reservation list if previous reservations exist
            // doing this will invalidate previous whitelist, since this is a new listing
            whitelistRegistry.update(node, whitelist);
            whitelistRegistry.updateWhitelistType(node, 0);
        }
    }

    function setNameRegistry(NameRegistry registry) external onlyController {
        nameRegistry = registry;
    }

    function setReservedRegistry(
        ReservedRegistry registry
    ) external onlyController {
        reservedRegistry = registry;
    }

    function setWhitelistRegistry(
        WhitelistRegistry registry
    ) external onlyController {
        whitelistRegistry = registry;
    }

    function addWhitelistType(uint8 wlType) external onlyController {
        whitelistTypes.push(wlType);
    }

    function setWhitelistTypes(uint8[] calldata types) external onlyController {
        whitelistTypes = types;
    }

    function setNameWrapper(address _nameWrapper) external onlyController {
        nameWrapper = INameWrapper(_nameWrapper);
    }

    function _validWhitelist(uint8 wlType) private view returns (bool) {
        for (uint8 i = 0; i < whitelistTypes.length; i++) {
            if (wlType == whitelistTypes[i]) return true;
        }
        return false;
    }
}
