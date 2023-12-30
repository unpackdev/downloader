// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./MockProviderModuleGelatoUserProxyExecRevertCheckRevert.sol";
import "./IGelatoCore.sol";
import "./IGelatoUserProxy.sol";

contract MockProviderModuleGelatoUserProxyExecRevertCheckOk is
    MockProviderModuleGelatoUserProxyExecRevertCheckRevert
{
    function execRevertCheck(bytes memory)
        public
        pure
        virtual
        override
    {
        // do nothing
    }
}