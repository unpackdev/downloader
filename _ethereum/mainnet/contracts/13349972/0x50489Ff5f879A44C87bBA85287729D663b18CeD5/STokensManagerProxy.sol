// SPDX-License-Identifier: MPL-2.0
pragma solidity 0.8.4;

import "./TransparentUpgradeableProxy.sol";

contract STokensManagerProxy is TransparentUpgradeableProxy {
	constructor(
		address _logic,
		address admin_,
		bytes memory _data
	) TransparentUpgradeableProxy(_logic, admin_, _data) {}
}
