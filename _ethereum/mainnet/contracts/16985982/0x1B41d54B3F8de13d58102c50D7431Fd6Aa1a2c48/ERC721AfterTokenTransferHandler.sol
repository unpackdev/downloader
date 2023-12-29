// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./IERC721AfterTokenTransferHandler.sol";

abstract contract ERC721AfterTokenTransferHandler is Context, Ownable, ERC721{
     /// @notice Reference to the handler contract for transfer hooks
    address public afterTokenTransferHandler;

    /**
     * Sets the after token transfer handler
     *
     * @param handlerAddress  Address to the transfer hook handler contract
     */
    function setAfterTokenTransferHandler(
        address handlerAddress
    ) external onlyOwner {
        afterTokenTransferHandler = handlerAddress;
    }

    /**
     * @notice Handles any after-transfer actions
     * @inheritdoc ERC721
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        if (afterTokenTransferHandler != address(0)) {
            IERC721AfterTokenTransferHandler handlerRef = IERC721AfterTokenTransferHandler(
                    afterTokenTransferHandler
                );
            handlerRef.afterTokenTransfer(
                address(this),
                _msgSender(),
                from,
                to,
                tokenId,
                batchSize
            );
        }

        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }
}
