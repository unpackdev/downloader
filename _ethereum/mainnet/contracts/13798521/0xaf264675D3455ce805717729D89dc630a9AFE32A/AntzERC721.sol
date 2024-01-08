// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Whitelisted.sol";

contract AntzERC721 is ERC721, Ownable, ReentrancyGuard, Whitelisted {
  using Address for address;

  uint256 internal _tokenIds;
  uint256 internal _reserved;
  uint256 internal _presaleMinted;
  string internal _baseTokenURI;
  
  string public FIRST_BATCH_PROVENANCE = "";
  string public SECOND_BATCH_PROVENANCE = "";

  uint256 constant public MAX_MINT = 10;
  uint256 constant public PRESALE_MAX_MINT = 3;
  uint256 constant public MINT_PRICE = 0.069 ether;
  uint256 constant public MAX_FIRST_BATCH = 5151;
  uint256 constant public MAX_SUPPLY = 10000;
  uint256 constant public MAX_RESERVED = 100;
  bool public presaleActive;
  bool public firstBatchActive;
  bool public saleActive;
  mapping(address => uint256) public presaleMints;

  constructor(
    address signer
  )
    ERC721("AntzNFT", "ANTZ")
    Whitelisted(signer)
  {}

  function totalSupply() external view returns (uint256) {
    return _tokenIds;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseTokenURI(string memory URI) public onlyOwner {
    _baseTokenURI = URI;
  }

  function setFirstProvenanceHash(string memory provenanceHash) public onlyOwner {
      FIRST_BATCH_PROVENANCE = provenanceHash;
  }

  function setSecondProvenanceHash(string memory provenanceHash) public onlyOwner {
      SECOND_BATCH_PROVENANCE = provenanceHash;
  }

  function flipPresaleActive() public onlyOwner {
    presaleActive = !presaleActive;
  }

  function flipFirstBatchActive() public onlyOwner {
    firstBatchActive = !firstBatchActive;
  }

  function flipSaleActive() public onlyOwner {
    saleActive = !saleActive;
  }

  function reserve(uint256 amount, address to) public onlyOwner {
    require(_reserved + amount <= MAX_RESERVED, "Exceeds maximum number of reserved tokens");

    _mintAmount(amount, to);
    _reserved += amount;
  }

  function presaleMint(bytes32 messageHash, bytes memory signature, uint256 amount)
    public
    payable
    nonReentrant
    processSignature(messageHash, signature)
  {
    require(presaleActive,                                         "Presale has not started");
    require(msg.value == MINT_PRICE * amount,                      "Invalid Ether amount sent");
    require(presaleMints[msg.sender] + amount <= PRESALE_MAX_MINT, "Exceeds remaining presale balance");
    require(_tokenIds + amount < MAX_SUPPLY,  "Exceeds maximum number of tokens");

    _mintAmount(amount, msg.sender);

    presaleMints[msg.sender] += amount;
    _presaleMinted += amount;
  }

  function mintFirstBatch(uint256 amount) public payable nonReentrant {
    require(firstBatchActive,                             "Public sale has not started");
    require(msg.value == MINT_PRICE * amount,       "Invalid Ether amount sent");
    require(amount <= MAX_MINT,                     "Exceeds the maximum amount to mint at once");
    require(_tokenIds + amount < MAX_FIRST_BATCH,   "Exceeds maximum number of tokens");

    _mintAmount(amount, msg.sender);
  }

  function mint(uint256 amount) public payable nonReentrant {
    require(saleActive,                       "Public sale has not started");
    require(msg.value == MINT_PRICE * amount, "Invalid Ether amount sent");
    require(amount <= MAX_MINT,               "Exceeds the maximum amount to mint at once");
    require(_tokenIds + amount < MAX_SUPPLY,  "Exceeds maximum number of tokens");

    _mintAmount(amount, msg.sender);
  }

  function _mintAmount(uint256 amount, address to) internal {

    for (uint256 i = 0; i < amount; i++) {
      _safeMint(to, _tokenIds);
      _tokenIds += 1;
    }
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}
