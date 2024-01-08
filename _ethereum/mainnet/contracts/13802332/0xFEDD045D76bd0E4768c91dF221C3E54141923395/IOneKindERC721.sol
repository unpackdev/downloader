// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./IERC721Enumerable.sol";

/**
 * @dev Extension for OneKindERC721 compatible methods
 */
interface IOneKindERC721 is IERC721Enumerable {
    function mint(address to) external returns (uint256);

    function setBaseURI(string memory permanentBaseURI) external;

    function setTokenURI(uint256 tokenId, string memory permanentTokenURI)
        external;
}
