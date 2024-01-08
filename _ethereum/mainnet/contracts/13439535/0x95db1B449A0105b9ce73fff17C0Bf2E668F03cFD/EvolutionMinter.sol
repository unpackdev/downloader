// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./EvolutionContract.sol";

contract EvolutionMinter is ERC721Enumerable, Ownable {
  using Strings for uint256;

  IEvolutionContract evolutionContract;
  ERC721Enumerable mintingContract;
  
  uint256 private _currentTokenID = 10420;

  string private _baseUri = "";

  event Evolve(address _to, uint256 _tokenId, uint256[3] _burnedTokens, bytes data);

  constructor() ERC721("Tokenmon Gen 2", "TM2") {
  }

  function setBaseURI(string memory baseUri) public onlyOwner {
    _baseUri = baseUri;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseUri;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return string(abi.encodePacked(_baseUri, tokenId.toString()));
  }

  function setEvolutionContractAddress(address _address) public onlyOwner {
    evolutionContract = IEvolutionContract(_address);
  }

  function setMintingContractAddress(address _address) public onlyOwner {
    mintingContract = ERC721Enumerable(_address);
  }

  function evolve(uint256[3] memory _tokensToBurn, bytes memory data) public {
    require(evolutionContract.isEvolvingActive(), "EvolutionMinter: Evolving is not active right now");
    require(evolutionContract.isEvolutionValid(_tokensToBurn), "EvolutionMinter: Evolution is not valid");
    
    address dead = address(0x000000000000000000000000000000000000dEaD);
    mintingContract.safeTransferFrom(msg.sender, dead, _tokensToBurn[0]);
    mintingContract.safeTransferFrom(msg.sender, dead, _tokensToBurn[1]);
    mintingContract.safeTransferFrom(msg.sender, dead, _tokensToBurn[2]);
    
    _currentTokenID = _currentTokenID + 1;
    _mint(msg.sender, _currentTokenID);
    
    emit Evolve(msg.sender, _currentTokenID, _tokensToBurn, data);
  }

  function withdraw(address _target) public onlyOwner {
    payable(_target).transfer(address(this).balance);
  }
}