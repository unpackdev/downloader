// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./ISTKBrightToken.sol";

interface IAbstractCooldownStaking {

	function getWithdrawalInfo(address _userAddr) external view
	returns (
		uint256 _amount,
		uint256 _unlockPeriod,
		uint256 _availableFor
	);

}
