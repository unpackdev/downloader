// SPDX-License-Identifier: MIT
/*
-------------------------
|   DEGEN FOR DEGENS    |
-------------------------
*/

pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";


contract DGNWZRDS is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;
  string public           baseURI = "https://dgnwzrds.xyz/metadata/";
  string public           contractURI = "https://dgnwzrds.xyz/metadata-contract.json";

  uint256 public constant maxSupply = 4000;
  uint256 public          maxFreeSupply = 1000;
  uint256 public          cost = (5 ether/1000); //0.005 
  uint256 public          maxFreePerTransaction = 5;
  uint256 public          maxPerTransaction = 5;
  bool public             mintEnabled       = false;

  mapping(address => uint256) private _walletMints;

  constructor() ERC721A("DGN WZRDS", "DGNWZRDS"){
    setCost(cost);
    setmaxFreePerTransaction(maxFreePerTransaction);
    setmaxPerTransaction(maxPerTransaction);
    _mint(owner(), 1);
  }


  function mint(uint256 _count)  external payable {
    require(mintEnabled, "Minting is not live yet.");

    require(totalSupply() + _count <= maxSupply, 'Max supply exceeded!');

    if(totalSupply() < maxFreeSupply){
      require(_count <= maxFreePerTransaction, 'Invalid free mint amount!');
      _walletMints[_msgSender()] += _count;
    } else {
      require(msg.value == cost * _count, "Free mint done already! Insufficient funds!");
      require(_count <= maxPerTransaction, "Invalid mint amount!");  
    }
    _safeMint(msg.sender, _count);
  }


  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

	  string memory currentBaseURI = _baseURI();
	  return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), "")) : "";
  }


  function enableMint() external onlyOwner {
      mintEnabled = !mintEnabled;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setmaxFreePerTransaction(uint256 _maxFreePerTransaction) public onlyOwner {
    maxFreePerTransaction = _maxFreePerTransaction;
  }


  function setmaxPerTransaction(uint256 _maxPerTransaction) public onlyOwner {
    maxPerTransaction = _maxPerTransaction;
  }

  function numberMinted(address owner) public view returns (uint256) {
      return _numberMinted(owner);
  }

  function setBaseURI(string calldata baseURI_) external onlyOwner {
      baseURI = baseURI_;
  }

  function setcontractURI(string calldata contractURI_) external onlyOwner {
      contractURI = contractURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }

  function reserveMint(address _to, uint256 _count) external onlyOwner nonReentrant {
      _mint(_to, _count);
  }


  function withdraw() external onlyOwner nonReentrant {
    //owner withdraw
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

}