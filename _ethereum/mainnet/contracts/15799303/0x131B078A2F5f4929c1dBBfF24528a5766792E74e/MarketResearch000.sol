// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract MarketResearch000 is ERC721, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _nextTokenId;

  constructor() ERC721("DidYouSeeThis?", "DIDUC") {
  }

  function mintNext(address to) public onlyOwner {
    _safeMint(to, _nextTokenId.current());
    _nextTokenId.increment();
  }

  function bulkMint(address[] calldata receivers) public onlyOwner {
    for(uint i = 0; i < receivers.length; i++ ){
      mintNext(receivers[i]);
    }
  }

  function _baseURI() override internal view virtual returns (string memory) {
    return "https://nft.didyouseethis.xyz/campaigns/000/metadata/";
  }
}
