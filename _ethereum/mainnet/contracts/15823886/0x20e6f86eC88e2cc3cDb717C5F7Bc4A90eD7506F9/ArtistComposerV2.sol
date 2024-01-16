// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.14;

/*
██   ██ ██       ██████   ██████  ██    ██ 
██  ██  ██      ██    ██ ██    ██ ██    ██ 
█████   ██      ██    ██ ██    ██ ██    ██ 
██  ██  ██      ██    ██ ██    ██  ██  ██  
██   ██ ███████  ██████   ██████    ████   
*/

import "./CountersUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./BeaconProxy.sol";
import "./AccessControlUpgradeable.sol";

contract ArtistComposerV2 is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _artistIds;

    // Address of the Beacon contract.
    address public beacon;
    // Role in charge of creating artists.
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    // ==================
    // EVENTS
    // ==================

    event ArtistCreated(uint256 indexed artistId, address indexed proxyAddress);

    // ==================
    // FUNCTIONS
    // ==================

    /// @notice Deploys an Artist contract and initializes it.
    /// @param name Name of the artist.
    /// @param symbol Symbol for the artist.
    /// @param admin Default admin of the contract.
    /// @param pauser Default pauser of the contract.
    /// @param minter Default minter of the contract.
    /// @param owner Default owner of the contract.
    /// @param baseUri Default base URI for metadata.
    /// @param forwarder Default forwarder of the contract.
    function createArtist(
        string calldata name,
        string calldata symbol,
        address admin,
        address pauser,
        address minter,
        address owner,
        string calldata baseUri,
        address forwarder
    ) external onlyRole(CREATOR_ROLE) {
        _artistIds.increment();

        BeaconProxy artist = new BeaconProxy(
            beacon,
            abi.encodeWithSelector(
                0x9c368117,
                name,
                symbol,
                admin,
                pauser,
                minter,
                owner,
                baseUri,
                forwarder
            )
        );

        emit ArtistCreated(_artistIds.current(), address(artist));
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}
