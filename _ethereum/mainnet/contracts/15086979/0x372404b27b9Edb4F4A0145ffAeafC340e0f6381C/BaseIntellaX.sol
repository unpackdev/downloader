// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./draft-ERC20Permit.sol";

/**
 * Base ERC20 token contract
 *
 * support pausable functions (pause/unpause)
 * supports openzeppelin's role based AccessControl and ERC20Permit extension
 * admin - the address holds default admin permission and pauser role
 * name - the name of the token
 * symbol - the symbol of the token
 * decimal of the token is set to 18
 */
abstract contract BaseIntellaX is ERC20, Pausable, AccessControl, ERC20Permit {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(
        address admin,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) ERC20Permit(name) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "BaseIntellaX: token transfer while paused");
    }
}
