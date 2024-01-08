// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "./IMysteryNFT_S.sol";

interface IMysteryNFT is IMysteryNFT_S {
    function mint(address _to, MysteryNFT_S memory _nft,string memory _tokenURI) external  returns (uint256 tokenId);
    function burn(uint256 _tokenId) external;
    function getNFTByTokenId(uint256 _tokenId) external view returns (MysteryNFT_S memory);
    function getNFTs(uint256 page) external view returns (MysteryNFT_S[] memory,uint);
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function tokenURI(uint256 tokenId) external view  returns (string memory);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}