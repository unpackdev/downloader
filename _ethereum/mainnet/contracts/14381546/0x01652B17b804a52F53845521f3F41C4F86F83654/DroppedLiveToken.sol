// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Address.sol";

contract DroppedLiveToken is ERC721, IERC2981, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  constructor(string memory customBaseURI_) ERC721("Dropped Live Token", "NPTN")
  {
    customBaseURI = customBaseURI_;
  }

  /** MINTING LIMITS **/

  mapping(address => uint256) private mintCountMap;

  mapping(address => uint256) private allowedMintCountMap;

  uint256 public constant MINT_LIMIT_PER_WALLET = 20;

  function allowedMintCount(address minter) public view returns (uint256) {
    return MINT_LIMIT_PER_WALLET - mintCountMap[minter];
  }

  function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
  }

  /** MINTING **/

  uint256 public constant MAX_SUPPLY = 10000;

  uint256 public constant MAX_MULTIMINT = 20;

  uint256 public PRICE = 100000000000000000;

  Counters.Counter private supplyCounter;

  function mint(uint256 count) public payable nonReentrant {
    require(saleIsActive, "Sale not active");

    if (allowedMintCount(msg.sender) >= count) {
      updateMintCount(msg.sender, count);
    } else {
      revert("Minting limit exceeded");
    }

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 20 at a time");

    require(
      msg.value >= PRICE * count, string(abi.encodePacked("Insufficient payment, ", Strings.toString(PRICE/1000000000), " gwei per item"))
    );

    for (uint256 i = 0; i < count; i++) {
      _mint(msg.sender, totalSupply());

      supplyCounter.increment();
    }
  }

  function totalSupply() public view returns (uint256) {
    return supplyCounter.current();
  }

  function setPrice(uint256 newPrice) external onlyOwner {
    PRICE = newPrice*1000000000;
  }

  /** ACTIVATION **/

  bool public saleIsActive = false;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  /** URI HANDLING **/

  string private customBaseURI;

  mapping(uint256 => string) private tokenURIMap;

  function setTokenURI(uint256 tokenId, string memory tokenURI_) external onlyOwner
  {
    tokenURIMap[tokenId] = tokenURI_;
  }

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  function tokenURI(uint256 tokenId) public view override
    returns (string memory)
  {
    string memory tokenURI_ = tokenURIMap[tokenId];

    if (bytes(tokenURI_).length > 0) {
      return tokenURI_;
    }

    return string(abi.encodePacked(super.tokenURI(tokenId)));
  }

  /** PAYOUT **/

  function withdraw() public nonReentrant {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(owner()), balance);
  }

  /** ROYALTIES **/

  function royaltyInfo(uint256, uint256 salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
  {
    return (address(this), (salePrice * 750) / 10000);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, IERC165)
    returns (bool)
  {
    return (
      interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(interfaceId)
    );
  }

  /** Contract URI **/

  string private contrURI = "https://nptn.live/contract-metadata";

  function setContractURI(string memory contrURI_) external onlyOwner {
    contrURI = contrURI_;
  }

  function contractURI() public view returns (string memory) {
      return contrURI;
  }
}
