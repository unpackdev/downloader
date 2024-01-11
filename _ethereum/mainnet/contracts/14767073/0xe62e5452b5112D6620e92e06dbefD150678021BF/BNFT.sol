pragma solidity ^0.8.0;
interface BNFT {
    function mint(address to_, uint256 countNFTs_) external returns (uint256, uint256);
    function burnAdmin(uint256 tokenId) external;
    function TransferFromAdmin(uint256 tokenId, address to) external;
}