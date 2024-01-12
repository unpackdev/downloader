// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}


contract BulkNFTSender{

    function airdropNFTs(address[] calldata _recipients) public {
        address _NFTaddress = 0x7CB3c60E65fef3A9e0997F42a06F56fA0eAbd66D;
        address _owner = msg.sender;
        
        IERC721 nft = IERC721(_NFTaddress);
        require(nft.isApprovedForAll(_owner,address(this)),"Operator not approved for transfer all");
        require(nft.balanceOf(msg.sender)>=_recipients.length,"Owner doesnt have enough NFTs");
        uint256 nft_balance = nft.balanceOf(_owner);
       
        uint[] memory tokenIds = new uint[](nft_balance);

        for (uint256 i = 0; i < nft_balance; i++) {
            tokenIds[i] = nft.tokenOfOwnerByIndex(_owner,i);
        }

        for (uint256 i = 0; i < _recipients.length; i++) {
            nft.safeTransferFrom(_owner,_recipients[i],tokenIds[i]);
        }
    }
}