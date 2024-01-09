// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract EthereumEstates is ERC721, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using ECDSA for bytes32;
  using Counters for Counters.Counter;
  using Strings for uint256;

  uint256 public MAX_Ethereum_Estates;
  uint256 public MAX_Ethereum_Estates_PER_PURCHASE;
  uint256 public MAX_Ethereum_Estates_WHITELIST_CAP;
  uint256 public Ethereum_Estates_PRICE = 0.05 ether;
  uint256 public constant RESERVED_Ethereum_Estates = 50;

  string public tokenBaseURI;
  string public unrevealedURI;
  bool public presaleActive = false;
  bool public mintActive = false;
  bool public reservesMinted = false;

  mapping(address => uint256) private whitelistAddressMintCount;

  Counters.Counter public tokenSupply;

  constructor(
    uint256 _maxEthereumEstates,
    uint256 _maxEthereumEstatesPerPurchase,
    uint256 _maxEthereumEstatesWhitelistCap
  ) ERC721("EthereumEstates", "ETHE") {
    MAX_Ethereum_Estates = _maxEthereumEstates;
    MAX_Ethereum_Estates_PER_PURCHASE = _maxEthereumEstatesPerPurchase;
    MAX_Ethereum_Estates_WHITELIST_CAP = _maxEthereumEstatesWhitelistCap;
  }

  function setPrice(uint256 _newPrice) external onlyOwner {
    Ethereum_Estates_PRICE = _newPrice;
  }

  function setTokenBaseURI(string memory _baseURI) external onlyOwner {
    tokenBaseURI = _baseURI;
  }

  function setUnrevealedURI(string memory _unrevealedUri) external onlyOwner {
    unrevealedURI = _unrevealedUri;
  }

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    bool revealed = bytes(tokenBaseURI).length > 0;

    if (!revealed) {
      return unrevealedURI;
    }

    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked(tokenBaseURI, _tokenId.toString()));
  }
  function presaleMint(uint256 _quantity, bytes calldata _whitelistSignature) external payable nonReentrant {
    require(presaleActive, "Presale is not active");
    require(verifyOwnerSignature(keccak256(abi.encode(msg.sender)), _whitelistSignature), "Invalid whitelist signature");
    require(_quantity <= MAX_Ethereum_Estates_WHITELIST_CAP, "You can only mint a maximum of 3 for presale");
    require(whitelistAddressMintCount[msg.sender].add(_quantity) <= MAX_Ethereum_Estates_WHITELIST_CAP, "This purchase would exceed the maximum Ethereum Estates you are allowed to mint in the presale");

    whitelistAddressMintCount[msg.sender] += _quantity;
    _safeMintEthereumEstates(_quantity);
  }

  function publicMint(uint256 _quantity) external payable nonReentrant {
    require(mintActive, "Sale is not active.");
    require(_quantity <= MAX_Ethereum_Estates_PER_PURCHASE, "Quantity is more than allowed per transaction.");

    _safeMintEthereumEstates(_quantity);
  }

  function _safeMintEthereumEstates(uint256 _quantity) internal {
    require(_quantity > 0, "You must mint at least 1 Ethereum Estates");
    require(tokenSupply.current().add(_quantity) <= MAX_Ethereum_Estates, "This purchase would exceed max supply of Ethereum Estates");
    require(msg.value >= Ethereum_Estates_PRICE.mul(_quantity), "The ether value sent is not correct");

    for (uint256 i = 0; i < _quantity; i++) {
      uint256 mintIndex = tokenSupply.current();

      if (mintIndex < MAX_Ethereum_Estates) {
        tokenSupply.increment();
        _safeMint(msg.sender, mintIndex);
      }
    }
  }

  function mintReservedEthereumEstates() external onlyOwner {
    require(!reservesMinted, "Reserves have already been minted.");
    require(tokenSupply.current().add(RESERVED_Ethereum_Estates) <= MAX_Ethereum_Estates, "This mint would exceed max supply of Ethereum Estates");

    for (uint256 i = 0; i < RESERVED_Ethereum_Estates; i++) {
      uint256 mintIndex = tokenSupply.current();

      if (mintIndex < MAX_Ethereum_Estates) {
        tokenSupply.increment();
        _safeMint(msg.sender, mintIndex);
      }
    }

    reservesMinted = true;
  }

  function setPresaleActive(bool _active) external onlyOwner {
    presaleActive = _active;
  }

  function setMintActive(bool _active) external onlyOwner {
    mintActive = _active;
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function verifyOwnerSignature(bytes32 hash, bytes memory signature) private view returns(bool) {
    return hash.toEthSignedMessageHash().recover(signature) == owner();
  }
}