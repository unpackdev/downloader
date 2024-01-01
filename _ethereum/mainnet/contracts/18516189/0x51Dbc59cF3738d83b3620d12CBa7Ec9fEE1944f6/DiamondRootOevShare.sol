// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "./IBaseOracleAdapter.sol";
import "./IBaseController.sol";
import "./IOevShare.sol";

/**
 * @title DiamondRootOevShare contract to provide base functions that the three components of the OEV contract system
 * need. They are exposed here to simplify the inheritance structure of the OEV contract system and to enable easier
 * composability and extensibility at the integration layer, enabling arbitrary combinations of sources and destinations.
 */

abstract contract DiamondRootOevShare is IBaseController, IOevShare, IBaseOracleAdapter {
    /**
     * @notice Returns the latest data from the source.
     * @return answer The latest answer in 18 decimals.
     * @return updatedAt The timestamp of the answer.
     */
    function getLatestSourceData() public view virtual returns (int256, uint256);

    /**
     * @notice Tries getting latest data as of requested timestamp. If this is not possible, returns the earliest data
     * available past the requested timestamp within provided traversal limitations.
     * @param timestamp The timestamp to try getting latest data at.
     * @param maxTraversal The maximum number of rounds to traverse when looking for historical data.
     * @return answer The answer as of requested timestamp, or earliest available data if not available, in 18 decimals.
     * @return updatedAt The timestamp of the answer.
     */
    function tryLatestDataAt(uint256 timestamp, uint256 maxTraversal) public view virtual returns (int256, uint256);

    /**
     * @notice Returns the latest data from the source. Depending on when the OEVShare was last unlocked this might
     * return an slightly stale value to protect the OEV from being stolen by a front runner.
     * @return answer The latest answer in 18 decimals.
     * @return updatedAt The timestamp of the answer.
     */
    function internalLatestData() public view virtual returns (int256, uint256);

    /**
     * @notice Snapshot the current source data. Is a no-op if the source does not require snapshotting.
     */
    function snapshotData() public virtual;

    /**
     * @notice Permissioning function to control who can unlock the OEVShare.
     */
    function canUnlock(address caller, uint256 cachedLatestTimestamp) public view virtual returns (bool);

    /**
     * @notice Time window that bounds how long the permissioned actor has to call the unlockLatestValue function after
     * a new source update is posted. If the permissioned actor does not call unlockLatestValue within this window of a
     * new source price, the latest value will be made available to everyone without going through an MEV-Share auction.
     * @return lockWindow time in seconds.
     */
    function lockWindow() public view virtual returns (uint256);

    /**
     * @notice Max number of historical source updates to traverse when looking for a historic value in the past.
     * @return maxTraversal max number of historical source updates to traverse.
     */
    function maxTraversal() public view virtual returns (uint256);
}
