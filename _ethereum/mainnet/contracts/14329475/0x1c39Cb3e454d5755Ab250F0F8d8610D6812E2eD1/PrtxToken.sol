// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./ERC20PausableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./UUPSUpgradeable.sol";

contract PrtxToken is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable, 
    PausableUpgradeable,
    ERC20PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant UPGRADE_LOCKER_ROLE = keccak256("UPGRADE_LOCKER_ROLE");
    bool private _upgradeLocked;

 
    event LockedUpgrades(address account);
    event UnlockedUpgrades(address account);

    modifier whenUpgradeNotLocked() {
        require(!upgradeLocked(), "upgrades unlocked");
        _;
    }

    modifier whenUpgradeLocked() {
        require(upgradeLocked(), "upgrades locked");
        _;
    }

    function initialize() initializer public {
        __ERC20_init("PRTX Token", "PRTX");
        __AccessControl_init_unchained();
        __ERC20Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); 
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(UPGRADE_LOCKER_ROLE, msg.sender);

        _upgradeLocked = false;
     }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function lockUpgrades() public whenUpgradeNotLocked onlyRole(UPGRADE_LOCKER_ROLE) {
        _upgradeLocked = true;
        emit LockedUpgrades(_msgSender());
    }

    function unlockUpgrades() public whenUpgradeLocked onlyRole(UPGRADE_LOCKER_ROLE) {
        _upgradeLocked = false;
        emit UnlockedUpgrades(_msgSender());
    }

    function upgradeLocked() public view virtual returns (bool) {
        return _upgradeLocked;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        // whenNotPaused
        override(ERC20Upgradeable, ERC20PausableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address) internal view override onlyRole(UPGRADER_ROLE) {
        require(!upgradeLocked(), "upgrade while upgrades locked");
    }
}