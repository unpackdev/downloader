// SPDX-License-Identifier: MIT
/*
   _      ΞΞΞΞ      _
  /_;-.__ / _\  _.-;_\
     `-._`'`_/'`.-'
         `\   /`
          |  /
         /-.(
         \_._\
          \ \`;
           > |/
          / //
          |//
          \(\
           ``
     defijesus.eth
*/
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";

error NonExistantToken();
error WrongArraySize();

contract HiddenStarsClub is ERC721, Ownable {

    mapping(uint256 => string) public URIs;

    uint256 public currentSupply = 0;

    constructor() ERC721("Hidden Stars Club", "STAR") {}

    // PUBLIC

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
          revert NonExistantToken();
        }
        return URIs[tokenId];
    }

    // ONLY OWNER

    function mint(string calldata url) external onlyOwner {
      URIs[currentSupply] = url;
      safeMint(msg.sender);
    }

    function mintTo(string calldata url, address to) external onlyOwner {
      URIs[currentSupply] = url;
      safeMint(to);
    }

    function mintMultiple(string[] calldata urls) external onlyOwner {
      unchecked {
        for (uint256 i = 0; i < urls.length; i++) {
          URIs[currentSupply] = urls[i];
          safeMint(msg.sender);
        }
      }
    }

    function mintMultipleTo(string[] calldata urls, address[] calldata tos) external onlyOwner {
      if (urls.length != tos.length) {
        revert WrongArraySize();
      }
      unchecked {
        for (uint256 i = 0; i < urls.length; i++) {
          URIs[currentSupply] = urls[i];
          safeMint(tos[i]);
        }
      }
    }
    
    function setTokenURIs(uint256[] calldata tokenIDs, string[] calldata tokenURLs) external onlyOwner {
        if (tokenIDs.length != tokenURLs.length) {
          revert WrongArraySize();
        }
        unchecked {
          for (uint256 i = 0; i < tokenIDs.length; i++) {
            URIs[tokenIDs[i]] = tokenURLs[i];
          }
        }
    }

    // INTERNAL
    function safeMint(address to) internal {
        _safeMint(to, currentSupply);
        currentSupply += 1;
    }
}