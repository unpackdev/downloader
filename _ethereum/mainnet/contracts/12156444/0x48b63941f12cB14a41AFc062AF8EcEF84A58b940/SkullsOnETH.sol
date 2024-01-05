// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import openzeppelin contracts
import "./ERC721.sol";
import "./Ownable.sol";

contract SkullsOnETH is ERC721,Ownable {
  mapping(string => uint8) mintedMediaHashes;
  mapping(uint256 => uint256) mintedTokenIds;
  mapping(uint256 => string) metadataHashes;
  string contractMetadataHash;
  uint256 private maxTokenAmount = 365;
  uint256[] private _allTokens;
  mapping(uint256 => uint256) private _allTokensIndex;

  constructor() ERC721("SkullsOnETH", "SOE") {}

  function _baseURI() internal view virtual override returns (string memory) {
    /* Return baseURI */
    return "ipfs://";
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    require(bytes(metadataHashes[tokenId]).length != 0, "ERC721Metadata: URI query for nonexistent metadata hash");
    require (totalSupply() <= getMaxTokenAmount(), "ERC721: max amount of mintable tokens reached");

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0
      ? string(abi.encodePacked(baseURI, metadataHashes[tokenId]))
      : 'no tokenURI found';
  }

  function contractURI() public pure returns (string memory) {
    return "ipfs://QmZ4SvtxXUti5Mr2nvPaKEgsxU7XaRMqJPUf5et6SrdRNw";
  }
  
  function mintToken(address recipient, uint256 tokenId, string memory metadataHash, string memory mediaHash ) 
  public 
  onlyOwner 
  returns (uint256) {
    require(mintedMediaHashes[mediaHash] != 1, "ERC721: mediaHash was already minted");
    require(mintedTokenIds[tokenId] != 1, "ERC721: tokenId was already minted");
    
    mintedMediaHashes[mediaHash] = 1;
    mintedTokenIds[tokenId] = 1;
    metadataHashes[tokenId] = metadataHash;
    
    _mint(recipient, tokenId);

    return tokenId;
  }

  function getMaxTokenAmount() public view returns (uint256) {
    return maxTokenAmount;
  }

  function totalSupply() public view returns (uint256) {
    return _allTokens.length;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
      super._beforeTokenTransfer(from, to, tokenId);

      if (from == address(0)) {
          _addTokenToAllTokensEnumeration(tokenId);
      }
  }

  function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
      _allTokensIndex[tokenId] = _allTokens.length;
      _allTokens.push(tokenId);
  }
}
