// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./IERC721A.sol";

/**
 * @notice Interface used by Issue 4 and Issue 56 contracts to expose burnBatch() function
 */
interface IBurnable is IERC721A {
    function burnBatch(uint256[] memory _tokenIds) external;
}
