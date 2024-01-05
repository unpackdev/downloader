//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721URIStorage.sol";

contract Freeema is ERC721URIStorage, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  constructor() ERC721("Freeema!!", "FRM") {}

  function mint(address to, string memory tokenURI)
    public
    onlyOwner
    returns (uint256)
  {
    _tokenIds.increment();

    uint256 newItemId = _tokenIds.current();
    _mint(to, newItemId);
    _setTokenURI(newItemId, tokenURI);

    return newItemId;
  }

  function _baseURI() override internal view virtual returns (string memory) {
    return "https://cloudflare-ipfs.com/ipfs/";
  }
}