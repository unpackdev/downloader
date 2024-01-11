// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "./AccessControl.sol";

contract AccessControlMixin is AccessControl {
    string private _revertMsg;

    function _setupContractId(string memory contractId) internal {
        _revertMsg = string(abi.encodePacked(contractId, ": INSUFFICIENT_PERMISSIONS"));
        _setupRole(0, _msgSender());
    }

    modifier only(bytes32 role) {
        require(
            hasRole(role, _msgSender()),
            _revertMsg
        );
        _;
    }
}
