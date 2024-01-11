// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice Registry of Portals and Portal Factories

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;
import "./Ownable.sol";

contract PortalRegistryV1 is Ownable {
    // The multisig collector address
    address public collector;

    // The addresses of the registrars
    mapping(address => bool) public registrars;

    // Tracks existing portals for use as targets for calldata execution
    mapping(address => bool) public isPortal;

    // Tracks portal partners for revenue sharing
    mapping(address => bool) public partners;

    // Returns a portal address given a protocolId and portal type
    mapping(bytes32 => mapping(PortalType => Portal)) public getPortalById;

    // Tracks supported platforms
    bytes32[] internal supportedPlatforms;

    // Tracks the total number of portals
    uint256 public numPortals;

    // The type of Portal where 1 = Portal In and 2 = Portal Out
    enum PortalType {
        IN,
        OUT
    }

    struct Portal {
        address portal;
        PortalType portalType;
        bytes32 protocolId;
        uint96 version;
        bool active;
    }

    /// @notice Emitted when a new portal is created
    /// @param portal The newly created portal
    /// @param numPortals The total number of portals in existence
    event AddPortal(Portal portal, uint256 numPortals);

    /// @notice Emitted when a portal is updated
    /// @param portal The updated portal
    /// @param numPortals The total number of portals in existence
    event UpdatePortal(Portal portal, uint256 numPortals);

    /// @notice Emitted when a portal is removed
    /// @param portal The removed portal
    /// @param numPortals The total number of portals in existence
    event RemovePortal(Portal portal, uint256 numPortals);

    // Only registrars may add new portals to the registry
    modifier onlyRegistrars() {
        require(registrars[tx.origin], "Invalid origin");
        _;
    }

    constructor(address _collector, address _owner) {
        collector = _collector;
        registrars[msg.sender] = true;
        registrars[_owner] = true;
        transferOwnership(_owner);
    }

    /// @notice Adds new portals deployed by active registrars
    /// @param portal The address of the new portal
    /// @param portalType The type of portal - in or out
    /// @param protocolId The bytes32 representation of the name of the protocol
    function addPortal(
        address portal,
        PortalType portalType,
        bytes32 protocolId
    ) external onlyRegistrars {
        Portal storage existingPortal = getPortalById[protocolId][portalType];
        if (existingPortal.version != 0) {
            isPortal[existingPortal.portal] = false;
            existingPortal.portal = portal;
            existingPortal.version++;
            existingPortal.active = true;
            isPortal[portal] = true;
            emit UpdatePortal(existingPortal, numPortals);
        } else {
            Portal memory newPortal = Portal(
                portal,
                portalType,
                protocolId,
                1,
                true
            );
            getPortalById[protocolId][portalType] = newPortal;
            isPortal[portal] = true;
            supportedPlatforms.push(protocolId);
            emit AddPortal(newPortal, numPortals++);
        }
    }

    /// @notice Removes an inactivates existing portals
    /// @param portalType The type of portal - in or out
    /// @param protocolId The bytes32 representation of the name of the protocol
    function removePortal(bytes32 protocolId, PortalType portalType)
        external
        onlyOwner
    {
        Portal storage deletedPortal = getPortalById[protocolId][portalType];
        deletedPortal.active = false;
        isPortal[deletedPortal.portal] = false;

        emit RemovePortal(deletedPortal, numPortals);
    }

    /// @notice Returns an array of all of the portal objects by type
    /// @param portalType The type of portal - in or out
    function getAllPortals(PortalType portalType)
        external
        view
        returns (Portal[] memory)
    {
        Portal[] memory portals = new Portal[](numPortals);
        for (uint256 i = 0; i < supportedPlatforms.length; i++) {
            Portal memory portal = getPortalById[supportedPlatforms[i]][
                portalType
            ];

            portals[i] = portal;
        }
        return portals;
    }

    /// @notice Returns an array of all supported platforms
    function getSupportedPlatforms() external view returns (bytes32[] memory) {
        return supportedPlatforms;
    }

    /// @notice Updates a registrar's active status
    /// @param registrar The address of the registrar
    /// @param active The status of the registrar. Set true if
    /// the registrar is active, false otherwise
    function updateRegistrars(address registrar, bool active)
        external
        onlyOwner
    {
        registrars[registrar] = active;
    }

    /// @notice Updates a partner's active status
    /// @param partner The address of the registrar
    /// @param active The status of the partner. Set true if
    /// the partner is active, false otherwise
    function updatePartners(address partner, bool active) external onlyOwner {
        partners[partner] = active;
    }

    /// @notice Updates the collector's address
    /// @param _collector The address of the new collector
    function updateCollector(address _collector) external onlyOwner {
        collector = _collector;
    }

    /// @notice Helper function to convert a protocolId string into bytes32
    function stringToBytes32(string memory _string)
        external
        pure
        returns (bytes32 _bytes32String)
    {
        assembly {
            _bytes32String := mload(add(_string, 32))
        }
    }

    /// @notice Helper function to convert protocolId bytes32 into a string
    function bytes32ToString(bytes32 _bytes)
        external
        pure
        returns (string memory)
    {
        return string(abi.encode(_bytes));
    }
}
