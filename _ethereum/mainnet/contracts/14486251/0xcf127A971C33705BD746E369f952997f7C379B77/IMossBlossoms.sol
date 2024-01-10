pragma solidity ^0.8.1;

interface IMossBlossoms {
    function mint(address to, uint256 tokenId) external ;
    function existsTokenId(uint256 tokenId)   external view returns (bool) ;
}