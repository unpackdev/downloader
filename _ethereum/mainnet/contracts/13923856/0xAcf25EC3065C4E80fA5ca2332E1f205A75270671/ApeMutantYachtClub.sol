// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Address.sol";

contract ApeMutantYachtClub is ERC721, IERC2981, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  constructor (string memory customBaseURI_)
    ERC721("Ape Mutant Yacht Club", "AMYC")
  {
    customBaseURI = customBaseURI_;

    allowedMintCountMap[owner()] = 2500;
  }

  /** MINTING LIMITS **/

  mapping(address => uint256) private mintCountMap;

  mapping(address => uint256) private allowedMintCountMap;

  uint256 public constant MINT_LIMIT_PER_WALLET = 20;

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    return a >= b ? a : b;
  }

  function allowedMintCount(address minter) public view returns (uint256) {
    if (saleIsActive) {
      return (
        max(allowedMintCountMap[minter], MINT_LIMIT_PER_WALLET) -
        mintCountMap[minter]
      );
    }

    return allowedMintCountMap[minter] - mintCountMap[minter];
  }

  function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
  }

  /** MINTING **/

  uint256 public constant MAX_SUPPLY = 20000;

  uint256 public constant MAX_MULTIMINT = 10;

  uint256 public constant PRICE = 16899999999999998;

  Counters.Counter private supplyCounter;

  function mint(uint256 count) public payable nonReentrant {
    if (allowedMintCount(_msgSender()) >= count) {
      updateMintCount(_msgSender(), count);
    } else {
      revert(saleIsActive ? "Minting limit exceeded" : "Sale not active");
    }

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 10 at a time");

    require(
      msg.value >= PRICE * count, "Insufficient payment, 0.0169 ETH per item"
    );

    for (uint256 i = 0; i < count; i++) {
      _safeMint(_msgSender(), totalSupply());

      supplyCounter.increment();
    }
  }

  function totalSupply() public view returns (uint256) {
    return supplyCounter.current();
  }

  /** ACTIVATION **/

  bool public saleIsActive = false;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  /** URI HANDLING **/

  string private customBaseURI;

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  /** PAYOUT **/

  address private constant payoutAddress1 =
    0x4F521F9abf20e6BeDF235a98eF0D42e8D104A894;

  address private constant payoutAddress2 =
    0x1A66508bc8477D943933D01C14a34EEeaeBC62AE;

  function withdraw() public nonReentrant {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(owner()), balance * 50 / 100);

    Address.sendValue(payable(payoutAddress1), balance * 25 / 100);

    Address.sendValue(payable(payoutAddress2), balance * 25 / 100);
  }

  /** ROYALTIES **/

  function royaltyInfo(uint256, uint256 salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
  {
    return (address(this), (salePrice * 500) / 10000);
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
}

// Contract created with Studio 721 v1.4.0
// https://721.so