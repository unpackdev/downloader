pragma solidity ^0.8.0;

interface IERC721 {
    function mint(address to, uint256 tokenId) external;
    function mintBatch(address to, uint256[] memory tokenIds) external;
}
