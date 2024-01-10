// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

contract FreedomVersePass is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using ECDSA for bytes32;

  uint256 public PUBLIC_AMT = 8838;
  uint256 public GIFT_AMT = 50;
  uint256 public MAX_AMT = GIFT_AMT + PUBLIC_AMT;
  uint256 public PASS_PRICE = .1 ether;
  uint256 public constant MAX_PER_TXN = 10;
  uint256 public constant MAX_PER_PRESALE = 10;
  uint256 public publicAmountMinted;
  bool public saleActive = false;
  bool public preSaleActive = true;

  address private freeSignerAddress = 0x1E2646181a24e2EeEF56Ad7fa29aAA260d35544C;
  address private whitelistSignerAddress = 0x4a9Db6E418426AAa1C65602df501F4c35559BC3e;
  address public communityWalletAddress = 0x50415354BD4908b81422359a1d6D147A5bc53Bd9;

  string private _tokenBaseURI = "https://ipfs.io/ipfs/Qmdxd4kqRu61hEp6EAPzzfa15N5z4b2aJ1yufcRUs1Bmo8/";

  mapping (address => bool) public hasAddressMintedFree;
  mapping (address => uint256) public amountClaimedPresale;

  constructor() ERC721A("FreedomVerse", "FREE") {}

  function toggleSaleStatus() external onlyOwner {saleActive = !saleActive;}

  function togglePreSaleStatus() external onlyOwner {preSaleActive = !preSaleActive;}

  function setCommunityWalletAddress(address _communityWalletAddress) external onlyOwner {
    require(_communityWalletAddress != address(0));
    communityWalletAddress = _communityWalletAddress;
  }

  function setFreeSignerAddress(address _freeSignerAddress) external onlyOwner {
    require(_freeSignerAddress != address(0));
    freeSignerAddress = _freeSignerAddress;
  }

  function setWhitelistSignerAddress(address _whitelistSignerAddress) external onlyOwner {
    require(_whitelistSignerAddress != address(0));
    whitelistSignerAddress = _whitelistSignerAddress;
  }

  function verifyAddressSigner(address signerAddress, bytes32 messageHash, bytes memory signature) private pure returns (bool) {
    return signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
  }

  function hashMessage(address sender) private pure returns (bytes32) {
    return keccak256(abi.encode(sender));
  }

  function mintPass(uint256 numberOfPasses) external payable nonReentrant {
    require(saleActive, "SALE_NOT_ACTIVE");
    require(publicAmountMinted + numberOfPasses <= PUBLIC_AMT, "WOULD_EXCEED_PUBLIC");
    require(totalSupply() < MAX_AMT, "WOULD_EXCEED_MAX_SUPPLY");
    require(numberOfPasses <= MAX_PER_TXN, "EXCEED_MAX_PER_TXN");
    require(numberOfPasses > 0, "MUST_MINT_AT_LEAST_ONE_TOKEN");
    require(PASS_PRICE * numberOfPasses <= msg.value, "INSUFFICIENT_ETH");

    publicAmountMinted += numberOfPasses;
    _safeMint(msg.sender, numberOfPasses);
  }

  function mintPresale(uint256 numberOfPasses, bytes32 messageHash, bytes calldata signature) external payable nonReentrant {
    require(preSaleActive, "PRE_SALE_NOT_ACTIVE");
    require(publicAmountMinted + numberOfPasses <= PUBLIC_AMT, "WOULD_EXCEED_PUBLIC");
    require(totalSupply() < MAX_AMT, "WOULD_EXCEED_MAX_SUPPLY");
    require(numberOfPasses <= MAX_PER_TXN, "EXCEED_MAX_PER_TXN");
    require(numberOfPasses > 0, "MUST_MINT_AT_LEAST_ONE_TOKEN");
    require(amountClaimedPresale[msg.sender] + numberOfPasses <= MAX_PER_PRESALE, "WOULD_EXCEED_MAX_PRESALE_AMOUNT");
    require(hashMessage(msg.sender) == messageHash, "MESSAGE_INVALID");
    require(verifyAddressSigner(whitelistSignerAddress, messageHash, signature), "SIGNATURE_VALIDATION_FAILED");
    require(PASS_PRICE * numberOfPasses <= msg.value, "INSUFFICIENT_ETH");

    amountClaimedPresale[msg.sender] += numberOfPasses;
    publicAmountMinted += numberOfPasses;

    _safeMint(msg.sender, numberOfPasses);
  }

  function mintFree(bytes32 messageHash, bytes calldata signature) external payable nonReentrant {
    require(preSaleActive, "PRE_SALE_NOT_ACTIVE");
    require(publicAmountMinted + 1 <= PUBLIC_AMT, "WOULD_EXCEED_PUBLIC");
    require(totalSupply() < MAX_AMT, "WOULD_EXCEED_MAX_SUPPLY");
    require(hasAddressMintedFree[msg.sender] == false, "ADDRESS_HAS_ALREADY_MINTED_FREE_PASS");
    require(hashMessage(msg.sender) == messageHash, "MESSAGE_INVALID");
    require(verifyAddressSigner(freeSignerAddress, messageHash, signature), "SIGNATURE_VALIDATION_FAILED");
    
    hasAddressMintedFree[msg.sender] = true;

    publicAmountMinted++;
    _safeMint(msg.sender, 1);
  }

  function giftPass(address[] calldata receivers, uint256 numberOfPasses) external onlyOwner nonReentrant {
    require(numberOfPasses > 0, "MUST_MINT_AT_LEAST_ONE_TOKEN");
    require(numberOfPasses <= 10, "MAX_10_PER_TRANSACTION");
    require((totalSupply() + (receivers.length * numberOfPasses)) <= MAX_AMT, "WOULD_EXCEED_MAX_SUPPLY");
    for (uint256 i = 0; i < receivers.length; i++) {
      _safeMint(receivers[i], numberOfPasses);
    }
  }

  function withdrawTeam() external onlyOwner nonReentrant {
    uint balance = address(this).balance;
    payable(0x8ec1B011d438DccB8Fde1f9898bD3fB460488109).transfer((balance*10)/100); // m
    payable(0x03D247E0EdE367f4931f88F252603E82c0B2ba96).transfer((balance*10)/100); // f
    payable(0x40eE01bC3477ce2c5A6B2E113cdd8106ee888e30).transfer((balance*10)/100); // s
    payable(0xe90b1FD2199c7A8D861AC94AdEF90661b1d2C132).transfer((balance*20)/100); // n
    payable(communityWalletAddress).transfer((balance*50)/100); // c
  }

  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _tokenBaseURI;
  }

  function setBaseURI(string calldata URI) external onlyOwner {
    _tokenBaseURI = URI;
  }

  function setPublicAmount(uint256 number) external onlyOwner {
    PUBLIC_AMT = number;
    MAX_AMT = GIFT_AMT + PUBLIC_AMT;
  }

  function setPrice(uint256 number) external onlyOwner {PASS_PRICE = number;}

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
    return ownershipOf(tokenId);
  }
}
