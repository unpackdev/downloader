// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.9 <0.9.0;

import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol"; 

contract DAOZER is ERC721, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  address private payee;

    /** MINTING **/
  uint256 public MAX_LEGENDARY_PER_WALLET;
  uint256 public MAX_EPIC_PER_WALLET;
  uint256 public EPIC_PRICE;
  uint256 public LEGENDARY_PRICE;
  uint256 public MAX_LEGENDARY_SUPPLY;
  uint256 public MAX_EPIC_SUPPLY;
  uint256 public MAX_SUPPLY;
  uint256 public MAX_LEGENDARY_RESERVED_SUPPLY;
  uint256 public MAX_EPIC_RESERVED_SUPPLY;
  uint256 public MAX_MULTIMINT;

  constructor (
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _customBaseURI,
    address _payee,
    uint256 _epicPrice,
    uint256 _legendaryPrice
   ) ERC721(_tokenName, _tokenSymbol) {
    payee = _payee;
    customBaseURI = _customBaseURI;
    LEGENDARY_PRICE = _legendaryPrice;
    EPIC_PRICE = _epicPrice;
    MAX_EPIC_PER_WALLET = 1;
    MAX_LEGENDARY_PER_WALLET = 1;
    MAX_MULTIMINT = 1;
    MAX_LEGENDARY_SUPPLY = 11000;
    MAX_EPIC_SUPPLY = 11000;
    MAX_LEGENDARY_RESERVED_SUPPLY = 1000;
    MAX_EPIC_RESERVED_SUPPLY = 1000;
    MAX_SUPPLY = MAX_LEGENDARY_SUPPLY + MAX_EPIC_SUPPLY;
  }

  /** PAYEE **/

  function beneficiary() public view virtual returns (address) {
    return payee;
  }

  /** ADMIN FUNCTIONS **/

  function setBeneficiary(address newPayee) external onlyOwner {
      payee = newPayee;
  }

  bool public saleIsActive = true;

  function flipSaleState() external onlyOwner {
    saleIsActive = !saleIsActive;
  }

  function setLegendaryPrice(uint256 price) external onlyOwner {
    LEGENDARY_PRICE = price;
  }

  function setEpicPrice(uint256 price) external onlyOwner {
    EPIC_PRICE = price;
  }

  function setEpicLimitPerWallet(uint256 maxPerWallet) external onlyOwner {
    MAX_EPIC_PER_WALLET = maxPerWallet;
  }

  function setLegendaryLimitPerWallet(uint256 maxPerWallet) external onlyOwner {
    MAX_LEGENDARY_PER_WALLET = maxPerWallet;
  }

  function setMultiMint(uint256 maxMultiMint) external onlyOwner {
    MAX_MULTIMINT = maxMultiMint;
  }

  /** MINTING LIMITS **/

  mapping(address => uint256) private legendaryMintCountMap;
  mapping(address => uint256) private epicMintCountMap;

  function allowedLegendaryMintCount(address minter) public view returns (uint256) {
    return MAX_LEGENDARY_PER_WALLET - legendaryMintCountMap[minter];
  }

  function updateLegendaryMintCount(address minter, uint256 count) private {
    legendaryMintCountMap[minter] += count;
  }

    function allowedEpicMintCount(address minter) public view returns (uint256) {
    return MAX_EPIC_PER_WALLET - epicMintCountMap[minter];
  }

  function updateEpicMintCount(address minter, uint256 count) private {
    epicMintCountMap[minter] += count;
  }

  /** COUNTERS */

  Counters.Counter private legendarySupplyCounter;
  Counters.Counter private legendaryReservedSupplyCounter;
  Counters.Counter private epicSupplyCounter;
  Counters.Counter private epicReservedSupplyCounter;

  function totalLegendarySupply() public view returns (uint256) {
    return legendarySupplyCounter.current();
  }

  function totalLegendaryReservedSupply() public view returns (uint256) {
    return legendaryReservedSupplyCounter.current();
  }

  function totalEpicSupply() public view returns (uint256) {
    return epicSupplyCounter.current();
  }

  function totalEpicReservedSupply() public view returns (uint256) {
    return epicReservedSupplyCounter.current();
  }

  function totalSupply() public view returns (uint256) {
    return MAX_SUPPLY;
  }

  /** MINTING **/

  function mintLegendary(uint256 count) public payable nonReentrant {
    require(saleIsActive, "Sale not active");
    require(totalLegendarySupply() + count <= MAX_LEGENDARY_SUPPLY - MAX_LEGENDARY_RESERVED_SUPPLY, "Max supply exceeded");
    require(count <= MAX_MULTIMINT, "Max multi mint exceeded");
    require(msg.value >= LEGENDARY_PRICE * count, "Insufficient funds");

    if (allowedLegendaryMintCount(_msgSender()) > 0) {
      updateLegendaryMintCount(_msgSender(), count);
    } else {
      revert("Minting limit exceeded");
    }

    for (uint256 i = 0; i < count; i++) {
      legendarySupplyCounter.increment();
      _safeMint(_msgSender(), MAX_LEGENDARY_RESERVED_SUPPLY + totalLegendarySupply());
    }
  }

  function mintEpic(uint256 count) public payable nonReentrant {
    require(saleIsActive, "Sale not active");
    require(totalEpicSupply() + count <= MAX_EPIC_SUPPLY - MAX_EPIC_RESERVED_SUPPLY, "Max supply exceeded");
    require(count <= MAX_MULTIMINT, "Max multi mint exceeded");
    require(msg.value >= EPIC_PRICE * count, "Insufficient funds");

    if (allowedEpicMintCount(_msgSender()) > 0) {
      updateEpicMintCount(_msgSender(), count);
    } else {
      revert("Minting limit exceeded");
    }

    for (uint256 i = 0; i < count; i++) {
      epicSupplyCounter.increment();
      _safeMint(_msgSender(), MAX_LEGENDARY_SUPPLY + MAX_EPIC_RESERVED_SUPPLY + totalEpicSupply());
    }
  }

  function mintLegendaryReserved(uint256 count) external onlyOwner {
    require(totalLegendaryReservedSupply() + count <= MAX_LEGENDARY_RESERVED_SUPPLY, "Max supply exceeded");

    for (uint256 i = 0; i < count; i++) {
      legendaryReservedSupplyCounter.increment();
      _safeMint(_msgSender(), totalLegendaryReservedSupply());
    }
  }

  function mintLegendaryReservedToAddress(uint256 count, address account) external onlyOwner {
    require(totalLegendaryReservedSupply() + count <= MAX_LEGENDARY_RESERVED_SUPPLY, "Max supply exceeded");

    for (uint256 i = 0; i < count; i++) {
      legendaryReservedSupplyCounter.increment();
      _safeMint(account, totalLegendaryReservedSupply());
    }
  }

  function mintEpicReserved(uint256 count) external onlyOwner{
    require(totalEpicReservedSupply() + count <= MAX_EPIC_RESERVED_SUPPLY, "Max supply exceeded");

    for (uint256 i = 0; i < count; i++) {
      epicReservedSupplyCounter.increment();
      _safeMint(_msgSender(), MAX_LEGENDARY_SUPPLY + totalEpicReservedSupply());
    }
  }

  function mintEpicReservedToAddress(uint256 count, address account) external onlyOwner{
    require(totalEpicReservedSupply() + count <= MAX_EPIC_RESERVED_SUPPLY, "Max supply exceeded");

    for (uint256 i = 0; i < count; i++) {
      epicReservedSupplyCounter.increment();
      _safeMint(account, MAX_LEGENDARY_SUPPLY + totalEpicReservedSupply());
    }
  }

  /** URI HANDLING **/

  string private customBaseURI;
  string public uriSuffix = ".json";

  function baseTokenURI() public view returns (string memory) {
    return customBaseURI;
  }

  function setBaseURI(string memory _customBaseURI) external onlyOwner {
    customBaseURI = _customBaseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), uriSuffix))
        : "";
  }

  /** PAYOUT **/

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(payee).call{value: address(this).balance}("");
    require(os, "Could not withdraw");
  }
}