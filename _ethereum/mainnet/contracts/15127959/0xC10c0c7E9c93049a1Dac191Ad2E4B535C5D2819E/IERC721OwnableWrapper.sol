// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

interface IERC721OwnableWrapper {
    function setBaseURI(string memory _uri) external;

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;

    function deleteDefaultRoyalty() external;

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external;

    function resetTokenRoyalty(uint256 tokenId) external;
}