//Be name khoda
//Bime Abolfazl

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./dERC20.sol";

contract Registrar is dERC20, AccessControl {

	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
	bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");

	constructor(address admin, address synchronizer, address liquidator, string memory name, string memory symbol) dERC20(name, symbol) {
		_setupRole(DEFAULT_ADMIN_ROLE, admin);
		_setupRole(MINTER_ROLE, synchronizer);
		_setupRole(BURNER_ROLE, synchronizer);
		_setupRole(LIQUIDATOR_ROLE, liquidator);
	}

	function rename(string memory name, string memory symbol) external {
		require(hasRole(LIQUIDATOR_ROLE, msg.sender), "Caller is not a liquidator");
		_name = name;
		_symbol = symbol;
	}

	function mint(address to, uint256 amount) external {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(to, amount);
    }

	function burn(address from, uint256 amount) external {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        _burn(from, amount);
    }

}
//Dar panah khoda