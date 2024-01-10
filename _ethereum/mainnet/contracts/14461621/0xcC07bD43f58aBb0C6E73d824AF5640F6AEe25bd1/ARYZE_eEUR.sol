// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./eEUR_AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./WhitelistUpgradeable.sol";

/// @custom:security-contact admin@aryze.io
contract ARYZE_eEUR is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    WhitelistUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    address private multiSigTreasury;

    function initialize() public initializer {
        __ERC20_init("ARYZE eEUR", "eEUR");
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        multiSigTreasury = 0xaB23968d766D445BC9b370512d3085c345AcB235;
        _grantRole(ADMIN_eEUR, multiSigTreasury);
        _grantRole(PAUSER_ROLE, multiSigTreasury);
        _grantRole(MINTER_ROLE, multiSigTreasury);
        _grantRole(UPGRADER_ROLE, multiSigTreasury);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(_whitelist[to], "Address is not in whitelist");
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function addToWhitelist(address account)
        public
        onlyRole(ADMIN_eEUR)
    {
        _addToWhitelist(account);
    }

    function removeFromWhitelist(address account)
        public
        onlyRole(ADMIN_eEUR)
    {
        _removeFromWhitelist(account);
    }
}
