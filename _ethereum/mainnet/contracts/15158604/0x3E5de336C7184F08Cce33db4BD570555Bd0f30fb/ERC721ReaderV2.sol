// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.9;
pragma abicoder v2;

import "./IERC721.sol";
import "./IERC721Enumerable.sol";

contract ERC721ReaderV2 {
    struct CollectionSupply {
        address tokenAddress;
        uint256 supply;
    }

    struct OwnerTokenCount {
        address tokenAddress;
        uint256 count;
    }

    struct TokenOwnerInput {
        address tokenAddress;
        uint256 tokenId;
    }

    struct TokenOwner {
        address tokenAddress;
        uint256 tokenId;
        address owner;
        bool exists;
    }

    struct TokenId {
        uint256 tokenId;
        bool exists;
    }

    function collectionSupplys(address[] calldata tokenAddresses)
        external
        view
        returns (CollectionSupply[] memory supplys)
    {
        supplys = new CollectionSupply[](tokenAddresses.length);

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            address tokenAddress = tokenAddresses[i];
            uint256 supply = IERC721Enumerable(tokenAddress).totalSupply();

            supplys[i] = CollectionSupply(tokenAddress, supply);
        }
    }

    function ownerTokenCounts(address[] calldata tokenAddresses, address owner)
        external
        view
        returns (OwnerTokenCount[] memory tokenCounts)
    {
        tokenCounts = new OwnerTokenCount[](tokenAddresses.length);

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            address tokenAddress = tokenAddresses[i];
            uint256 count = IERC721(tokenAddress).balanceOf(owner);

            tokenCounts[i] = OwnerTokenCount(tokenAddress, count);
        }
    }

    function _tokenOfOwnerByIndex(
        address tokenAddress,
        address owner,
        uint256 index
    ) internal view returns (TokenId memory) {
        try
            IERC721Enumerable(tokenAddress).tokenOfOwnerByIndex(owner, index)
        returns (uint256 tokenId) {
            return TokenId(tokenId, true);
        } catch {
            return TokenId(0, false);
        }
    }

    function ownerTokenIds(
        address tokenAddress,
        address owner,
        uint256 fromIndex,
        uint256 size
    ) external view returns (TokenId[] memory tokenIds) {
        uint256 count = IERC721(tokenAddress).balanceOf(owner);
        uint256 length = size;

        if (length > (count - fromIndex)) {
            length = count - fromIndex;
        }

        tokenIds = new TokenId[](length);

        for (uint256 i = 0; i < length; i++) {
            tokenIds[i] = _tokenOfOwnerByIndex(
                tokenAddress,
                owner,
                fromIndex + i
            );
        }
    }

    function _tokenByIndex(address tokenAddress, uint256 index)
        internal
        view
        returns (TokenId memory)
    {
        try IERC721Enumerable(tokenAddress).tokenByIndex(index) returns (
            uint256 tokenId
        ) {
            return TokenId(tokenId, true);
        } catch {
            return TokenId(0, false);
        }
    }

    function collectionTokenIds(
        address tokenAddress,
        uint256 fromIndex,
        uint256 size
    ) external view returns (TokenId[] memory tokenIds) {
        uint256 count = IERC721Enumerable(tokenAddress).totalSupply();
        uint256 length = size;

        if (length > (count - fromIndex)) {
            length = count - fromIndex;
        }

        tokenIds = new TokenId[](length);

        for (uint256 i = 0; i < length; i++) {
            tokenIds[i] = _tokenByIndex(tokenAddress, fromIndex + i);
        }
    }

    function _tokenOwner(address tokenAddress, uint256 tokenId)
        internal
        view
        returns (TokenOwner memory)
    {
        try IERC721(tokenAddress).ownerOf(tokenId) returns (address owner) {
            return TokenOwner(tokenAddress, tokenId, owner, true);
        } catch {
            return TokenOwner(tokenAddress, tokenId, address(0), false);
        }
    }

    function tokenOwners(TokenOwnerInput[] calldata tokenOwnerInput)
        external
        view
        returns (TokenOwner[] memory owners)
    {
        owners = new TokenOwner[](tokenOwnerInput.length);

        for (uint256 i = 0; i < tokenOwnerInput.length; i++) {
            address tokenAddress = tokenOwnerInput[i].tokenAddress;
            uint256 tokenId = tokenOwnerInput[i].tokenId;
            owners[i] = _tokenOwner(tokenAddress, tokenId);
        }
    }
}
