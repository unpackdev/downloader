// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./Constants.sol";

contract LockAndMsgSender {
    error ContractLocked();

    address public lockedBy = address(1);

    modifier isNotLocked() {
        if (msg.sender != address(this)) {
            if (lockedBy != address(1)) revert ContractLocked();
            lockedBy = msg.sender;
            _;
            lockedBy = address(1);
        } else {
            _;
        }
    }

    /// @notice Calculates the recipient address for a command
    /// @param recipient The recipient or recipient-flag for the command
    /// @return output The resultant recipient for the command
    function map(address recipient) internal view returns (address) {
        if (recipient == Constants.MSG_SENDER) {
            return lockedBy;
        } else if (recipient == Constants.ADDRESS_THIS) {
            return address(this);
        } else {
            return recipient;
        }
    }
}