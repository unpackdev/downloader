// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "./IERC721.sol";
import "./IERC1155.sol";

import "./OperatorRole.sol";

contract TransferProxy is OperatorRole {
    /**
     * @notice transfer ERC721 token 
     * @param token interface of ERC721 token
     * @param from sender address
     * @param to recipient address
     * @param tokenId ERC721 token ID
     */
    function erc721safeTransferFrom(
        IERC721 token,
        address from,
        address to,
        uint tokenId
    ) external onlyOperator {
        token.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @notice transfer ERC1155 token 
     * @param token interface of ERC1155 token
     * @param from sender address
     * @param to recipient address
     * @param tokenId ERC1155 token ID
     * @param value amount value to transfer
     * @param data callback data
     */
    function erc1155safeTransferFrom(
        IERC1155 token,
        address from,
        address to,
        uint tokenId,
        uint value,
        bytes calldata data
    ) external onlyOperator {
        token.safeTransferFrom(from, to, tokenId, value, data);
    }
}