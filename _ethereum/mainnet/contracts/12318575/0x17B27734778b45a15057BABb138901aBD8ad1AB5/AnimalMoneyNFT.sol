pragma solidity ^0.6.12;
import "./ERC721PresetMinterPauserAutoId.sol";

contract AnimalMoneyNFT is ERC721PresetMinterPauserAutoId {
  constructor() public ERC721PresetMinterPauserAutoId("Animal Money NFT", "ANIMALNFT", "https://animal.money/") {}
}
