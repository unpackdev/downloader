// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./LibAsset.sol";

abstract contract ITransferExecutor {

    struct ERC721BundleItem {
        address tokenAddress;
        uint256[] tokenIds;
    }

    struct ERC721Item {
        address tokenAddress;
        uint256 tokenId;
    }

    //events
    event Transfer(LibAsset.Asset asset, address from, address to, bytes4 transferDirection, bytes4 transferType);

    function erc721BatchTransfer(ERC721Item[] calldata erc721Items, address to) external virtual;

    function transfer(
        LibAsset.Asset memory asset,
        address from,
        address to,
        bytes4 transferDirection,
        bytes4 transferType
    ) internal virtual;

}
