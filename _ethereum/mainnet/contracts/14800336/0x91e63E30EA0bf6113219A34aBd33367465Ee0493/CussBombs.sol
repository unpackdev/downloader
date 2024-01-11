//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";

contract CussBombs is ERC721A, Ownable {
  using Strings for uint256;

  uint256 public maxSupply = 12230;
  uint256 private _currentId; 
  string public baseURI;
  string private _contractURI;
  address public beneficiary;
  address public royalties; 

  constructor(
    address _beneficiary,
    address _royalties,
    string memory _initialBaseURI,
    string memory _initialContractURI
  ) ERC721A("CussBombs", "CUSSB") {
    beneficiary = _beneficiary;
    royalties = _royalties;
    baseURI = _initialBaseURI;
    _contractURI = _initialContractURI;
  }

  // Setters

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setBeneficiary(address _beneficiary) public onlyOwner {
    beneficiary = _beneficiary;
  }

  function setRoyalties(address _royalties) public onlyOwner {
    royalties = _royalties;
  }

  function setBaseURI(string memory uri) public onlyOwner {
    baseURI = uri;
  }

  function setContractURI(string memory uri) public onlyOwner {
    _contractURI = uri;
  }

  // Getters

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  // Minting

  function ownerMint(address to, uint256 amount) public onlyOwner {
    _internalMint(to, amount); 
  }

  // Withdraw Payment

  function withdraw() public onlyOwner {
    payable(beneficiary).transfer(address(this).balance);
  }

  // Private

  function _internalMint(address to, uint amount) private {
    require(_currentId + amount <= maxSupply, "Will exceed maximum supply");
    _currentId += amount;
    _safeMint(to, amount);
  }

  // IERC2981

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256 royaltyAmount) {
    _tokenId; 
    royaltyAmount = (_salePrice / 100) * 5; 
    return (royalties, royaltyAmount);
  }
}