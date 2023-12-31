// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IPoolRegistry.sol";
import "./IQuoter.sol";

abstract contract QuoterStorageV1 is IQuoter {
    /**
     * @notice The pool registry contract
     */
    IPoolRegistry public poolRegistry;
}
