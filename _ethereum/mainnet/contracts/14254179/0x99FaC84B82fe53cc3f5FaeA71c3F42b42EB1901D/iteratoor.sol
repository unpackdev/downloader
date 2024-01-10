// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract iteratoor is ERC721, IERC2981, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  constructor (string memory customBaseURI_) ERC721("iteratoor", "itr8r") {
    customBaseURI = customBaseURI_;
  }

  uint256 public constant MAX_SUPPLY = 420;

  uint256 public constant MAX_MULTIMINT = 10;

  uint256 public constant PRICE = 220000000000000000;

  Counters.Counter private supplyCounter;

  function mint(uint256 count) public payable nonReentrant {
    require(saleIsActive, "Sale not active yet!");

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply!");

    require(count <= MAX_MULTIMINT, "Max 10 per tx!");

    require(
      msg.value >= PRICE * count, "Sorry, not enough ETH!"
    );

    for (uint256 i = 0; i < count; i++) {
      _safeMint(_msgSender(), totalSupply());

      supplyCounter.increment();
    }
  }

  function totalSupply() public view returns (uint256) {
    return supplyCounter.current();
  }


  bool public saleIsActive = false;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  string private customBaseURI;

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  address private constant payoutAddress1 = 0x5B8e137417450C46B8C0190Fcc2d8025063a00C7;

  address private constant payoutAddress2 = 0x1C3334fA0A383DB77434F544C6F0227e89094ea9;

  address private constant payoutAddress3 = 0x0A0cc8D18643A33f633A789b6c1783A1573676D0;

  address private constant royalties = 0xc5a8DA73a8D26F59b9A500C59c4A3cAdE3664b7d;

  function withdraw() public {
    uint256 balance = address(this).balance;

    payable(payoutAddress1).transfer(balance * 40 / 100);

    payable(payoutAddress2).transfer(balance * 40 / 100);

    payable(payoutAddress3).transfer(balance * 20 / 100);
  }


  function royaltyInfo(uint256, uint256 salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
  {
    return (address(royalties), (salePrice * 1000) / 10000);
  }
}
