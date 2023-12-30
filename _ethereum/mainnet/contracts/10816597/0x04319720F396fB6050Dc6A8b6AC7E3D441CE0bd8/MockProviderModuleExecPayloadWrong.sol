// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./GelatoProviderModuleStandard.sol";
import "./IGelatoCore.sol";

contract MockProviderModuleExecPayloadWrong is GelatoProviderModuleStandard {
    // Incorrect execPayload func on purpose
    function execPayload(uint256, address, address, Task calldata, uint256)
        external
        view
        override
        returns(bytes memory, bool)
    {
        return (abi.encodeWithSelector(this.bogus.selector), false);
    }

    function bogus() external {}
}