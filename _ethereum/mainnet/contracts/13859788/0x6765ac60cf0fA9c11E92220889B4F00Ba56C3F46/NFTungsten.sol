// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract NFTungsten is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
  uint8[] private availableTokens;
  uint[] private claimedTokens;
  mapping(uint8 => bool) private tokenExists;

  uint public constant tokenPrice = 740000000000000000; //0.74 ETH
  string baseTokenURI = "https://www.nftungsten.io/api/tokens/";

  constructor() ERC721("NFTungsten", "NFW74") {
    initAvailableTokens();
  }

  function initAvailableTokens() private {
    for (uint8 i=1; i <= 74; i++){
      availableTokens.push(i);
    }
  }

  function _baseURI() internal view override returns(string memory){
    return baseTokenURI;
  }

  // ---- Owner Only ----

  function setBaseURI(string memory baseURI) public onlyOwner {
    baseTokenURI = baseURI;
  }

  function withdraw() public onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }

  // ---- Minting ----

  function removeAvailableToken(uint rIndex) private {
    require(rIndex < availableTokens.length, "index out of bound");

    for (uint i=rIndex; i < availableTokens.length - 1; i++){
      availableTokens[i] = availableTokens[i + 1];
    }
    availableTokens.pop();
  }

  function safeMint(uint mintQuantity) public payable {
    require(totalSupply() < 74, "All tokens have been minted");
    require((totalSupply() + mintQuantity) <= 74, "Cannot mint more than the 74 tokens available, adjust mint quantity");
    require(mintQuantity <= 4, "Cannot exceed max mint quantity of 4");
    require(msg.value >= (tokenPrice * mintQuantity), "Not enough ETH sent.");

    for (uint8 i=0; i < mintQuantity; i++){
      uint r = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % availableTokens.length;
      uint8 tokenId = availableTokens[r];

      require(tokenExists[tokenId] != true, "Random token already exists");

      tokenExists[tokenId] = true;
      claimedTokens.push(tokenId);

      removeAvailableToken(r);
      _safeMint(msg.sender, tokenId);
    }
  }

  // The following functions are overrides required by Solidity.

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage){
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns(string memory){
    return super.tokenURI(tokenId);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable){
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns(bool){
    return super.supportsInterface(interfaceId);
  }
}