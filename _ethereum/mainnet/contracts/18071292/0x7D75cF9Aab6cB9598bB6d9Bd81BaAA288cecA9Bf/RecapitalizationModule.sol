// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./Interfaces.sol";

import "./IRecapitalizationModule.sol";

/*
 * The recapitalization module has a defined schedule of recapitalization that defines how new tokens will be issued over time.
 * Here is an example of an recapitalization schedule with three windows, the first two windows have a defined start and end.
 * The last window has a defined start but lasts indefinitely after it starts since it is the last window in the schedule.
 *
 * |--------|------|---------------->
 *     W1      W2          W3
 *
 * Each window has a separate issuance rate, which defines how many tokens per second will be issued during it's duration.
 * The issuance rate generally increases over time and is used to simulate the effect of compounding (for example on a yearly basis).
 * However the issuance rate can also be zero to indicate that no tokens should be issued.
 *
 * |----|==============|________|≡≡≡≡≡≡≡≡≡≡≡≡>
 *   W1        W2          W3         W4
 *
 * New windows can be scheduled, but only from the current time, retroactive scheduling is not possible.
 * When new windows are scheduled after the last window in the schedule starts, they will be appended to the schedule.
 *
 * |--------|----------|----------------->
 *     W1        W2         ^  W3
 *                          |
 * |--------|----------|----|------------>
 *     W1        W2      W3       W4
 *
 * When new windows are scheduled before any of the existing windows in the schedule start, they will replace them instead.
 *
 * |--------|----------|--------------->
 *     W1        W2 ^         W3
 *                  |
 * |--------|-------|------------------>
 *     W1        W2          W4
 */

