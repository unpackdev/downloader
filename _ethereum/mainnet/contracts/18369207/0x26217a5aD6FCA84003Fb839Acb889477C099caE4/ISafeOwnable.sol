// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./IOwnable.sol";
import "./ISafeOwnableInternal.sol";

interface ISafeOwnable is ISafeOwnableInternal, IOwnable {
    /**
     * @notice get the nominated owner who has permission to call acceptOwnership
     */
    function nomineeOwner() external view returns (address);

    /**
     * @notice accept transfer of contract ownership
     */
    function acceptOwnership() external;
}
