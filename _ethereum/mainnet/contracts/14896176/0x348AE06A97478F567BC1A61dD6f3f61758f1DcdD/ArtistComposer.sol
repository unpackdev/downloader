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
import "./UpgradeableBeacon.sol";
import "./UUPSUpgradeable.sol";
import "./BeaconProxy.sol";
import "./AccessControlUpgradeable.sol";
import "./Artist.sol";

contract ArtistComposer is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _artistIds;

    address public beacon;
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    event ArtistCreated(uint256 indexed artistId, address indexed proxyAddress);

    function initialize(address admin) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CREATOR_ROLE, msg.sender);
        UpgradeableBeacon _beacon = new UpgradeableBeacon(
            address(new Artist())
        );
        _beacon.transferOwnership(admin);
        beacon = address(_beacon);
    }

    function createArtist(Artist.InitializationData calldata initializationData)
        external
        onlyRole(CREATOR_ROLE)
    {
        _artistIds.increment();

        BeaconProxy artist = new BeaconProxy(beacon, "");
        bool success = Artist(address(artist)).initialize(initializationData);
        require(success, "ArtistComposer: Artist intialization failed");

        emit ArtistCreated(_artistIds.current(), address(artist));
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}
