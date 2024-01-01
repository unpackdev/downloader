// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ILockFacet.sol";

contract LockFacet is ILockFacet {
    bytes32 public constant STORAGE_POSITION = keccak256("mellow.contracts.lock.storage");

    function _contractStorage() internal pure returns (ILockFacet.Storage storage ds) {
        bytes32 position = STORAGE_POSITION;

        assembly {
            ds.slot := position
        }
    }

    function setLock(bool flag, string memory reason) external {
        IPermissionsFacet(address(this)).requirePermission(msg.sender, address(this), msg.sig);
        ILockFacet.Storage storage ds = _contractStorage();
        ds.isLocked = flag;
        ds.reason = reason;
    }

    function getLock() external view returns (bool isLocked, string memory reason) {
        ILockFacet.Storage storage ds = _contractStorage();
        isLocked = ds.isLocked;
        reason = ds.reason;
    }

    function lockSelectors() external pure returns (bytes4[] memory selectors_) {
        selectors_ = new bytes4[](3);
        selectors_[0] = ILockFacet.setLock.selector;
        selectors_[1] = ILockFacet.getLock.selector;
        selectors_[2] = ILockFacet.lockSelectors.selector;
    }
}
