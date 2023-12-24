// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Radao.sol";

contract Share is Radao {
    bytes32 public constant SUPPLY_ROLE = keccak256("SUPPLY_ROLE");

    constructor(string memory name, string memory symbol, address admin) Radao(name, symbol, admin) {
        _grantRole(SUPPLY_ROLE, admin);
    }

    function mint(uint256 amount) public virtual {
        mintTo(msg.sender, amount);
    }

    function mintTo(address to, uint256 amount) public onlyRole(SUPPLY_ROLE) {
        _mint(to, amount);
    }

    function burn(uint256 amount) public virtual onlyRole(SUPPLY_ROLE) {
        _burn(msg.sender, amount);
    }

    function burnFrom(address from, uint256 amount) public virtual onlyRole(SUPPLY_ROLE) {
        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
    }
}
