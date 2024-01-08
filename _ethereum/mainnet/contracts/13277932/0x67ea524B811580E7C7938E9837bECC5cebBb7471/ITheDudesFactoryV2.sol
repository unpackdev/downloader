pragma solidity 0.8.0;

interface ITheDudesFactoryV2 {
  function mint(uint256 collectionId, address account, uint256 tokenId) external;
  function burn(uint256 collectionId, uint256 tokenId) external;
}
