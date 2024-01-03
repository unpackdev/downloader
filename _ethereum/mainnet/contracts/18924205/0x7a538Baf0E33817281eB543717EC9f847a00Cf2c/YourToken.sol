// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./ERC20Permit.sol";
import "./AccessControl.sol";


/**
 * @title YOUR Token (YOUR)
 * @dev ERC20 Token with more benefits, including minting, burning,
 * access control, and pausable functionality.
 */
contract YourToken is ERC20, ERC20Burnable, ERC20Pausable, AccessControl, ERC20Permit {

    // Roles for access control
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Contract constructor.
     * @param defaultAdmin The default admin for the contract.
     * @param initialOwner The initial owner who receives the initial token supply.
     */
    constructor(address defaultAdmin, address initialOwner)
        ERC20("YOUR token", "YOUR")
        ERC20Permit("YOUR token")
    {
        // Validate that initialOwner and defaultAdmin are not the zero address
        require(initialOwner != address(0), "Initial owner cannot be the zero address");
        require(defaultAdmin != address(0), "Default admin cannot be the zero address");

        // Assign roles and mint initial token supply to the initial owner
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, defaultAdmin);
        _mint(initialOwner, 1000000000 * 10 ** decimals()); // Initial supply deposited to the address provided here
    }

    /**
     * @dev Pause token transfers.
     * Only callable by an address with the PAUSER_ROLE.
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause token transfers.
     * Only callable by an address with the PAUSER_ROLE.
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Mint new tokens and assign them to the specified address.
     * Only callable by an address with the MINTER_ROLE.
     * @param to The address to which new tokens will be minted.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /**
     * @dev Internal function to update token transfers.
     * Overrides functions from ERC20 and ERC20Pausable.
     */
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
    {
        super._update(from, to, value);
    }
}