// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC20PermitUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./i_governance.sol";

contract sGov_Token is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable {
	address public protocol;
	uint256[50] __gap;

	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() {
		_disableInitializers();
	}

	function initialize() public initializer {
		__ERC20_init("cgCAGA", "cgCAGA");
		__ERC20Burnable_init();
		__Ownable_init();
		__ERC20Permit_init("cgCAGA");
		__UUPSUpgradeable_init();
	}

	function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

	modifier onlyProtocol() {
		require(_msgSender() == protocol, "caller is not the protocol");
		_;
	}

	function set_protocol(address new_protocol) external onlyOwner {
		require(new_protocol != address(0), "address cannot be 0");

		protocol = new_protocol;
	}

	function mint(address to, uint256 amount) external onlyProtocol {
		super._mint(to, amount);
	}

	function burn(uint256 amount) public override onlyProtocol {
		super.burn(amount);
	}

	function burnFrom(address account, uint256 amount) public override onlyProtocol {
		_burn(account, amount);
	}

	function transfer(address to, uint256 amount) public override returns (bool) {
		i_governance(protocol).transfer_stake(_msgSender(), to, amount);
		_transfer(_msgSender(), to, amount);

		return true;
	}

	function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
		i_governance(protocol).transfer_stake(from, to, amount);
		_spendAllowance(from, _msgSender(), amount);
		_transfer(from, to, amount);

		return true;
	}
}
