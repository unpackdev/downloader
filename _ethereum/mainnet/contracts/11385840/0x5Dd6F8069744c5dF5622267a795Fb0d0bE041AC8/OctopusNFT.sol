pragma solidity ^0.6.2;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

// NFT Gradient token
// Stores two values for every token: outer color and inner color
contract OctopusNFT is ERC721,Ownable {

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  constructor() public ERC721("OctopusNFT token", "OctopusNFT") {}

  function awardItem(address player, string memory tokenURI)
  public onlyOwner
  returns (uint256)
  {
    _tokenIds.increment();

    uint256 newItemId = _tokenIds.current();
    _mint(player, newItemId);
    _setTokenURI(newItemId, tokenURI);

    return newItemId;
  }


}

