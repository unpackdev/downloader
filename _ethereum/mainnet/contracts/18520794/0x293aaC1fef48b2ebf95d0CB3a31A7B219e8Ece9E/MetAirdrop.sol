// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Math.sol";
import "./RecurringAirdrop.sol";
import "./IESMET.sol";

/**
 * @title MET Airdrop contract
 */
contract MetAirdrop is RecurringAirdrop {
    using SafeERC20 for IERC20;
    using Math for uint256;

    IESMET public constant ESMET = IESMET(0xA28D70795a61Dc925D4c220762A4344803876bb8);
    IERC20 public constant MET = IERC20(0x2Ebd53d035150f328bd754D6DC66B99B0eDB89aa);

    /// @notice For how long `MET` tokens will be locked
    uint256 public lockPeriod = 7 days;

    constructor() RecurringAirdrop(MET) {}

    /**
     * @inheritdoc RecurringAirdrop
     * @dev Locks the `MET` into `esMET` on user's behalf.
     * The `lockPeriod` starts from the current merkle root update (i.e. `updatedAt`)
     */
    function _transferReward(address to_, uint256 amount_) internal override {
        uint256 _end = updatedAt + lockPeriod;

        if (_end < block.timestamp) {
            MET.safeTransfer(to_, amount_);
            return;
        }

        uint256 _min = ESMET.MINIMUM_LOCK_PERIOD() + 1;
        uint256 _max = ESMET.MAXIMUM_LOCK_PERIOD();

        // Ensures valid lock period
        uint256 _remainLockPeriod = Math.min(Math.max(_end - block.timestamp, _min), _max);

        token.safeApprove(address(ESMET), 0);
        token.safeApprove(address(ESMET), amount_);
        ESMET.lockFor(to_, amount_, _remainLockPeriod);
    }

    /**
     * @notice Update esMET lock period
     * @param lockPeriod_ The new value
     */
    function updateLockPeriod(uint256 lockPeriod_) public onlyGovernor {
        lockPeriod = lockPeriod_;
    }
}
