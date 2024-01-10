// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IERC721Upgradeable.sol";
import "./IERC1155Upgradeable.sol";

interface INftTransferProxy {

    struct ERC721BundleItem {
        address tokenAddress;
        uint256[] tokenIds;
    }

    struct ERC721Item {
        address tokenAddress;
        uint256 tokenId;
    }

    function erc721safeTransferFrom(IERC721Upgradeable token, address from, address to, uint256 tokenId) external;

    function erc1155safeTransferFrom(IERC1155Upgradeable token, address from, address to, uint256 id, uint256 value, bytes calldata data) external;

    function erc721BundleSafeTransferFrom(ERC721BundleItem[] calldata erc721BundleItems, address from, address to) external; 

    function erc721BatchTransfer(ERC721Item[] calldata erc721Items, address to) external;
}
