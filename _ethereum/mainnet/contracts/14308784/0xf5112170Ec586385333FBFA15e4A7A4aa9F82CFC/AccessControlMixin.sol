// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./AccessControlEnumerable.sol";

contract AccessControlMixin is AccessControlEnumerable {
    string private _revertMsg;

    function _setupContractId(string memory contractId) internal {
        _revertMsg = string(
            abi.encodePacked(contractId, ": INSUFFICIENT_PERMISSIONS")
        );
    }

    modifier only(bytes32 role) {
        require(hasRole(role, _msgSender()), _revertMsg);
        _;
    }
}
