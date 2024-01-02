// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title ArbitraryBasic
 * @author satoshi
 * @notice Exports a single function, `exec`, which is
 * used to dispatch additional arbitrary function calls
 * configured by the caller.
 */
contract ArbitraryBasic {

    /**
     * @param to The target address to call.
     * @param payload The data to send during the call.
     * @return data The returned data from the call.
     * 
     * Notice:
     * - Will revert if the call fails.
     * - Will propagate `msg.value` onto the call target.
     */
    function exec(address to, bytes calldata payload) external payable returns (bytes memory) {
        (bool success, bytes memory result) = to.call{value: msg.value}(payload);
        require(success);

        return result;
    }
    
}
