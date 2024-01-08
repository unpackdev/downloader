// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";

interface IERC20Snapshot is IERC20, IERC20Metadata {
    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);

    function totalSupplyAt(uint256 snapshotId) external view returns (uint256);
}
