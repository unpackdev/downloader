// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./GelatoProviderModuleStandard.sol";
import "./IGelatoCore.sol";

contract MockProviderModule is GelatoProviderModuleStandard {
    function execPayload(
        uint256,
        address,
        address,
        Task calldata _task,
        uint256
    ) external pure override returns (bytes memory payload, bool) {
        return (_task.actions[0].data, false);
    }
}
