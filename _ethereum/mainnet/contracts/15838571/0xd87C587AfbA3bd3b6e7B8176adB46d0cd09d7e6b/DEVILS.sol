// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract EtherealDEVILS is ERC721A, Ownable, ReentrancyGuard {
  //using Strings for uint256;
  
  uint256 public DEVILS_SUPPLY = 3333;

  string public uriSuffix = ".json";
  string public baseURI = "";

  
  
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol
  ) ERC721A(_tokenName, _tokenSymbol) {
  }

  function Airdrop(uint256 _DEVILSAmount, address toAirdrop) public onlyOwner{
    _mint(toAirdrop, _DEVILSAmount);
  }


 function adminMint(uint256 _teamAmount) external onlyOwner{
    _mint(msg.sender, _teamAmount);
  }


  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
  }

}