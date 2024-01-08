pragma solidity ^0.5.0;

// DigitalArtCollectible is not quite ERC-20 compliant
interface IDigitalArtCollectible {
   function transfer(address to, uint drawingId, uint printIndex) external returns (bool success);
   function DrawingPrintToAddress(uint print) external returns (address _address);
   function buyCollectible(uint drawingId, uint printIndex) external payable;
   function alt_buyCollectible(uint drawingId, uint printIndex) external payable;
}
