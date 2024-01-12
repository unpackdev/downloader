// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

contract BulkNFTSender{
    function airdropNFTs(address _owner, uint256[] calldata _tokenIds, address[] calldata _recipient) public {
        address _NFTaddress = 0x7CB3c60E65fef3A9e0997F42a06F56fA0eAbd66D;
        IERC721 nft = IERC721(_NFTaddress);
        
        require(nft.isApprovedForAll(_owner,address(this)),"Operator not approved for transfer all");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            nft.safeTransferFrom(_owner,_recipient[i],_tokenIds[i]);
        }
    }
}