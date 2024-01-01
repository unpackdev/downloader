// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./BaseAccessControl.sol";
import "./BubbleReverts.sol";
import "./IBasePermissionedExecution.sol";

abstract contract BasePermissionedExecution is BaseAccessControl, IBasePermissionedExecution {
    function executeOperation(address target, bytes calldata payload) external payable override onlyClientAdmin {
        (bool _success, bytes memory _returnedData) = payable(target).call{ value: msg.value }(payload);
        if (!_success) {
            CallUtils.revertFromReturnedData(_returnedData);
        }
    }
}
