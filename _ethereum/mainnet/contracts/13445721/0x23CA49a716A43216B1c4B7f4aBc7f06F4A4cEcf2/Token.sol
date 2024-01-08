// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract Token is ERC721, Ownable {
  using Counters for Counters.Counter;
  
  Counters.Counter private _tokenIds;
  string private baseUri;
  constructor(string memory name_, string memory symbol_, string memory baseUri_) ERC721(name_, symbol_){
    baseUri = baseUri_;
  }
  function setBaseUri(string memory baseUri_) external onlyOwner {
    baseUri = baseUri_;
  }
  function _baseURI() internal view override returns(string memory){
     return baseUri;
  }
 function mint() external virtual returns(uint256){
    _tokenIds.increment();
    uint256 tokenId = _tokenIds.current();
    _mint(msg.sender, tokenId);
    return tokenId;
  }
  function burn(uint256 tokenId) external virtual {
    require(_exists(tokenId), "Token does not exist");
    require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved to handle token id");
    _burn(tokenId);
  }
  
}
