// SPDX-License-Identifier: ISC

/**
 * 
 * Tokenine ERC20  Smartcontract
 * Contact: Dome C. <dome@tel.co.th>
 *          Tokenine Inc
 *          256 Chapman Road STE 105-4
 *          Newark New Castle
 *          Delaware(DE) 19702
 * 
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./ERC20.sol";
import "./Ownable.sol";

contract TokenineERC20 is ERC20, AccessControl, Ownable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(address _admin) ERC20("MVP Token", "MVP") {

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(MINTER_ROLE, _admin);

    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burnfrom(address from, uint256 amount) public onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    } 

}


