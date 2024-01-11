
/*
CyberLionz Heat Reward Staking
https://cyberlionz.io
Twitter @CyberLionzNFT

Crafted with love by
Fueled on Bacon 
https://fueledonbacon.com
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./AccessControl.sol";
import "./ERC20.sol";

contract HeatToken is ERC20, AccessControl {
	bytes32 private _MINTER_ROLE = keccak256('MINTER_ROLE');

	function isAdmin(address account) public view virtual returns (bool) {
		return hasRole(DEFAULT_ADMIN_ROLE, account);
	}

	function isMinter(address account) public view virtual returns (bool) {
		return hasRole(_MINTER_ROLE, account);
	}

	modifier onlyAdmin() {
		require(isAdmin(msg.sender), 'Restricted to admins.');
		_;
	}
	modifier onlyMinters() {
		require(isMinter(msg.sender), 'Restricted to minters.');
		_;
	}

	constructor() ERC20("HeatToken", "HEAT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

	function setMinterRole(address minter) public onlyAdmin {
		_setupRole(_MINTER_ROLE, minter);
	}

	function mint(address to, uint256 amount) external onlyMinters {
		_mint(to, amount);
	}

	function burn(uint256 _amount) external {
		_burn(msg.sender, _amount);
	}
}

