// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./AccessControl.sol";
import "./ERC20Burnable.sol";
import "./ERC20Capped.sol";
import "./draft-ERC20Permit.sol";

/// @custom:security-contact kittyparty.eth
contract KittyPartyToken is AccessControl, ERC20Capped, ERC20Burnable, ERC20Permit  {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("Kitty Party Reward Token", "KPT") ERC20Capped(133978713 ether) ERC20Permit("Kitty Party Reward Token") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Capped) {
        super._mint(to, amount);
    }
}