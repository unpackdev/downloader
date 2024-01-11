//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IERC721.sol";
import "./IERC1155.sol";

/**
 * @title NftOwner.sol
 * @author @lozzereth (www.allthingsweb3.com)
 * @notice Intended for off-chain computation. Returns the owned ERC1155/ERC721 tokens.
 *         Should work fine for 10K collections.
 */
contract NftOwner {
    /**
     * @notice Track ownership of ERC721
     * @param nftContract - ERC721 contract to query
     * @param account - Account to search
     * @return tokenIds
     */
    function erc721NftsOf(IERC721 nftContract, address account)
        external
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsLength = nftContract.balanceOf(account);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i; tokenIdsIdx != tokenIdsLength; ++i) {
                try nftContract.ownerOf(i) returns (address originalOwner) {
                    if (originalOwner == account) {
                        tokenIds[tokenIdsIdx++] = i;
                    }
                } catch (bytes memory) {}
            }
            return tokenIds;
        }
    }

    /**
     * @notice Track ownership of ERC1155 tokens
     * @param nftContract - ERC1155 contract to query
     * @param tokenIdList - Token ID list
     * @param account - Account to search
     * @return (tokenIds, balances)
     */
    function erc1155NftsOf(
        IERC1155 nftContract,
        uint256[] memory tokenIdList,
        address account
    ) external view returns (uint256[] memory, uint256[] memory) {
        unchecked {
            uint256 tokenIdsLength = tokenIdList.length;
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            uint256[] memory balances = new uint256[](tokenIdsLength);
            for (uint256 i; i != tokenIdsLength; ++i) {
                uint256 tokenId = tokenIdList[i];
                tokenIds[i] = tokenId;
                try nftContract.balanceOf(account, tokenId) returns (
                    uint256 balance
                ) {
                    balances[i] = balance;
                } catch (bytes memory) {
                    balances[i] = 0;
                }
            }
            return (tokenIds, balances);
        }
    }
}
