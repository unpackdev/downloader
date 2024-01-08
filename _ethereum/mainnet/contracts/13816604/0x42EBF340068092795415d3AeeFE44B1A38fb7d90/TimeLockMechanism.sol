// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0 < 0.9.0;

import "./Initializable.sol";

///@title TimeLockMechanism contains mechanism to lock functions for a specific period of time.
///@notice This contains modifier that can be used to lock functions for a certain period of time.
contract TimeLockMechanism is Initializable {
    uint256 public unlockTimestamp;

    event UpdateUnlockTimestamp(
        string description,
        address sender,
        uint256 newUnlockTimestamp
    );

    modifier timeLocked {
        require(
            block.timestamp >= unlockTimestamp,
            "Cannot access before token unlock"
        );
        _;
    }

    function _TimeLockMechanism_init(uint256 _unlockTimestamp)
        internal
        initializer
    {
        unlockTimestamp = _unlockTimestamp;
    }
}
