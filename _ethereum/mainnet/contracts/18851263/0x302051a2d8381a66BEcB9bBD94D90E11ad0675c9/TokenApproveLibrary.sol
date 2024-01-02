// Copyright 2020 Compound Labs, Inc.
// (c) 2023 Primex.finance
// SPDX-License-Identifier: BSD-3-Clause

// Modified version of approve logic that allows working with non-standart ERC-20 tokens
pragma solidity 0.8.18;

import "./Errors.sol";

import "./EIP20NonStandardInterface.sol";

library TokenApproveLibrary {
    function doApprove(address token, address spender, uint256 amount) public returns (uint256) {
        //reduce the addresses allowance to zero
        _doApprove(token, spender, 0);
        // set the new allowance
        _doApprove(token, spender, amount);
    }

    function _doApprove(address token, address spender, uint256 amount) private returns (uint256) {
        EIP20NonStandardInterface(token).approve(spender, amount);
        bool success;
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a complaint ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        _require(success, Errors.TOKEN_APPROVE_FAILED.selector);
    }
}
