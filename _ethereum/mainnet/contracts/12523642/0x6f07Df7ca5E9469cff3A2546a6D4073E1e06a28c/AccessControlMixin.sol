pragma solidity 0.6.6;

import "./AccessControlUpgradeable.sol";

contract AccessControlMixin is AccessControlUpgradeable {
	string private _revertMsg;

	function _setupContractId(string memory contractId) internal {
		_revertMsg = string(abi.encodePacked(contractId, ": INSUFFICIENT_PERMISSIONS"));
	}

	modifier only(bytes32 role) {
		require(hasRole(role, _msgSender()), _revertMsg);
		_;
	}
}
