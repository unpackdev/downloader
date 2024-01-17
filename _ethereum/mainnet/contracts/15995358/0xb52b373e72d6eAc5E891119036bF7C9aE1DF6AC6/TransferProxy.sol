// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IERC721.sol";
import "./IERC1155.sol";
import "./Pausable.sol";

import "./OwnableOperatorRole.sol";

contract TransferProxy is OwnableOperatorRole, Pausable {

    function erc721safeTransferFrom(IERC721 token, address from, address to, uint256 tokenId) external onlyOperator whenNotPaused {
        token.safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(IERC1155 token, address from, address to, uint256 id, uint256 value, bytes calldata data) external onlyOperator whenNotPaused {
        token.safeTransferFrom(from, to, id, value, data);
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }
}