contract RecapitalizationModule is IRecapitalizationModule {

    struct Window {
        uint16  nextWindowId;  // Identifier of the window that takes effect after this one (zero if there is none).
        uint32  windowStart;   // Timestamp that marks when the window starts. It lasts until the start of the next window (or forever).
        uint208 issuanceRate;  // Defines the amount of tokens per second that will be issued (zero indicates no issuance).
    }

    address public immutable token;

    uint16 public lastClaimedWindowId;
    uint16 public lastScheduledWindowId;

    uint32 public lastClaimedTimestamp;

    mapping(uint16 => Window) public windows;

    constructor(address token_) {
        token = token_;
    }

    /**************************************************************************************************************************************/
    /*** Modifiers                                                                                                                      ***/
    /**************************************************************************************************************************************/

    modifier onlyClaimer {
        require(IGlobalsLike(_globals()).isInstanceOf("RECAPITALIZATION_CLAIMER", msg.sender), "RM:NOT_CLAIMER");

        _;
    }

    modifier onlyGovernorAndScheduled(bytes32 functionId_) {
        IGlobalsLike globals_ = IGlobalsLike(_globals());

        require(msg.sender == globals_.governor(), "RM:NOT_GOVERNOR");

        bool isScheduledCall_ = globals_.isValidScheduledCall(msg.sender, address(this), functionId_, msg.data);

        require(isScheduledCall_, "RM:NOT_SCHEDULED");

        globals_.unscheduleCall(msg.sender, functionId_, msg.data);

        _;
    }

    /**************************************************************************************************************************************/
    /*** External Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function claim() external onlyClaimer returns (uint256 amountClaimed_) {

        (
            uint16  lastClaimableWindowId_,
            uint256 claimableAmount_
        ) = _claimable(lastClaimedWindowId, lastClaimedTimestamp, uint32(block.timestamp));

        require(claimableAmount_ > 0, "RM:C:ZERO_CLAIM");

        lastClaimedTimestamp = uint32(block.timestamp);
        lastClaimedWindowId  = lastClaimableWindowId_;

        emit Claimed(claimableAmount_, lastClaimableWindowId_);

        IMapleTokenLike(token).mint(IGlobalsLike(_globals()).mapleTreasury(), amountClaimed_ = claimableAmount_);
    }

    function schedule(uint32[] memory windowStarts_, uint208[] memory issuanceRates_) external onlyGovernorAndScheduled("RM:SCHEDULE") {
        _validateWindows(windowStarts_, issuanceRates_);

        // Find at which point in the linked list to insert the new windows.
        uint16 previousWindowId_ = _findInsertionPoint(windowStarts_[0]);
        uint16 newWindowId_      = lastScheduledWindowId + 1;

        require(windowStarts_[0] > windows[previousWindowId_].windowStart, "RM:S:DUPLICATE_WINDOW");

        windows[previousWindowId_].nextWindowId = newWindowId_;

        // Create all the new windows and link them up to each other.
        uint16 newWindowCount_ = uint16(windowStarts_.length);

        for (uint16 index_; index_ < newWindowCount_; ++index_) {
            windows[newWindowId_] = Window({
                nextWindowId: index_ < newWindowCount_ - 1 ? newWindowId_ + 1 : 0,
                windowStart:  windowStarts_[index_],
                issuanceRate: issuanceRates_[index_]
            });

            emit WindowScheduled(newWindowId_, windowStarts_[index_], issuanceRates_[index_], previousWindowId_);

            previousWindowId_ = newWindowId_;
            ++newWindowId_;
        }

        lastScheduledWindowId = newWindowId_ - 1;
    }

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function claimable(uint32 to_) external view returns (uint256 claimableAmount_) {
        uint32 lastClaimedTimestamp_ = lastClaimedTimestamp;

        if (to_ <= lastClaimedTimestamp_) return 0;

        ( , claimableAmount_ ) = _claimable(lastClaimedWindowId, lastClaimedTimestamp_, to_);
    }

    function currentIssuanceRate() external view returns (uint208 issuanceRate_) {
        issuanceRate_ = windows[currentWindowId()].issuanceRate;
    }

    function currentWindowId() public view returns (uint16 windowId_) {
        windowId_ = _findInsertionPoint(uint32(block.timestamp));

        uint16 nextWindowId_ = windows[windowId_].nextWindowId;

        if (block.timestamp == windows[nextWindowId_].windowStart) windowId_ = nextWindowId_;
    }

    function currentWindowStart() external view returns (uint32 windowStart_) {
        windowStart_ = windows[currentWindowId()].windowStart;
    }

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function _claimable(
        uint16 windowId_,
        uint32 from_,
        uint32 to_
    )
        internal view returns (
            uint16  lastClaimableWindowId_,
            uint256 claimableAmount_
        )
    {
        Window memory window_ = windows[windowId_];
        Window memory nextWindow_;

        while (from_ < to_) {
            bool isLastWindow_ = window_.nextWindowId == 0;

            if (!isLastWindow_) {
                nextWindow_ = windows[window_.nextWindowId];
            }

            bool isCurrentWindow_ = isLastWindow_ ? true : to_ < nextWindow_.windowStart;

            uint32 windowEnd_ = isCurrentWindow_ ? to_ : nextWindow_.windowStart;

            claimableAmount_ += window_.issuanceRate * (windowEnd_ - from_);

            if (isCurrentWindow_) break;

            from_     = windowEnd_;
            windowId_ = window_.nextWindowId;
            window_   = nextWindow_;
        }

        lastClaimableWindowId_ = windowId_;
    }

    function _findInsertionPoint(uint32 windowStart_) internal view returns (uint16 windowId_) {
        windowId_ = lastClaimedWindowId;

        Window memory window_ = windows[windowId_];

        while (true) {
            uint16 nextWindowId_ = window_.nextWindowId;

            if (nextWindowId_ == 0) break;

            window_ = windows[nextWindowId_];

            if (windowStart_ <= window_.windowStart) break;

            windowId_ = nextWindowId_;
        }
    }

    function _globals() internal view returns (address globals_) {
        globals_ = IMapleTokenLike(token).globals();
    }

    function _validateWindows(uint32[] memory windowStarts_, uint208[] memory issuanceRates_) internal view {
        require(windowStarts_.length == issuanceRates_.length, "RM:VW:LENGTH_MISMATCH");
        require(windowStarts_.length > 0,                      "RM:VW:EMPTY_ARRAYS");
        require(windowStarts_[0] >= block.timestamp,           "RM:VW:OUT_OF_DATE");

        for (uint256 index_ = 0; index_ < windowStarts_.length - 1; ++index_) {
            require(windowStarts_[index_] < windowStarts_[index_ + 1], "RM:VW:OUT_OF_ORDER");
        }
    }

}
