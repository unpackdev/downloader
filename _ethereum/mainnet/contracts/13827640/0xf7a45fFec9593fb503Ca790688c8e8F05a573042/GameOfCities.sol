// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

//
//  .__                 ._   __   ,
//  [ __ _.._ _  _    _ |,  /  `*-+-* _  __
//  [_./(_][ | )(/,  (_)|   \__.| | |(/,_)
//
//
// A secret minting code will be hidden on a sticker IRL.
// The sticker will be hidden somewhere in it's corresponding city.
// Check out twitter and gameofcities.com for new city drops.
// For each city a riddle will give you clues as to the stickers location.
// You solve the riddle, find the sticker, and claim the city!
// The sticker will contain a secret.
// The secret will be the IPFS url of the tokens metadata.
// The hash of the secret IPFS url is stored when the city is loaded.
// When claiming the city / minting the token the hash of the secret IPFS while be verified.
// This ensures that only people who have seen the physical sticker can claim.
// Call it Proof of Adventure.
// Have fun,
// Dave (design) & Chad (dev)

contract GameOfCities is ERC721, ERC721URIStorage, Ownable {

  bool public gameOver;

  mapping(uint256 => bytes32) hashes;
  
  constructor() ERC721("Game of Cities", "GOC") {}

  function loadCity(uint256 cityId, bytes32 secretUriHash) public onlyOwner {
    require(!gameOver, "Game over");
    require(hashes[cityId] == 0, "City already loaded");
    hashes[cityId] = secretUriHash;
  }

  function endGame(bool areYouReallySure) public onlyOwner {
    require(areYouReallySure, "Not really sure");
    gameOver = true;
  }
  
  function claimCity(uint256 cityId, string memory secretUri ) public
  {
    require(hashes[cityId] > 0, "City not loaded");
    bytes32 hash = keccak256(abi.encodePacked(secretUri));
    require(hashes[cityId] == hash, "Invalid secret URI");
    _safeMint(msg.sender, cityId);
    _setTokenURI(cityId, secretUri);
  }

  function isCityClaimed(uint256 cityId) public view returns (bool)
  {
    return _exists(cityId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

}
