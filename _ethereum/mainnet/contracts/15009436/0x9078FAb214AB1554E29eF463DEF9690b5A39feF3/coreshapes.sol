// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./ECDSA.sol";
import "./Strings.sol";

import "./AddressString.sol";


contract CORESHAPES is Ownable, ERC721A, ReentrancyGuard {
  uint256 public immutable maxPerAddressDuringMint;
  uint256 public immutable reserved;
  uint256 public immutable collectionSize;
  uint256 public immutable maxBatchSize;

  struct SaleConfig {
    uint32 whitelistSaleStartTime;
    uint32 publicSaleStartTime;
    uint64 priceWei;
    address whitelistSigner;
  }

  SaleConfig public config;

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    uint256 reserved_
  )
  ERC721A(name_, symbol_)
  {
    reserved = reserved_;
    maxBatchSize = maxBatchSize_;
    collectionSize = collectionSize_;
    maxPerAddressDuringMint = 3;
    config.priceWei = 0 ether;
    require(reserved_ <= collectionSize_);
    require(maxBatchSize_ <= collectionSize_);
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function _startTokenId() internal override view virtual returns (uint256) {
      return 1;
  }

  function whitelistMint(
      uint256 quantity,
      bytes memory signature
  )
    external
    payable
    callerIsUser
  {
    uint256 price = uint256(config.priceWei);
    uint256 whitelistSaleStartTime = uint256(config.whitelistSaleStartTime);

    require(
      isSaleOn(price, whitelistSaleStartTime),
      "whitelist sale has not begun yet"
    );

    require(
      totalSupply() + quantity <= collectionSize,
      "not enough remaining reserved for sale to support desired mint amount"
    );

    require(
      numberMinted(msg.sender) + quantity <= 1,
      "can not mint this many"
    );

    bytes memory data = abi.encodePacked(
        AddressString.toAsciiString(msg.sender),
        ":1"
    );
    bytes32 hash = ECDSA.toEthSignedMessageHash(data);
    address signer = ECDSA.recover(hash, signature);

    require(
        signer == config.whitelistSigner,
        "wrong signature"
    );

    uint256 totalCost = price * quantity;
    _safeMint(msg.sender, quantity);
    refundIfOver(totalCost);
  }

  function mint(uint256 quantity)
    external
    payable
    callerIsUser
  {
    uint256 publicPrice = uint256(config.priceWei);
    uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);

    require(
      isSaleOn(publicPrice, publicSaleStartTime),
      "sale has not begun yet"
    );
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(
      numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
      "can not mint this many"
    );
    _safeMint(msg.sender, quantity);
    refundIfOver(publicPrice * quantity);
  }

  function refundIfOver(uint256 price)
    private
  {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function isSaleOn(uint256 _price, uint256 _startTime)
    public
    view
    returns (bool)
  {
    return _price != 0 && _startTime != 0 && block.timestamp >= _startTime;
  }


  function setPrice(uint64 price)
    external
    onlyOwner
  {
    config.priceWei = price;
  }


  function setWhitelistSaleConfig(uint32 timestamp, address signer)
    external
    onlyOwner
  {
    config.whitelistSaleStartTime = timestamp;
    config.whitelistSigner = signer;
  }

  function setPublicSaleConfig(uint32 timestamp)
    external
    onlyOwner
  {
      config.publicSaleStartTime = timestamp;
  }

  // For marketing etc.
  function reserve(uint256 quantity)
    external
    onlyOwner
  {
    require(
      totalSupply() + quantity <= reserved,
      "too many already minted before dev mint"
    );
    require(
      quantity % maxBatchSize == 0,
      "can only mint a multiple of the maxBatchSize"
    );
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

  // // metadata URI
  string private _baseTokenURI;

  function _baseURI()
    internal
    view
    virtual
    override
    returns (string memory)
  {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI)
    external
    onlyOwner
  {
    _baseTokenURI = baseURI;
  }

  function withdraw()
    external
    onlyOwner
    nonReentrant
  {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function numberMinted(address owner)
    public
    view
    returns (uint256)
  {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return _ownershipOf(tokenId);
  }

  function totalMinted()
    public
    view
    returns (uint256)
  {
      // Counter underflow is impossible as _currentIndex does not decrement,
      // and it is initialized to _startTokenId()
      unchecked {
          return _currentIndex - _startTokenId();
      }
  }
}
