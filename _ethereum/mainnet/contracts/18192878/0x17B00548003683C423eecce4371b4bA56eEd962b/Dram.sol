// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC20PermitUpgradeable.sol";
import "./DramAccessControl.sol";
import "./DramFreezable.sol";
import "./DramMintable.sol";

// Status: Under development, Not for public use
contract Dram is
    Initializable,
    DramAccessControl,
    DramFreezable,
    ERC20Upgradeable,
    DramMintable,
    PausableUpgradeable,
    ERC20PermitUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address admin,
        address roleManager,
        address supplyManager,
        address regulatoryManager
    ) public initializer {
        __ERC20_init("DRAM", "DRAM");
        __Pausable_init();
        __ERC20Permit_init("DRAM");
        __DramAccessControl_init(
            admin,
            roleManager,
            supplyManager,
            regulatoryManager
        );
        __DramMintable_init();
        __DramFreezable_init();
    }

    /**
     * @notice Pauses the smart contract.
     */
    function pause() external onlyRoleOrAdmin(REGULATORY_MANAGER_ROLE) {
        _pause();
    }

    /**
     * @notice Resumes the smart contract.
     */
    function unpause() external onlyRoleOrAdmin(REGULATORY_MANAGER_ROLE) {
        _unpause();
    }

    /**
     * @notice Freezes an account. A freezed account can't send any transaction related to
     * transferring tokens.
     * @dev Protected by onlyRoleOrAdmin, only admin and regulatory manager can call the function.
     * @param account Account to be freezed
     */
    function freeze(
        address account
    ) external onlyRoleOrAdmin(REGULATORY_MANAGER_ROLE) {
        _freeze(account);
    }

    /**
     * @notice Unfreezes an account.
     * @dev Protected by onlyRoleOrAdmin, only admin and regulatory manager can call the function.
     * @param account Account to be unfreezed
     */
    function unfreeze(
        address account
    ) external onlyRoleOrAdmin(REGULATORY_MANAGER_ROLE) {
        _unfreeze(account);
    }

    /**
     * @notice Increases the minting cap of an address by amount.
     * @dev Protected by onlyRoleOrAmin, so only admin and role manager can call the function.
     * @param operator Address that gets its minting cap gets increased
     * @param amount Value to add to the current minting cap
     */
    function increaseMintCap(
        address operator,
        uint256 amount
    ) external onlyRoleOrAdmin(ROLE_MANAGER_ROLE) {
        _increaseMintCap(operator, amount);
    }

    /**
     * @notice Decreases the minting cap of an address by amount.
     * @dev Protected by onlyRoleOrAmin, so only admin and role manager can call the function.
     * @param operator Address that gets its minting cap gets decreased
     * @param amount Value to subtract from the current minting cap
     */
    function decreaseMintCap(
        address operator,
        uint256 amount
    ) external onlyRoleOrAdmin(ROLE_MANAGER_ROLE) {
        _decreaseMintCap(operator, amount);
    }

    /**
     * @notice Sets the minting cap of an address and emits the associated event.
     * @dev Protected by onlyRoleOrAmin, so only admin and role manager can call the function.
     * @param operator Address that its minting cap will be changed
     * @param amount New minting cap
     */
    function setMintCap(
        address operator,
        uint256 amount
    ) external onlyRoleOrAdmin(ROLE_MANAGER_ROLE) {
        _setMintCap(operator, amount);
    }

    /**
     * @notice Mints tokens for an account.
     * @dev Protected by onlyRole, so only role manager can call the function.
     * @param to Account to send tokens to
     * @param amount Amount of the tokens to be minted
     */
    function mint(
        address to,
        uint256 amount
    ) external onlyRole(SUPPLY_MANAGER_ROLE) {
        _mint(to, amount);
    }

    /**
     * @notice Burns the caller tokens.
     * @dev Protected by onlyRole, so only role manager can call the function.
     * @param amount Amount of the tokens to be minted
     */
    function burn(uint256 amount) external onlyRole(SUPPLY_MANAGER_ROLE) {
        _burn(_msgSender(), amount);
    }

    /**
     * @notice Burns the tokens from an account.
     * @dev Protected by onlyRole, so only role manager can call the function.
     * @param account Address to burn tokens from
     * @param amount Amount of the tokens to be burned
     */
    function burnFrom(
        address account,
        uint256 amount
    ) external onlyRole(SUPPLY_MANAGER_ROLE) {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function _mint(
        address account,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, DramMintable) {
        super._mint(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused whenNotFreezed(from) whenNotFreezed(to) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
