// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract BeachBabes is ERC721, Ownable {
  using SafeMath for uint256;

  string public PROVENANCE = "0ea0786df089e834de83b37a84c7f1a6e643ad19e6e3856567bbe953c81d30db";

  uint256 public constant MAX_TOKENS = 3918; // 0-3917

  uint256 public constant MAX_TOKENS_PER_PURCHASE = 10;

  uint256 private price = 25000000000000000; // 0.025 Ether
  // uint256 private price = 250000000000000; // for dev

  bool public isSaleActive = true;

  event Mint(address indexed from, uint256 tokenId, uint256 timestamp);

  constructor(uint256 _reserveAmount) ERC721("BeachBabes", "BBABE") {
    // pre-mint reserved tokens
    uint256 supply = totalSupply();
    for (uint256 i = 0; i < _reserveAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function mint(uint256 _count) public payable {
    uint256 totalSupply = totalSupply();

    require(isSaleActive, "Sale is not active");
    require(
      _count > 0 && _count < MAX_TOKENS_PER_PURCHASE + 1,
      "Exceeds maximum tokens you can purchase in a single transaction"
    );
    require(totalSupply + _count < MAX_TOKENS + 1, "Exceeds maximum tokens available for purchase");
    require(msg.value >= price.mul(_count), "Ether value sent is not correct");

    for (uint256 i = 0; i < _count; i++) {
      _safeMint(msg.sender, totalSupply + i);
      emit Mint(msg.sender, totalSupply + 1, block.timestamp);
    }
  }

  function setBaseURI(string memory _baseURI) public onlyOwner {
    _setBaseURI(_baseURI);
  }

  function flipSaleStatus() public onlyOwner {
    isSaleActive = !isSaleActive;
  }

  function setPrice(uint256 _newPrice) public onlyOwner {
    price = _newPrice;
  }

  function getPrice() public view returns (uint256) {
    return price;
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    msg.sender.transfer(balance);
  }

  function tokensByOwner(address _owner) external view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 index;
      for (index = 0; index < tokenCount; index++) {
        result[index] = tokenOfOwnerByIndex(_owner, index);
      }
      return result;
    }
  }
}
