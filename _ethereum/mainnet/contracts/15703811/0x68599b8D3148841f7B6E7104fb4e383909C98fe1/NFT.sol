// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract ARABPUNKS is ERC721, Ownable {
using Counters for Counters.Counter;

Counters.Counter private _tokenIdCounter;

constructor() ERC721("ARABPUNKS", "ABP") {}

function _baseURI() internal pure override returns (string memory) {
return "https://ipfs.io/ipfs/QmSVKfqjqHACKLJKG3i9HVeM4gGHeKSJnaugCWqvrAzhMS?filename=silver.mp4";
}

function safeMint(address to) public onlyOwner {
uint256 tokenId = _tokenIdCounter.current();
_tokenIdCounter.increment();
_safeMint(to, tokenId);
}

function airdropMint(address[] memory _addresses, uint[] memory _tokenIds) external onlyOwner {
require(_addresses.length == _tokenIds.length);
uint arrayLength = _addresses.length;
for(uint i = 0; i < arrayLength; i++){
_safeMint(_addresses[i], _tokenIds[i]);
}
}
}