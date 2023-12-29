// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "./UUPSUpgradeable.sol";
import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./IPrivateSale.sol";
import "./IPrivateSaleNft.sol";
import "./EnumerableMapUpgradeable.sol";


contract PrivateSaleManagement is IPrivateSale, Initializable, UUPSUpgradeable, AccessControlUpgradeable {
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;

    bytes32 public constant WHITELIST_MANAGER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant FUNDS_OWNER_ROLE = keccak256("FUNDS_OWNER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    EnumerableMapUpgradeable.AddressToUintMap internal _whitelist;
    IPrivateSaleNft internal _privateSaleNft;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address fundsOwner,
        address whitelistManager,
        address roleAdmin,
        address upgrader
    ) public initializer {
        __AccessControl_init();

        _grantRole(FUNDS_OWNER_ROLE, fundsOwner);
        _grantRole(WHITELIST_MANAGER_ROLE, whitelistManager);
        _grantRole(DEFAULT_ADMIN_ROLE, roleAdmin);
        _grantRole(UPGRADER_ROLE, upgrader);

    }

    /// @notice Add a list of addresses to the whitelist
    /// @param users The list of addresses to add
    /// @dev Only callable by addresses with the OWNER_ROLE
    function whitelistAdd(address[] memory users, uint256[] memory cap) public {
        if (!hasRole(WHITELIST_MANAGER_ROLE, msg.sender)) {
            revert NotOwner();
        }

        if (users.length != cap.length) {
            revert InvalidInput();
        }

        for (uint256 i = 0; i < users.length; i++) {
            _whitelist.set(users[i], cap[i]);
        }
    }

    /// @notice Remove a list of addresses from the whitelist
    /// @param users The list of addresses to remove
    /// @dev Only callable by addresses with the OWNER_ROLE
    function whitelistRemove(address[] memory users) public {
        if (!hasRole(WHITELIST_MANAGER_ROLE, msg.sender)) {
            revert NotOwner();
        }

        for (uint256 i = 0; i < users.length; i++) {
            _whitelist.remove(users[i]);
        }
    }

    function setUp(address privateSaleNftAddress) external {
        if (address(_privateSaleNft) != address(0)) {
            revert NftContractAddressSet();
        }
        _privateSaleNft = IPrivateSaleNft(privateSaleNftAddress);
    }

    function getWhitelistCount() external view returns (uint256) {
        return _whitelist.length();
    }

    function getWhitelistItem(address key) external view returns (bool, uint256) {
        return _whitelist.tryGet(key);
    }

    function getWhitelist() external view returns (WhitelistItem[] memory) {
        WhitelistItem[] memory whitelist = new WhitelistItem[](_whitelist.length());

        address[] memory keys = _whitelist.keys();

        for (uint256 i = 0; i < keys.length; i++) {
            whitelist[i] = WhitelistItem({
                user: keys[i],
                cap: _whitelist.get(keys[i])
            });
        }

        return whitelist;
    }

    function checkWhitelisted(address user) external view returns (bool) {
        return _whitelist.contains(user);
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    function _authorizeUpgrade(address) internal view override {
        if (!hasRole(UPGRADER_ROLE, msg.sender)) {
            revert NotUpgrader();
        }
    }
}
