// SPDX-License-Identifier: CHAMCHA
pragma solidity ^0.8.17;

import "./UUPSUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

contract Chax is
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable
{
    // mint manager
    bytes32 public constant MINT_ROLE =
        0x0000000000000000000000000000000000000000000000000000000000000001;
    // burn manager
    bytes32 private constant BURN_ROLE =
        0x0000000000000000000000000000000000000000000000000000000000000002;

    constructor() {
        _disableInitializers();
    }

    // ensures this can be called only once per *proxy* contract deployed
    function initialize() public initializer {
        __UUPSUpgradeable_init();
        _AccessControl_init();
        __ERC20_init("Chamcha Token", "CHAX");
    }

    function _AccessControl_init() internal onlyInitializing {
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MINT_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINT_ROLE, _msgSender());
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function mint(address to, uint256 amount) public onlyRole(MINT_ROLE) {
        _mint(to, amount);
    }
}
