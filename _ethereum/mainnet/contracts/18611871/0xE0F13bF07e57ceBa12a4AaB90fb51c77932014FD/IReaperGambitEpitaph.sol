
pragma solidity ^0.8.0;

interface IReaperGambitEpitaph {
    function totalSupply() external view returns (uint256);
    function mintEpitaph(uint256[12] calldata sig, uint256 extraData, bytes memory coupon) external payable;
    function BMP(uint256 tokenId) external view returns (bytes memory);
    function ownerOf(uint256 tokenId) external view returns (address);
}
