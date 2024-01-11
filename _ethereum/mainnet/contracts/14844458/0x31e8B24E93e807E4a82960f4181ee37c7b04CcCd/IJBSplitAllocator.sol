// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IERC165.sol";
import "./JBSplitAllocationData.sol";

interface IJBSplitAllocator is IERC165 {
  function allocate(JBSplitAllocationData calldata _data) external payable;
}
