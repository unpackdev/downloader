// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library OperationsLib {
	function safeApprove(
		address token,
		address to,
		uint256 value
	) internal {
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
		require(success && (data.length == 0 || abi.decode(data, (bool))), "OperationsLib::safeApprove: approve failed");
	}
}