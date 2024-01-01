// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract SwanseaBay20 is ERC20, ERC20Burnable, AccessControl, Ownable {
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Constructor that gives specified ownerAddress all of existing tokens.
     */
    constructor(address ownerAddress) public ERC20("Swansea Bay 20", "BAY20") {
        _mint(ownerAddress, 125000 * 10 ** decimals());
        _grantRole(MINTER_ROLE, ownerAddress);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}