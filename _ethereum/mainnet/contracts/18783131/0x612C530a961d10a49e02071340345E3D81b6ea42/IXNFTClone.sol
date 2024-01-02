// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IXNFTClone {
    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function contractURI() external view returns (string calldata);

    function getApproved(uint256 tokenId) external view returns (address);

    function initialize(
        string calldata _name,
        string calldata _symbol,
        uint256 _accountId
    ) external;

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    function mint(address recepient, uint256 tokenId) external;

    function name() external view returns (string calldata);

    function nftRedemption(address user, uint256 tokenId) external;

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function renounceOwnership() external;

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address, uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string calldata);

    function tokenURI(uint256 _tokenId) external view returns (string calldata);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function transferOwnership(address newOwner) external;
}
