// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract RoboPianoLoops is ERC721Enumerable, Ownable {
  string public ALL_MP3_HASH =
    "e8b25e7502c1ae3692c1085c11bd8afca5a05b380d87d93c46d04ef29e657e1c";

  function setHash(string memory h) public onlyOwner {
    ALL_MP3_HASH = h;
  }

  uint256 public MAX_TOKENS = 1024;

  function setMaxTokens(uint256 n) public onlyOwner {
    require(n > MAX_TOKENS, "Unable to decrease supply");
    MAX_TOKENS = n;
  }

  uint256 public MAX_TOKENS_PER_PURCHASE = 64;

  function setMaxTokensPerPurchase(uint256 n) public onlyOwner {
    MAX_TOKENS_PER_PURCHASE = n;
  }

  string public BASE_URI =
    "https://robo-piano-loops.s3.us-east-1.amazonaws.com/token/";

  function setBaseUri(string memory s) public onlyOwner {
    BASE_URI = s;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return BASE_URI;
  }

  uint256 public PRICE_PER_TOKEN = 0.025 * 10**18; // 0.025 Ether

  function setPricePerToken(uint256 _newPrice) public onlyOwner {
    PRICE_PER_TOKEN = _newPrice;
  }

  bool public IS_SALE_ACTIVE = true;

  function setIsSaleActive(bool b) public onlyOwner {
    IS_SALE_ACTIVE = b;
  }

  constructor() ERC721("RoboPianoLoops", "RPLOOP") {}

  function _mintTokens(
    address _to,
    uint256 fromTokenId,
    uint256 toTokenId
  ) private {
    require(fromTokenId == totalSupply(), "Invalid range start");
    require(toTokenId < MAX_TOKENS, "Invalid range end");
    for (uint256 i = fromTokenId; i <= toTokenId; i++) {
      _safeMint(_to, i);
    }
  }

  function reserveTokens(
    address _to,
    uint256 fromTokenId,
    uint256 toTokenId
  ) public onlyOwner {
    _mintTokens(_to, fromTokenId, toTokenId);
  }

  function mint(uint256 fromTokenId, uint256 toTokenId) public payable {
    require(IS_SALE_ACTIVE, "Sale is not active");

    uint256 numBuying = 1 + (toTokenId - fromTokenId);

    require(
      numBuying <= MAX_TOKENS_PER_PURCHASE,
      "Exceeds MAX_TOKENS_PER_PURCHASE"
    );
    require(
      msg.value >= PRICE_PER_TOKEN * numBuying,
      "Insufficient ether sent"
    );

    _mintTokens(msg.sender, fromTokenId, toTokenId);
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}
