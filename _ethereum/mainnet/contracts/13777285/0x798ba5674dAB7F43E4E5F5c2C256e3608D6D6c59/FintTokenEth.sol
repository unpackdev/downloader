// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./UUPSUpgradeable.sol";

import "./ILiquidityRestrictor.sol";
import "./IAntisnipe.sol";

/// @custom:security-contact info@fintropy.io
contract FintToken is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _MintableAssetProxy) public initializer {
        __ERC20_init("Fintropy", "FINT");
        __ERC20Burnable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(PREDICATE_ROLE, _MintableAssetProxy);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function mint(address to, uint256 amount) public onlyRole(PREDICATE_ROLE) {
        _mint(to, amount);
    }
}
