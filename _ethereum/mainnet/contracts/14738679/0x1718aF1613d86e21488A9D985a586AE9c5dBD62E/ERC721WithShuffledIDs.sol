// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";

// Get a random ID minted every time _safeMint is called.
// Credits to @PunkScapes project and @jalil.
// https://etherscan.io/address/0x51ae5e2533854495f6c587865af64119db8f59b4#code#F3#L1


contract ERC721WithShuffledIDs is ERC721 {
  uint16[8193] private tokens;
  uint16 private maxIndex;
  uint16 public maxSupply;
  uint16 public mintedTokens;

  constructor (string memory name_, string memory symbol_, uint16 _maxSupply)
    ERC721(name_, symbol_)
  {
    maxSupply = _maxSupply;
    maxIndex = _maxSupply;
  }

  function totalSupply() public view returns (uint256) {
    return uint256(maxSupply);
  }

  function nextToken() internal returns (uint16) {
    require(tokensLeft()>0, "No more tokens left.");
    uint16 random = uint16(uint256(blockhash(block.number - 1)) % maxIndex)+1;
    uint16 value = (tokens[random] == 0) ? random : tokens[random];
    tokens[random] = (tokens[maxIndex] == 0) ? maxIndex : tokens[maxIndex];
    tokens[maxIndex] = value;
    // ^ This is nice: Tokens[maxSupply - maxIndex] hold the minted
    // token IDs in reverse order. tokenByIndex can be user to retrieve them.
    maxIndex -= 1;
    mintedTokens += 1;
    return(value);
  }

  function tokensLeft() public view returns (uint16) {
    return( maxSupply - mintedTokens );
  }

  function tokenByIndex(uint16 _index) public view returns (uint16) {
    require(_index < mintedTokens, "Not minted yet");
    return tokens[maxSupply - _index];
  }

  // Override _safeMint to make sure it can not be used to
  // mint a specific tokenId.
  // _tokenId is ignored now.
  function _safeMint(address _to, uint256 /* _tokenId */) internal override {
    uint256 id = nextToken();
    ERC721._safeMint(_to, id);
  }

  function _safeMint(address _to) internal {
    _safeMint(_to, 0);
  }

}