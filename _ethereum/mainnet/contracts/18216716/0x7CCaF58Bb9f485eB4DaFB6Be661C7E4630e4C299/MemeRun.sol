// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./ERC20PermitUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./TaxableUpgradeable.sol";

contract MemeRun is
    Initializable,
    ERC20Upgradeable,
    UUPSUpgradeable,
    PausableUpgradeable,
    ERC20BurnableUpgradeable,
    ERC20PermitUpgradeable,
    AccessControlUpgradeable,
    TaxableUpgradeable
{
    bytes32 public constant EXCLUDED_FROM_TAX = keccak256("EXCLUDED_FROM_TAX");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __ERC20_init("MemeRunWar", "RUN");
        __ERC20Permit_init("MemeRunWar");
        __ERC20Burnable_init();

        // Configure Tax
        __Taxable_init(
            true,
            100, // Default Tax 1%
            2500, // Max Tax 25%
            25, // Min Tax 0.25%
            0xBdD95a81dc2c47475f968C14D81297204612C728
        );

        // Config Roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(EXCLUDED_FROM_TAX, msg.sender);
        _grantRole(EXCLUDED_FROM_TAX, address(this));

        _mint(
            0xBdD95a81dc2c47475f968C14D81297204612C728,
            88_000_000 * (10**decimals())
        );

        // Paused on deploy
        _pause();
    }

    function transferOwnerShip(
        address newOwner
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
    }

    function renounceOwnership(
        bytes32 role,
        address callerConfirmation
    ) public {
        renounceRole(role, callerConfirmation);
    }

    function enableTrading() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function enableTax() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _taxon();
    }

    function disableTax() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _taxoff();
    }

    function updateTax(uint newtax) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _updatetax(newtax);
    }

    function excludeFromTax(
        address toBeExcluded
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(EXCLUDED_FROM_TAX, toBeExcluded);
    }

    function removeTaxImmunity(
        address toBeRemoved
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(EXCLUDED_FROM_TAX, toBeRemoved);
    }

    function updateTaxDestination(
        address destination
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _updatetaxdestination(destination);
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable) {
        // Should be not paused or is default admin
        require(!paused() || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Paused");

        if (
            (hasRole(EXCLUDED_FROM_TAX, from) ||
                hasRole(EXCLUDED_FROM_TAX, to) ||
                !taxed())
        ) {
            super._update(from, to, amount);
        } else {
            super._update(from, taxdestination(), (amount * thetax()) / 10000);
            super._update(from, to, (amount * (10000 - thetax())) / 10000);
        }
    }

    function batchTransfer(
        address[] calldata _addresses,
        uint256[] calldata _amounts
    ) external {
        // Should be not paused or is default admin
        require(!paused() || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Paused");
        for (uint8 i; i < _addresses.length; i++) {
            transfer(_addresses[i], _amounts[i]);
        }
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
