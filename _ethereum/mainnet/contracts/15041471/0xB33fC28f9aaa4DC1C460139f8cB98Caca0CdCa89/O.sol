// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./ECDSA.sol";
import "./Ownable.sol";

contract Opulent is ERC721A, Ownable {
  
  using ECDSA for bytes32;

  string public _baseTokenURI;
  string public endingUri = ".json";

  uint256 public price = 10 ether; 
  uint256 public maxSupply = 155;

  address treasuryWallet = 0x24B81B2d8c8F9Ed9C15dE3EED41221CE2815868e;
  // BALD EAGLE
  address founder1 = 0xfbAe075Ed462FA5ba53502cE11610B14BB5cA084;
  // MORPHEUS
  address founder2 = 0x2C0c25561D1239d4EB09E93E13e9e7167Fc320dF;
  // XANMAN
  address founder3 = 0xed5F8f1ab60300011C43923d8ab1BFAda7F0970D;
  // BUNK
  address founder4 = 0xd24F2d1BDD74b6B29a0e21DDfe7D726A7170C159;
  // HIGH RISK MIKEY
  address founder5 = 0x549Ba31aF64fCA21E995B24e110eC371f85Ed26e;

  enum MintStatus {
    CLOSED,
    PRIVATE,
    FOUNDER,
    PUBLIC
  }

  MintStatus public _mintStatus;

  constructor(string memory baseURI) ERC721A("Opulent", "Opulent") {
    _baseTokenURI = baseURI;
  }

  modifier onlyHuman() {
    require(tx.origin == msg.sender, "Naughty Naughty");
    _;
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setFounder() external onlyOwner {
    _mintStatus = MintStatus.FOUNDER;
  }

  function setPrivate() external onlyOwner {
    _mintStatus = MintStatus.PRIVATE;
  }

  function setPublic() external onlyOwner {
    _mintStatus = MintStatus.PUBLIC;
  }

  function setClosed() external onlyOwner {
    _mintStatus = MintStatus.CLOSED;
  }

  function setEndingURI(string memory _endingUri) external onlyOwner {
    endingUri = _endingUri;
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function setMaxSupply(uint256 _maxSupply) external onlyOwner {
    maxSupply = _maxSupply;
  }

  function founderMint() external payable onlyOwner { 
    require(_mintStatus == MintStatus.FOUNDER, 'Founder Mint Not Active');
    require(totalSupply() + 5 <= maxSupply, 'Supply Denied');
    _safeMint(founder1, 1);
    _safeMint(founder2, 1);
    _safeMint(founder3, 1);
    _safeMint(founder4, 1);
    _safeMint(founder5, 1);
  }

  function privateMint() external payable onlyOwner { 
    require(_mintStatus == MintStatus.PRIVATE, 'Private Mint Not Active');
    require(totalSupply() + 50 <= maxSupply, 'Supply Denied');
    _safeMint(msg.sender, 50);
  }

  function mint(uint256 _amount) external payable onlyHuman {
    require(_mintStatus == MintStatus.PUBLIC, 'Public Mint Not Active');
    require(_amount <= 1, 'Max of 1 Mints Allowed');
    require(totalSupply() + _amount <= maxSupply, 'Supply Denied');
    require(msg.value >= price * _amount, 'Ether Amount Denied');
    _safeMint(msg.sender, _amount);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return string(abi.encodePacked(super.tokenURI(tokenId), endingUri));
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function withdraw() external payable onlyOwner {
    uint256 balance = address(this).balance;

    _withdraw(treasuryWallet, (balance * 50) / 100);
    _withdraw(founder1, (balance * 10) / 100);
    _withdraw(founder2, (balance * 10) / 100);
    _withdraw(founder3, (balance * 10) / 100);
    _withdraw(founder4, (balance * 10) / 100);
    _withdraw(founder5, (balance * 10) / 100);
    _withdraw(treasuryWallet, address(this).balance);
  }

  function _withdraw(address _address, uint256 _amount) private {
      (bool success, ) = _address.call{value: _amount}("");
      require(success, "transfer failed");
  }

 function withdrawTreasury() external payable onlyOwner {
    payable(treasuryWallet).transfer(address(this).balance);
 }
}