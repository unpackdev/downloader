// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// This file is a holding place for my best contract yet but that isn't working.
// It's here so I can experiment in the main one.

import "./ERC721.sol";
import "./Ownable.sol";

/// @author Jimmy Wales

contract EditThisNFT is ERC721, Ownable {
  uint public resetInterval = 5; // default resetInterval is 5
  bool public editAllowed = true; // default
  string private _tokenURI = "ipfs://QmUFpgdKZnGa19yFPtQnMGt5g7QuahqT1zTsFZSc9X3wjJ";

  constructor() ERC721("EditThisNFT", "ETN") {
    _safeMint(msg.sender, 1);
  }

  /**
   @notice set new ResetInterval - should be respected on server side
   @param _resetInterval - how often the NFT website should reset to Hello, World!
   */

  function setResetInterval(uint _resetInterval) external {
    require( msg.sender == ownerOf(1), "ERROR: Only token owner can set reset interval");
    resetInterval = _resetInterval;
  }

  /**
   @notice set new editAllowed - should be respected on server side
   @param _editAllowed - true or false if editing is allowed or not right now
  **/

  function setEditAllowed(bool _editAllowed) external {
    require( msg.sender == ownerOf(1), "ERROR: Only token owner can set editability");
    editAllowed = _editAllowed;
  }

  /**
   @notice update the tokenURI.  Only callable by the contract owner
   @param _newTokenURI - new location of URI
  **/

  function setTokenURI(string memory _newTokenURI) external {
    require(
        ( msg.sender == owner() ),
        "ERROR: not token owner and not contract owner!"
        );
      _tokenURI = _newTokenURI;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURI;
    }
}

