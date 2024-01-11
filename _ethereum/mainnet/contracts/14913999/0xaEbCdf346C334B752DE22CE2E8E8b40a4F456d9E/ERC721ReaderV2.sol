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

    function ownerTokenIds(
        address tokenAddress,
        address owner,
        uint256 fromIndex,
        uint256 size
    ) external view returns (uint256[] memory tokenIds) {
        uint256 count = IERC721(tokenAddress).balanceOf(owner);
        uint256 length = size;

        if (length > (count - fromIndex)) {
            length = count - fromIndex;
        }

        tokenIds = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            tokenIds[i] = IERC721Enumerable(tokenAddress).tokenOfOwnerByIndex(
                owner,
                fromIndex + i
            );
        }
    }

    function collectionTokenIds(
        address tokenAddress,
        uint256 fromIndex,
        uint256 size
    ) external view returns (uint256[] memory tokenIds) {
        uint256 count = IERC721Enumerable(tokenAddress).totalSupply();
        uint256 length = size;

        if (length > (count - fromIndex)) {
            length = count - fromIndex;
        }

        tokenIds = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            tokenIds[i] = IERC721Enumerable(tokenAddress).tokenByIndex(
                fromIndex + i
            );
        }
    }

    function tokenOwners(TokenOwnerInput[] calldata tokenOwnerInput)
        external
        view
        returns (TokenOwner[] memory owners)
    {
        for (uint256 i = 0; i < tokenOwnerInput.length; i++) {
            address tokenAddress = tokenOwnerInput[i].tokenAddress;
            uint256 tokenId = tokenOwnerInput[i].tokenId;
            address owner = IERC721(tokenAddress).ownerOf(tokenId);
            owners[i] = TokenOwner(tokenAddress, tokenId, owner);
        }
    }
}
