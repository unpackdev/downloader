// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./ISimpleERC721Project.sol";

interface IERC721 {
    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev totalSupply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);
}

contract NFTsBatchReader {
    constructor() {}

    function balancesOf(IERC721 nft, address[] calldata owners) external view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](owners.length);
        for (uint256 i = 0; i < owners.length; i++) {
            balances[i] = nft.balanceOf(owners[i]);
        }
        return balances;
    }

    function tokenURIs(IERC721 nft, uint256[] calldata tokenIds) external view returns (string[] memory) {
        string[] memory res = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            try nft.tokenURI(tokenIds[i]) returns (string memory uri) {
                res[i] = uri;
            } catch Error(
                string memory /*reason*/
            ) {
                res[i] = "";
            }
        }
        return res;
    }

    function totalSupplies(IERC721[] calldata nfts) external view returns (uint256[] memory) {
        uint256[] memory supplies = new uint256[](nfts.length);
        for (uint256 i = 0; i < nfts.length; i++) {
            supplies[i] = nfts[i].totalSupply();
        }
        return supplies;
    }

    function totalSupplies1155(IERC1155 nft, uint256[] calldata tokenIds) external view returns (uint256[] memory) {
        uint256[] memory supplies = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            supplies[i] = nft.totalSupply(tokenIds[i]);
        }
        return supplies;
    }

    function uris(IERC1155 nft1155, uint256[] calldata tokenIds) external view returns (string[] memory) {
        string[] memory res = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            try nft1155.uri(tokenIds[i]) returns (string memory u) {
                res[i] = u;
            } catch Error(
                string memory /*reason*/
            ) {
                res[i] = "";
            }
        }
        return res;
    }
}
