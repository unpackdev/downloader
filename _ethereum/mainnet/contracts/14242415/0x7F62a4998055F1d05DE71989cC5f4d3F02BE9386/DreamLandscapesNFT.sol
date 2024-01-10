// SPDX-License-Identifier: MIT
//                _                                  
//               (`  ).                   _           
//              (     ).              .:(`  )`.       
// )           _(       '`.          :(   .    )      
//         .=(`(      .   )     .--  `.  (    ) )      
//        ((    (..__.:'-'   .+(   )   ` _`  ) )                 
// `.     `(       ) )       (   .  )     (   )  ._   
//   )      ` __.:'   )     (   (   ))     `-'.-(`  ) 
// )  )  ( )       --'       `- __.'         :(      )) 
// .-'  (_.'          .')                    `(    )  ))
//                   (_  )  dream landscapes   ` __.:'          
//                                         
// --..,___.--,--'`,---..-.--+--.,,-,,..._.--..-._.-a:f--.
//
// by @eddietree

pragma solidity ^0.8.0;

import "./Base64.sol";
import "./DreamSeedProduct.sol";

contract DreamLandscapesNFT is DreamSeedProduct {

  bool public isRevealed = false;
  string internal _revealedMetaURI = "https://gateway.pinata.cloud/ipfs/QmRA71NveXF5EFUSds873WqxkVuT8HvvATgz65ev3ea9d5/";
  
  constructor(address _proxyRegistryAddress) ERC721TradableBurnable("Dream Landscapes NFT", "DREAMLANDSCAPE", _proxyRegistryAddress) {  
    _prerevealMetaURI = "https://gateway.pinata.cloud/ipfs/QmPWgEDgbkg9EuuEegGwdzTi5E3MzJu7uMYZ6YSWVb5NuC";
  }

  function setRevealedURI(string memory _value) external onlyOwner {
    _revealedMetaURI = _value;
  }

  function revealAll(bool state) external onlyOwner {
      isRevealed = state;
  }

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    require(_tokenId >= 1 && _tokenId <= MAX_SUPPLY, "Not valid token range");

    if (!isRevealed) { // prereveal

      string memory json = Base64.encode(
          bytes(string(
              abi.encodePacked(
                  '{"name": ', '"Dream Landscape #',Strings.toString(_tokenId),'",',
                  '"description": "A doorway opening into another cycle of life...",',
                  '"attributes":[{"trait_type":"Status", "value":"Unrevealed"}],',
                  '"image": "', _prerevealMetaURI, '"}' 
              )
          ))
      );
      return string(abi.encodePacked('data:application/json;base64,', json));
    }  else { // revealed
      return string(abi.encodePacked(_revealedMetaURI, Strings.toString(_tokenId), ".json"));
    }
  }

  function reserveLandscape() public onlyOwner {
    require(totalSupply() < MAX_SUPPLY, "Purchase would exceed max tokens");
    mintTo(msg.sender);
  }

  function mintLandscape(uint256 seedTokenId) external {
    require(mintIsActive, "Must be active to mint tokens");
    require(totalSupply() < MAX_SUPPLY, "Purchase would exceed max tokens");

    burnDreamSeed(seedTokenId);
    mintTo(msg.sender);
  }
}