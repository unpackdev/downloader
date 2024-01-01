// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC20PermitUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract LS_Token is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable {
	address public protocol;
	uint256[50] __gap;

	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() {
		_disableInitializers();
	}

	function initialize() public initializer {
		__ERC20_init("CAGA ETH", "cgETH");
		__ERC20Burnable_init();
		__Ownable_init();
		__ERC20Permit_init("CAGA ETH");
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
}
