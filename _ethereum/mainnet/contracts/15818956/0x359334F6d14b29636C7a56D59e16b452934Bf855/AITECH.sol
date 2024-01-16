// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./ERC20Burnable.sol";

contract AITECH is ERC20, Ownable, AccessControl, ERC20Burnable {

    // Create a new role identifier for the burner role
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor() ERC20("AITECH", "AITECH") {

        // Mint 2 billion tokens
        _mint(msg.sender,2000000000*10**18);

        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Grant the burner role to a specific account
        _setupRole(BURNER_ROLE, msg.sender);
    }

    // This function overrides the burn() function from the ERC20Burnable extension
    // it can be called by the BURNER_ROLE
    function burn(uint256 amount) public override onlyRole(BURNER_ROLE){
        _burn(_msgSender(), amount);
    }

    // This function overrides the burnFrom() function from the ERC20Burnable extension
    // it can be called by the BURNER_ROLE
    function burnFrom(address account, uint256 amount) public override onlyRole(BURNER_ROLE){
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

}