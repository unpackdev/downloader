// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./SafeCast.sol";
import "./ERC721.sol";
import "./PaymentSplitter.sol";
import "./ERC2981.sol";

struct SaleConfig {
  uint32 preSaleStartTime;
  uint32 publicSaleStartTime;
  uint32 txLimit;
  uint32 supplyLimit;
}

contract InterstellarKnightClub is Ownable, ERC721, ERC2981, PaymentSplitter {
  using SafeCast for uint256;
  using ECDSA for bytes32;

  uint256 public constant mintPrice = 0.077 ether;

  uint256 public totalSupply = 0;

  SaleConfig public saleConfig;
  string public baseURI;
  address public whitelistSigner;

  mapping(address => uint) private presaleMinted;

  bytes32 private DOMAIN_SEPARATOR;
  bytes32 private TYPEHASH = keccak256("presale(address buyer,uint256 limit)");

  address[] private payeeAddresses = [
    0xc89Eec8114fa216D867d1C59892EC4634c74F9e1,
    0x84eF482BCFce278B3632DDf1fc606BFf27B72502,
    0x157a3fE416Bd4C74D32D181C01B5267086e833d2,
    0xE957E3c129002504e0E0Ae9d4aF6296722A063b4,
    0xe05AdCB63a66E6e590961133694A382936C85d9d,
    0x8819A194919f73Ca3137B39198B5b98fBE11E946 
  ];

  uint256[] private payeeShares = [
    21,
    21,
    10,
    1,
    7,
    40
  ];

  constructor(
    string memory inputBaseUri,
    address payable royaltyRecipient
  ) 
  ERC721("InterstellarKnightClub", "DA-IM")
  PaymentSplitter(payeeAddresses, payeeShares)
  {
    baseURI = inputBaseUri;

    saleConfig = SaleConfig({
      preSaleStartTime:     1638937800, //Wed Dec 08 2021 04:30:00 GMT+0000
      publicSaleStartTime:  1639110600, //Fri Dec 10 2021 04:30:00 GMT+0000
      txLimit:              20,
      supplyLimit:          7777
    });

    _setRoyalties(royaltyRecipient, 600); // 6% royalties

    uint256 chainId;
      assembly {
        chainId := chainid()
      }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("InterstellarKnightClub")),
        keccak256(bytes("1")),
        chainId,
        address(this))
    );
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    baseURI = newBaseUri;
  }

  function setWhiteListSigner(address signer) external onlyOwner {
    whitelistSigner = signer;
  }
  
  function setRoyalties(address recipient, uint256 value) external onlyOwner {
    require(recipient != address(0), "zero address");
    _setRoyalties(recipient, value);
  }

  function configureSales(
    uint256 preSaleStartTime,
    uint256 publicSaleStartTime,
    uint256 txLimit,
    uint256 supplyLimit
  ) external onlyOwner {
    uint32 _preSaleStartTime = preSaleStartTime.toUint32();
    uint32 _publicSaleStartTime = publicSaleStartTime.toUint32();
    uint32 _txLimit = txLimit.toUint32();
    uint32 _supplyLimit = supplyLimit.toUint32();

    require(0 < _preSaleStartTime, "Invalid time");
    require(_preSaleStartTime < _publicSaleStartTime, "Invalid time");

    saleConfig = SaleConfig({
      preSaleStartTime: _preSaleStartTime,
      publicSaleStartTime: _publicSaleStartTime,
      txLimit: _txLimit,
      supplyLimit: _supplyLimit
    });
  }

  function whitelistBuy(bytes memory signature, uint numberOfTokens, uint approvedLimit) external payable {
    SaleConfig memory _saleConfig = saleConfig;

    require(block.timestamp >= _saleConfig.preSaleStartTime && block.timestamp < _saleConfig.publicSaleStartTime, "Presale is not active");
    require(whitelistSigner != address(0), "Whitelist signer not yet set");
    require((presaleMinted[msg.sender] + numberOfTokens) <= approvedLimit, "Wallet limit exceeded");
    require(msg.value == mintPrice * numberOfTokens, "Incorrect payment");
    
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(TYPEHASH, msg.sender, approvedLimit))));

    address signer = digest.recover(signature);

    require(signer != address(0) && signer == whitelistSigner, "Invalid signature");

    presaleMinted[msg.sender] = presaleMinted[msg.sender] + numberOfTokens;
    mint(msg.sender, numberOfTokens);
  }

  function publicBuy(uint numberOfTokens) external payable {
    SaleConfig memory _saleConfig = saleConfig;

    require(block.timestamp >= _saleConfig.publicSaleStartTime, "Sale is not active");
    require(numberOfTokens <= _saleConfig.txLimit, "Transaction limit exceeded");
    require(msg.value == mintPrice * numberOfTokens, "Incorrect payment");

    mint(msg.sender, numberOfTokens);
  }

  function mint(address to, uint numberOfTokens) private {
    require(totalSupply + numberOfTokens <= saleConfig.supplyLimit, "Not enough tokens left");

    uint256 newId = totalSupply;

    for(uint i = 0; i < numberOfTokens; i++) {
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