// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC20Upgradeable.sol";

contract Muzi is ERC20Upgradeable {
	address public contractOwner;
	address public platformAdmin;
	mapping(address => bool) public internalPlatformAddresses;

	function initialize(uint256 initialSupply) public initializer {
		__ERC20_init("Muzi", "MZC");
		contractOwner = msg.sender;
		_mint(contractOwner, initialSupply);
	}

	function transfer(address to, uint256 amount) public virtual override returns (bool) {
		address from = _msgSender();
		if (isInternalPlatformAddress(to)) {
			_transfer(from, platformAdmin, amount);
			emit DepositToInternalPlatformAddress(from, to, amount);
			return true;
		}
		_transfer(from, to, amount);
		return true;
	}

	function burn(address from, uint256 amount) external {
		require(msg.sender == contractOwner, "only contractOwner");
		_burn(from, amount);
	}

	function registerPlatformAdmin(address addr) public {
		require(msg.sender == contractOwner, "only contractOwner");
		platformAdmin = addr;
	}

	function registerInternalPlatformAddress(address addr) public {
		require(msg.sender == platformAdmin, "only platformAdmin");
		internalPlatformAddresses[addr] = true;
	}

	function isInternalPlatformAddress(address addr) public view returns (bool) {
		return internalPlatformAddresses[addr];
	}

	event DepositToInternalPlatformAddress(address indexed from, address indexed to, uint256 amount);
}
