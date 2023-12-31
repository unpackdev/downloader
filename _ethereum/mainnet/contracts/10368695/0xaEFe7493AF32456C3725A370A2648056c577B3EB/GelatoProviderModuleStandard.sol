// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./IGelatoProviderModule.sol";
import "./IGelatoCore.sol";

abstract contract GelatoProviderModuleStandard is IGelatoProviderModule {

    string internal constant OK = "OK";

    function isProvided(address, address, Task calldata)
        external
        view
        virtual
        override
        returns(string memory)
    {
        return OK;
    }

    /// @dev Overriding fns should revert with the revertMsg they detected on the userProxy
    function execRevertCheck(bytes calldata) external pure override virtual {
        // By default no reverts detected => do nothing
    }
}
