// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./UpgradeableBeacon.sol";
import "./BeaconProxy.sol";
import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./IERC20.sol";

import "./IListing.sol";
import "./IRegistry.sol";

/// Top-Level Directory of Listings
/// @notice This contract allows you retrieve current listings, and if you have the CREATE_LISTING_ROLE role, create a new listing
contract Directory is Initializable, AccessControlUpgradeable {
    event NewListing(uint256 indexed id);

    IRegistry public registry;
    address public admin;

    IListing[] public listings;

    bytes32 public constant CREATE_LISTING_ROLE =
        keccak256("CREATE_LISTING_ROLE"); // Allowed to create listings

    function initialize(IRegistry _registry, address _admin) public {
        registry = _registry;
        admin = _admin;
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function numListings() public view returns (uint256) {
        return listings.length;
    }

    /// Create a new listing
    /// @notice Create a new listing. `softCap` and `hardCap` should take into account `fundingToken.decimals()`
    /// @param name Name of listing (maximum 32 bytes)
    /// @param tokenName Fractionalized ERC20 token name (maximum 32 bytes)
    /// @param tokenSymbol Fractionalized ERC20 token symbol (maximum 32 bytes)
    /// @param fundingToken Token (typically a stablecoin) used to fund listing
    /// @param softCap Minimum amount needed to succeed
    /// @param hardCap Maximum amount accepted
    /// @param fundingDurationSeconds Start to end of IRO in seconds
    /// @param expiryDurationSeconds Even with a successful IRO, unlock funds if IRO stalled after this number of seconds from start of IRO
    /// @custom:role-create-listing
    function newListing(
        bytes32 name,
        bytes32 tokenName,
        bytes32 tokenSymbol,
        IERC20 fundingToken,
        uint256 softCap,
        uint256 hardCap,
        uint256 fundingDurationSeconds,
        uint256 expiryDurationSeconds
    ) public onlyRole(CREATE_LISTING_ROLE) {
        BeaconProxy proxy = new BeaconProxy(
            address(registry.listingBeacon()),
            abi.encodeWithSignature(
                "initialize(address,address,bytes32,bytes32,bytes32,address,uint256,uint256,uint256,uint256)",
                registry,
                admin,
                name,
                tokenName,
                tokenSymbol,
                fundingToken,
                softCap,
                hardCap,
                fundingDurationSeconds,
                expiryDurationSeconds
            )
        );
        IListing listing = IListing(address(proxy));
        listings.push(listing);

        emit NewListing(listings.length - 1);
    }
}
