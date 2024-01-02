// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./AccessControl.sol";

/// @custom:security-contact mechahubtrack@protonmail.com
contract MechaHubMinutes is ERC20, ERC20Burnable, AccessControl { 
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address defaultAdmin, address minter) ERC20("Mecha Hub Minutes", "MHMN") {
        _mint(msg.sender, 1 * 10 ** decimals());
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}