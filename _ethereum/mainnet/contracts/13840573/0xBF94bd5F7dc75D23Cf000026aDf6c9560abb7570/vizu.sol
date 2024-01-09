// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20FlashMint.sol";

/// @custom:security-contact goatseface@protonmail.ch
contract VIZU is ERC20, ERC20Burnable, Pausable, AccessControl, ERC20Permit, ERC20FlashMint {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor() ERC20("VIZU", "VIZU") ERC20Permit("VIZU") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _mint(msg.sender, 21000000000000 * 10 ** decimals());
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
