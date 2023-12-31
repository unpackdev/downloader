// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
 * @notice Interface used by AP Token
 */
interface IERC1155 {
    function privateMint(address _account, uint256 _amount) external;
}
