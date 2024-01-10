// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
                   @@@@              @@@@@@@@@(                        
               @@@@@@@@@@@@        @@@@@@@@@@@@@@                      
              @@@@@    @@@@@      @@@@@      @@@@@                     
             @@@@        @@@@     @@@@@      @@@@@                     
             @@@@        @@@@      @@@@@@@@@@@@@@                      
              @@          @@         &@@@@@@@@*                        
                                                                      
                   @@@@                                                
                   @@@@           @@@@        @@@@                     
             @@@@@@@@@@@@@@@@     @@@@       %@@@@                     
              @@@@@@@@@@@@@@       @@@@@@//@@@@@@                      
                   @@@@              @@@@@@@@@@                        
                   @@@@                       

                  Created by notu @notuart    
 */

import "./base64.sol";
import "./ERC721A.sol";
import "./Ownable.sol";

abstract contract OneOfOnes is ERC721A, Ownable {
  bool public frozen = false;

  mapping(uint256 => Metadata) private _metadata;

  struct Metadata {
    string name;
    string description;
    string image;
  }

  modifier tokenExists(uint256 tokenId) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    _;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function mint(string memory name, string memory description, string memory image, address recipient) external onlyOwner {
    _metadata[_currentIndex] = Metadata(name, description, image);
    _safeMint(recipient, 1);
  }

  function tokenURI(uint256 tokenId) public view virtual override tokenExists(tokenId) returns (string memory) {
    Metadata memory metadata = _metadata[tokenId];
    
    return string(
      abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(
          bytes(
            abi.encodePacked('{"name":"', metadata.name, '", "description":"', metadata.description, '", "image": "', metadata.image, '"}')
          )
        )
      )
    );
  }

  function freeze() external onlyOwner {
    frozen = true;
  }

  function updateMetadata(uint256 tokenId, string memory name, string memory description, string memory image) public tokenExists(tokenId) onlyOwner {
    _metadata[tokenId] = Metadata(name, description, image);
  }
}