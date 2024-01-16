// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./IERC165.sol";

/**
 * Implement this if you want your manager to approve a transfer
 */
interface IERC721ProjectApproveTransferManager is IERC165 {
    /**
     * @dev Set whether or not the project will check the manager for approval of token transfer
     */
    function setApproveTransfer(address project, bool enabled) external;

    /**
     * @dev Called by project contract to approve a transfer
     */
    function approveTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external returns (bool);
}
