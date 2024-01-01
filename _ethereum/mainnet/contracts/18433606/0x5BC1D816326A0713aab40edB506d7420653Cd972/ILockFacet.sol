// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IPermissionsFacet.sol";
import "./LpToken.sol";

interface ILockFacet {
    struct Storage {
        bool isLocked;
        string reason;
    }

    function setLock(bool lock, string memory reason) external;

    function getLock() external view returns (bool isLocked, string memory reason);

    function lockSelectors() external pure returns (bytes4[] memory selectors_);
}
