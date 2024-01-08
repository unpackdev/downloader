pragma solidity ^0.7.6;

import "./ERC721.sol";
import "./Ownable.sol";


contract EtherBosoms is ERC721, Ownable {
  uint256 public numAvailable;
  address payable public withdrawalAddress;
  uint256 public mintStart;
  uint256 public mintPrice;

  constructor(
      string memory _baseURI, 
      uint256 _numAvailable, 
      address payable _withdrawalAddress, 
      uint256 _mintStart,
      uint256 _mintPrice
      ) ERC721("EtherBosoms","ETHERBOSOMS")  {
    setBaseURI(_baseURI);
    withdrawalAddress = _withdrawalAddress;
    numAvailable = _numAvailable;
    mintStart = _mintStart;
    mintPrice = _mintPrice;
    for (uint256 i = 0; i < 20; i++) doMint();
  }

  function doMint() private {
    require(numAvailable > 0, "No more available");
    uint256 tokenId = totalSupply() + 1;
    numAvailable--;
    _safeMint(msg.sender, tokenId);
  }

  function mint(uint256 number) external payable {
    require(block.timestamp >= mintStart, "Too early");
    require(msg.value >= (number * mintPrice), "Not enough eth");
    for (uint256 i = 0; i < number; i++) {
      doMint();
    }
  }

  function tokensOfOwner(address owner) external view returns(uint256[] memory) {
    uint256 balance = balanceOf(owner);
    if (balance == 0) {
      return new uint256[](0);
    }
    uint256[] memory result = new uint256[](balance);
    for (uint256 i = 0; i < balance; i++) {
      result[i] = tokenOfOwnerByIndex(owner, i);
    }
    return result;
  }

  function setMintStart(uint256 _mintStart) external onlyOwner {
    mintStart = _mintStart;
  }

  function setMintPrice(uint256 _mintPrice) external onlyOwner {
    mintPrice = _mintPrice;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _setBaseURI(baseURI);
  }

  function withdraw() external {
    (bool success, ) = withdrawalAddress.call{value: address(this).balance}("");
    require(success, "Failed");
  }
}