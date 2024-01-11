// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract SushimiFrens is ERC721Enumerable, Ownable {
  string constant public baseURI = "ipfs://";

  struct NFTData {
    string ipfsHash;
    bool frozen;
  }

  mapping(uint => NFTData) public nftDatas;

  constructor() ERC721("Sushimi Frens", "SUSHF") { }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    if(!_exists(_tokenId)) return "";
    return string(abi.encodePacked(baseURI, nftDatas[_tokenId].ipfsHash));
  }

  function mint(address _to, string calldata _ipfsHash) external onlyOwner {
    uint index = totalSupply();

    nftDatas[index] = NFTData(_ipfsHash, false); 
    _safeMint(_to, index);
  }


  // For error correction
  function freeze(uint _index) external onlyOwner {
    nftDatas[_index].frozen = true;
  }

  // For error correction
  function setIpfsHash(uint _index, string calldata _ipfsHash) external onlyOwner {
    require(nftDatas[_index].frozen == false, "Frozen");
    nftDatas[_index].ipfsHash = _ipfsHash;
  }
}