// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;


interface EKotketNFTInterface {
    function allTokens() external view returns (uint256[] memory ids);
    function totalSupply() external view returns (uint256);
    function tokenExisted(uint256 _tokenId) external view returns (bool);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokensOwned(address owner) external view returns (uint256[] memory ids);
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function getGene(uint256 _tokenId) external view returns (uint8);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function kotketBred(address _beneficiary,
        uint256 _tokenId, 
        uint8 _gene, 
        string memory _name, 
        string memory _metadataURI) external;
}