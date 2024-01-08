pragma solidity 0.8.0;

interface ITheDudes {
  function dudes(uint256 tokenId) external returns (string memory);
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function tokensOfOwner(address _owner) external view returns (uint256[] memory);
}
