// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./Safe.sol";

/**
 * @title SafeAuthorized - Authorizes a `Safe` to perform actions to the current contract.
 * @author Richard Meissner - @rmeissner
 */
abstract contract SafeAuthorized {
    Safe public safe;

    function requireSafeCall() private view {
        require(msg.sender == address(safe), "GS031");
    }

    modifier authorized() {
        // Modifiers are copied around during compilation. This is a function call as it minimized the bytecode size
        requireSafeCall();
        _;
    }
}
