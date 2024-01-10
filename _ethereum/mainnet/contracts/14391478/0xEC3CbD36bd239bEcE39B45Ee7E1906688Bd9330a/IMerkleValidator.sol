// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./IERC721.sol";
import "./IERC1155.sol";

interface IMerkleValidator {
    // Function declarations based on https://etherscan.io/address/0xbaf2127b49fc93cbca6269fade0f7f31df4c88a7#code

    /// @dev Match an ERC721 order, ensuring that the supplied proof demonstrates inclusion of the tokenId in the associated merkle root.
    /// @param from The account to transfer the ERC721 token from — this token must first be approved on the seller's AuthenticatedProxy contract.
    /// @param to The account to transfer the ERC721 token to.
    /// @param token The ERC721 token to transfer.
    /// @param tokenId The ERC721 tokenId to transfer.
    /// @param root A merkle root derived from each valid tokenId — set to 0 to indicate a collection-level or tokenId-specific order.
    /// @param proof A proof that the supplied tokenId is contained within the associated merkle root. Must be length 0 if root is not set.
    /// @return A boolean indicating a successful match and transfer.
    function matchERC721UsingCriteria(
        address from,
        address to,
        IERC721 token,
        uint256 tokenId,
        bytes32 root,
        bytes32[] calldata proof
    ) external returns (bool);

    /// @dev Match an ERC1155 order, ensuring that the supplied proof demonstrates inclusion of the tokenId in the associated merkle root.
    /// @param from The account to transfer the ERC1155 token from — this token must first be approved on the seller's AuthenticatedProxy contract.
    /// @param to The account to transfer the ERC1155 token to.
    /// @param token The ERC1155 token to transfer.
    /// @param tokenId The ERC1155 tokenId to transfer.
    /// @param amount The amount of ERC1155 tokens with the given tokenId to transfer.
    /// @param root A merkle root derived from each valid tokenId — set to 0 to indicate a collection-level or tokenId-specific order.
    /// @param proof A proof that the supplied tokenId is contained within the associated merkle root. Must be length 0 if root is not set.
    /// @return A boolean indicating a successful match and transfer.
    function matchERC1155UsingCriteria(
        address from,
        address to,
        IERC1155 token,
        uint256 tokenId,
        uint256 amount,
        bytes32 root,
        bytes32[] calldata proof
    ) external returns (bool);
}
