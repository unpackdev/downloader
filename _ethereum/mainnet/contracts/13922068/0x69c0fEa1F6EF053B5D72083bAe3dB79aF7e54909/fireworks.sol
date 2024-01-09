// SPDX-License-Identifier: UNLICENSED

// ███╗   ███╗ █████╗ ██████╗ ███████╗    ██╗    ██╗██╗████████╗██╗  ██╗    ███╗   ███╗ █████╗ ███████╗ ██████╗ ███╗   ██╗
// ████╗ ████║██╔══██╗██╔══██╗██╔════╝    ██║    ██║██║╚══██╔══╝██║  ██║    ████╗ ████║██╔══██╗██╔════╝██╔═══██╗████╗  ██║
// ██╔████╔██║███████║██║  ██║█████╗      ██║ █╗ ██║██║   ██║   ███████║    ██╔████╔██║███████║███████╗██║   ██║██╔██╗ ██║
// ██║╚██╔╝██║██╔══██║██║  ██║██╔══╝      ██║███╗██║██║   ██║   ██╔══██║    ██║╚██╔╝██║██╔══██║╚════██║██║   ██║██║╚██╗██║
// ██║ ╚═╝ ██║██║  ██║██████╔╝███████╗    ╚███╔███╔╝██║   ██║   ██║  ██║    ██║ ╚═╝ ██║██║  ██║███████║╚██████╔╝██║ ╚████║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝     ╚══╝╚══╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝

pragma solidity ^0.8.9;

import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Address.sol";
import "./PaymentSplitter.sol";

contract Fireworks is ERC721, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

    /** MINTING **/
  uint256 public PRICE;
  uint256 public MAX_SUPPLY;

  Counters.Counter private supplyCounter;

  PaymentSplitter private _splitter;

  constructor (
    string memory tokenName,
    string memory tokenSymbol,
    string memory customBaseURI_,
    address[] memory payees,
    uint256[] memory shares,
    uint256 _tokenPrice,
    uint256 _tokensForSale) ERC721(tokenName, tokenSymbol) {
    customBaseURI = customBaseURI_;

    PRICE = _tokenPrice;
    MAX_SUPPLY = _tokensForSale;

    _splitter = new PaymentSplitter(payees, shares);
  }

  function mint(uint256 count) public payable nonReentrant {
    require(saleIsActive, "Sale not active");

    // For every 10 tokens, we will include a free one
    uint freeMints = count / 10;

    require(totalSupply() + count + freeMints - 1 < MAX_SUPPLY , "Exceeds max supply");
    require(
      msg.value >= PRICE * count, "Insufficient payment"
    );

    for (uint256 i = 0; i < count + freeMints; i++) {
      supplyCounter.increment();
      _safeMint(_msgSender(), totalSupply());
    }

    payable(_splitter).transfer(msg.value);
  }

  function ownerMint(uint256 count, address account) external onlyOwner() {
    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    for (uint256 i = 0; i < count; i++) {
      supplyCounter.increment();
      _safeMint(account, totalSupply());
    }
  }

  function totalSupply() public view returns (uint256) {
    return supplyCounter.current();
  }

  /** ACTIVATION **/

  bool public saleIsActive = true;

  function flipSaleState() external onlyOwner {
    saleIsActive = !saleIsActive;
  }

  /** ADMIN **/

  function setPrice(uint256 _tokenPrice) external onlyOwner {
    PRICE = _tokenPrice;
  }

  /** OWNERSHIP  **/

  // WARNING: This function is not expensive, it should not be called from within the contract!!!
  function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);

    if (tokenCount == 0) {
      return new uint256[](1);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalTokens = totalSupply();
      uint256 resultIndex = 0;

      uint256 tokenId;
      for (tokenId = 1; tokenId <= totalTokens; tokenId++) {
          if (ownerOf(tokenId) == _owner) {
            result[resultIndex] = tokenId;
              resultIndex++;
          }
      }

      return result;
    }
  }

  /** URI HANDLING **/

  string private customBaseURI;

  function baseTokenURI() public view returns (string memory) {
    return customBaseURI;
  }

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  /** PAYOUT **/

  function release(address payable account) public virtual onlyOwner {
    _splitter.release(account);
  }
}
