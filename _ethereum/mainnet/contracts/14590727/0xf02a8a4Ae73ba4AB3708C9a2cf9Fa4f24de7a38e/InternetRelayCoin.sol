// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

/**
 * @dev Brale's non-stablecoin contract.
 *
 * This contract is used directly for our non-stablecoin.
 */
/// @custom:security-contact security@brale.xyz
contract InternetRelayCoin is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    /**
     * @dev The contract version follows Semantic Versioning 2.0.0. MAJOR
     * versions contain breaking API changes, MINOR backwards compatible
     * functionality, and PATCH backwards compatible bug fixes.
     * For details, see https://semver.org/spec/v2.0.0.html.
     */
    string public constant CONTRACT_VERSION = "0.0.5";

    /**
     * @dev Role required for `mint`.
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Role required for `pause` and `unpause`.
     */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Role required to propose contract upgrades.
     */
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Configures roles for {automator_}, {defaultAdmin_}, and {upgrader_}.
     * The deployer's roles are revoked.
     *
     * Recommendations: {automator_} should use a multisig contract.
     * {defaultAdmin_} credentials should be stored offline.
     *
     * These values are immutable: they can only be set once during
     * construction.
     */
    function initialize(
        address automator_,
        address defaultAdmin_,
        address upgrader_
    ) external initializer {
        __ERC20_init("InternetRelayCoin", "IRC");
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(MINTER_ROLE, automator_);
        _grantRole(PAUSER_ROLE, automator_);

        _grantRole(UPGRADER_ROLE, upgrader_);

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin_);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev See {ERC20Upgradeable-_mint}.
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /**
     * @dev See {PausableUpgradeable-_pause}.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev See {PausableUpgradeable-_unpause}.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev See {ERC20Upgradeable-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev See {UUPSUpgradeable-_authorizeUpgrade}.
     */
    function _authorizeUpgrade(address)
        internal
        view
        override
        onlyRole(UPGRADER_ROLE)
    {}
}
