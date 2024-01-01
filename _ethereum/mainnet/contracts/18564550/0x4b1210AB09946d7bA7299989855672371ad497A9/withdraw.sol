// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract Withdraw is Initializable, OwnableUpgradeable, UUPSUpgradeable {
	address public protocol;
	uint256[50] __gap;

	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() {
		_disableInitializers();
	}

	function initialize() public initializer {
		__Ownable_init();
		__UUPSUpgradeable_init();
	}

	function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

	receive() external payable {}

	modifier onlyProtocol() {
		require(_msgSender() == protocol, "caller is not the protocol");
		_;
	}

	function set_protocol(address new_protocol) external onlyOwner {
		require(new_protocol != address(0), "address cannot be 0");

		protocol = new_protocol;
	}

	function protocol_withdraw(uint256 amount) external onlyProtocol {
		if (amount > 0 && address(this).balance >= 0) {
			payable(protocol).transfer(amount);
		}
	}
}
