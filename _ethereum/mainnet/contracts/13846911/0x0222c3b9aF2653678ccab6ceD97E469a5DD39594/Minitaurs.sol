// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ERC721.sol";
import "./ERC2981.sol";

struct SaleConfig {
  uint32 preSaleStartTime;
  uint32 publicSaleStartTime;
  uint32 txLimit;
  uint32 supplyLimit;
}

contract Minitaurs is Ownable, ERC721, ERC2981, PaymentSplitter {
  uint256 public constant mintPrice = 0.06969 ether;
  uint256 public constant supplyLimit = 7777;
  uint256 public constant txLimit = 10;

  uint256 public saleStartTime = 1640138400; // Wed Dec 22 2021 02:00:00 GMT+0000

  uint256 public totalSupply;

  string public baseURI;

  address[] private payeeAddresses = [
    0xFa65B0e06BB42839aB0c37A26De4eE0c03B30211,
    0x09e339CEF02482f4C4127CC49C153303ad801EE0,
    0x8bffc7415B1F8ceA3BF9e1f36EBb2FF15d175CF5,
    0xe05AdCB63a66E6e590961133694A382936C85d9d,
    0x06B312F34e142402ebdD446431e83D609F9b4926 
  ];

  uint256[] private payeeShares = [30, 30, 15, 20, 5];

  constructor(string memory inputBaseUri)
    ERC721("Minitaurs", "MINI")
    PaymentSplitter(payeeAddresses, payeeShares)
  {
    baseURI = inputBaseUri;

    _setRoyalties(0x06B312F34e142402ebdD446431e83D609F9b4926, 500); // 5% royalties
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    baseURI = newBaseUri;
  }

  function setRoyalties(address recipient, uint256 value) external onlyOwner {
    require(recipient != address(0), "zero address");
    _setRoyalties(recipient, value);
  }

  function changeSaleStartTime(uint256 newSaleStartTime) external onlyOwner {
    saleStartTime = newSaleStartTime;
  }

  function buy(uint256 numberOfTokens) external payable {
    require(block.timestamp >= saleStartTime, "Sale is not active");
    require(numberOfTokens <= txLimit, "Transaction limit exceeded");
    require(msg.value == mintPrice * numberOfTokens, "Incorrect payment");

    mint(msg.sender, numberOfTokens);
  }

  function mint(address to, uint256 numberOfTokens) private {
    require(
      (totalSupply + numberOfTokens) <= supplyLimit,
      "Not enough tokens left"
    );

    uint256 newId = totalSupply;

    for (uint256 i = 0; i < numberOfTokens; i++) {
      newId += 1;
      _safeMint(to, newId);
    }

    totalSupply = newId;
  }

  function reserve(address to, uint256 numberOfTokens) external onlyOwner {
    mint(to, numberOfTokens);
  }

  function withdraw() external onlyOwner {
    require(address(this).balance > 0, "No balance to withdraw");

    for (uint256 i = 0; i < payeeAddresses.length; i++) {
      release(payable(payee(i)));
    }
  }

  /// @inheritdoc	ERC165
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
