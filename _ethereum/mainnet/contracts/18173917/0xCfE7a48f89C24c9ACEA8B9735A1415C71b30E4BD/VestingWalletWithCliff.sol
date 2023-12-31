// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
pragma solidity ^0.8.13;

import "./VestingWallet.sol";

/**
 * @title VestingWalletWithCliff
 * @dev This contract builds on OpenZeppelin's VestingWallet. See comments in VestingWallet for base details.
 *
 * This contract adds the following functionality:
 *   - Add a vesting cliff: `beneficiary` cannot claim any vested tokens until a cliff duration has elapsed
 */
abstract contract VestingWalletWithCliff is VestingWallet {

    error CurrentTimeIsBeforeCliff();

    uint64 private immutable _cliffDuration;

    /**
     * @dev Set the cliff and owner.
     * @dev Set the beneficiary, start timestamp, and vesting duration within VestingWallet base class.
     */
    constructor(uint64 cliffDurationSeconds) {
        _cliffDuration = cliffDurationSeconds;
    }

    /**
     * @dev Getter for the vesting cliff duration.
     */
    function cliffDuration() public view virtual returns (uint256) {
        return _cliffDuration;
    }

    /**
     * @dev Override of VestingWallet's `_vestingSchedule` to enforce releasing nothing until the cliff has passed.
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp)
        internal
        view
        virtual
        override
        returns (uint256)
    {
        if (uint64(block.timestamp) < (start() + cliffDuration())) {
            return 0;
        }
        return super._vestingSchedule(totalAllocation, timestamp);
    }
}
