// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

interface IBaseController {
    event LockWindowSet(uint256 indexed lockWindow);
    event MaxTraversalSet(uint256 indexed maxTraversal);
    event UnlockerSet(address indexed unlocker, bool indexed allowed);

    function canUnlock(address caller, uint256 cachedLatestTimestamp) external view returns (bool);
}
