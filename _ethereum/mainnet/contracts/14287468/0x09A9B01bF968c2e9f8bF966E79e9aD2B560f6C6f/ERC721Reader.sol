// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.9;
pragma abicoder v2;

import "./IERC721.sol";
import "./IERC721Enumerable.sol";

contract ERC721Reader {
    struct OwnerTokenCount {
        address tokenAddress;
        uint256 count;
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
}
