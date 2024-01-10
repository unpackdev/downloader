// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ERC721A.sol";

contract SevenDay is ERC721A, Ownable {
  bool public paused = false;
  string public baseURI;
  uint256 public constant maxMintAmount = 2;
  uint256 public constant maxSupply = 1024;
  uint256 public constant cost = 0.01 ether; 
  mapping(uint256=>uint256) private timestampID;


  constructor(string memory initBaseURI) ERC721A("7DayNFT", "7Day") {
    baseURI = initBaseURI;
    _safeMint(msg.sender, 1);
  }

  modifier mintCompliance(uint256 _mintAmount) 
  {
    require(!paused, "Yi jing ting zhi || Had stop");
    require(tx.origin == msg.sender, "Bie diao yong he yue, huo ji. || No contract");
    require(_mintAmount > 0 && _mintAmount <= maxMintAmount, "Shu liang bie chao guo 3 huo zhe xiao yu 0 || Number is wrong");
    require(totalSupply() + _mintAmount <= maxSupply, "Lai wan le, chi shi dou gan bu shang re de || You are late");
    _;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function viewTimeStampID(uint256 _id) public view returns (uint256){
    return timestampID[_id];
  }

  function mint(uint256 quantity) external payable mintCompliance(quantity) {
    require(numberMinted(msg.sender) + quantity <= maxMintAmount,"Yi jing mint");
    require(msg.value >= cost * quantity, "Qian mei dao wei || So less money");
    _safeMint(msg.sender, quantity);
    if (quantity>1){
        timestampID[totalSupply()-1] = block.timestamp;
        timestampID[totalSupply()-2] = block.timestamp;
    }else
    {
        timestampID[totalSupply()-1] = block.timestamp;
    }
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function setPaused(bool _state) external onlyOwner {
    paused = _state;
  }

  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function withdraw() external onlyOwner {
    require(totalSupply()>1020,"Zong Liang bu dao");
    require(block.timestamp - timestampID[1020]> 7 days,"Shi jian bu dao");
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function refund(uint256 tokenId) public {
      require(tx.origin == msg.sender, "Bie diao yong he yue, huo ji. || No contract");
      require(block.timestamp - timestampID[tokenId] < 7 days,"shi jian chao guo 7 tian || Had gone 7 days");
      transferFrom(msg.sender,0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B,tokenId);
      payable(msg.sender).transfer(0.01 ether);
  }
}