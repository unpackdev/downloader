
pragma solidity ^0.8.0;

interface IDogewood {

  // struct to store each token's traits
  
  struct Doge {
      uint8 head;
      uint8 breed;
      uint8 color;
      uint8 class;
      uint8 armor;
      uint8 offhand;
      uint8 mainhand;
      uint16 level;
  }

  function getTokenTraits(uint256 tokenId) external view returns (Doge memory);
  function getGenesisSupply() external view returns (uint256);
}