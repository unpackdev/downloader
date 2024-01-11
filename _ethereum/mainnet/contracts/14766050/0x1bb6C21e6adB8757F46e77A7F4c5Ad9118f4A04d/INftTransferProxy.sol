// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;
pragma abicoder v2;

import "./IERC721Upgradeable.sol";
import "./IERC1155Upgradeable.sol";

/**
 * @dev interface for transfering ERC721 adn ERC1155 tokens,
 * contracts that implement this interface must support
 * erc721safeTransferFrom and erc1155safeTransferFrom functions
 */
interface INftTransferProxy {
    function erc721safeTransferFrom(
        IERC721Upgradeable token,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function erc1155safeTransferFrom(
        IERC1155Upgradeable token,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;
}
