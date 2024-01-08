pragma solidity ^0.7.3;

import "./ERC721.sol";
import "./Ownable.sol";

contract TestRedditAvatarNFTs is ERC721, Ownable {
  constructor() public ERC721("TestRedditNFT", "TestSNOO") {}

  function mintNFT(uint tokenId, address ownerId, string memory tokenURI) public onlyOwner {
    _mint(ownerId, tokenId);
    _setTokenURI(tokenId, tokenURI);
  }

  function contractURI() public view returns (string memory) {
    return "https://nft.reddit.com/metadata/test-reddit-avatar-nfts.json";
  }
}
