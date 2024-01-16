// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./IERC721ProjectApproveTransferManager.sol";

import "./ERC165.sol";

/**
 * Implement this if you want your manager to approve a transfer
 */
abstract contract ERC721ProjectApproveTransferManager is IERC721ProjectApproveTransferManager, ERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721ProjectApproveTransferManager).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
