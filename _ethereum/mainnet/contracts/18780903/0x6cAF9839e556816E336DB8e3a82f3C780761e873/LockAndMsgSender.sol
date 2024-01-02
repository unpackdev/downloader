// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract LockAndMsgSender {
    error ContractLocked();

    address internal constant NOT_LOCKED_FLAG = address(0);
    address internal lockedBy;

    modifier isNotLocked() {
        if (msg.sender != address(this)) {
            if (lockedBy != NOT_LOCKED_FLAG) revert ContractLocked();
            lockedBy = msg.sender;
            _;
            lockedBy = NOT_LOCKED_FLAG;
        } else {
            _;
        }
    }
}
