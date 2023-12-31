// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IRecapitalizationModule {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Emitted when tokens are claimed.
     *  @param amountClaimed       The amount of tokens that were claimed.
     *  @param lastClaimedWindowId The identifier of the window during which the tokens were claimed.
     */
    event Claimed(uint256 amountClaimed, uint16 lastClaimedWindowId);

    /**
     *  @dev   Emitted when a new window is scheduled.
     *  @param newWindowId      The identifier of the new window that was scheduled.
     *  @param windowStart      The timestamp that marks when the new windows starts.
     *  @param issuanceRate     The issuance rate that will be applied to the new window.
     *  @param previousWindowId The identifier of the window that comes before the newly scheduled window (zero if there is none).
     */
    event WindowScheduled(uint16 indexed newWindowId, uint32 indexed windowStart, uint208 issuanceRate, uint16 previousWindowId);

    /**************************************************************************************************************************************/
    /*** Functions                                                                                                                      ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Claims tokens from the time of the last claim up until the current time.
     *  @return claimedAmount The amount of tokens that were claimed.
     */
    function claim() external returns (uint256 claimedAmount);

    /**
     *  @dev    Calculates how many tokens would be claimable from the time of the last claim up to the specified point in time.
     *  @return claimableAmount The amount of tokens that are claimable from the time of the last claim up to the specified time.
     */
    function claimable(uint32 to) external view returns (uint256 claimableAmount);

    /**
     *  @dev    Returns the amount of tokens issue per second for the current window.
     *  @return issuanceRate The amount of tokens issued per second for the current window.
     */
    function currentIssuanceRate() external view returns (uint208 issuanceRate);

    /**
     *  @dev    Returns the identifier of the current window.
     *  @return windowId The identifier of the current window.
     */
    function currentWindowId() external view returns (uint16 windowId);

    /**
     *  @dev    Returns the timestamp of the start of the current window.
     *  @return windowStart The timestamp of the start of the current window.
     */
    function currentWindowStart() external view returns (uint32 windowStart);

    /**
     *  @dev    Returns the timestamp of the last time tokens were claimed.
     *  @return lastClaimedTimestamp Timestamp of the last time tokens were claimed.
     */
    function lastClaimedTimestamp() external view returns (uint32 lastClaimedTimestamp);

    /**
     *  @dev    Returns the identifier of the window during which tokens were last claimed.
     *  @return lastClaimedWindowId Identifier of the window during which tokens were last claimed.
     */
    function lastClaimedWindowId() external view returns (uint16 lastClaimedWindowId);

    /**
     *  @dev    Returns the identifier that was assigned to the last scheduled window.
     *  @return lastScheduledWindowId Identifier that was assigned to the last scheduled window.
     */
    function lastScheduledWindowId() external view returns (uint16 lastScheduledWindowId);

    /**
     *  @dev   Schedules new windows that define when tokens will be issued.
     *  @param windowStarts  An array of window start times.
     *  @param issuanceRates An array of corresponding issuance rates.
     */
    function schedule(uint32[] memory windowStarts, uint208[] memory issuanceRates) external;

    /**
     *  @dev    Returns the address of the Maple treasury.
     *  @return token The address of the underlying token being managed.
     */
    function token() external view returns (address token);

    /**
     *  @dev    Returns thew window parameters given a window identifier.
     *  @param  windowId     The window identifier.
     *  @return nextWindowId The identifier of the window that takes effect after the provided one (zero if there is none).
     *  @return windowStart  The timestamp that marks when the window starts. It lasts until the start of the next window (or forever).
     *  @return issuanceRate The rate (per second) at which tokens will be issued (zero indicates no issuance).
     */
    function windows(uint16 windowId) external view returns (uint16 nextWindowId, uint32 windowStart, uint208 issuanceRate);

}
