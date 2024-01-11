pragma solidity ^0.8.1;

interface IdacDao {
    function mint(address to, uint256 tokenId) external ;
    function mintNFT(address to, uint256 tokenId,uint8 period) external;
    function existsTokenId(uint256 tokenId)   external view returns (bool) ;
    function getNFTPeriod(uint256 tokenId)  external view returns(uint8);
}