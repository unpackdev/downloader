// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";
import "./Counters.sol";
import "./Address.sol";

contract URUZ_by_Felt_Zine is ERC721, IERC2981, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  constructor(string memory customBaseURI_, address accessTokenAddress_)
    ERC721("URUZ by Felt Zine", "URUZ")
  {
    customBaseURI = customBaseURI_;

    accessTokenAddress = accessTokenAddress_;
  }

  /** MINTING **/

  address public accessTokenAddress;

  uint256 public constant MAX_SUPPLY = 250;

  uint256 public constant MAX_MULTIMINT = 10;

  uint256 public constant PRICE = 10000000000000000;

  Counters.Counter private supplyCounter;

  function mint(uint256 count) public payable nonReentrant {
    require(saleIsActive, "Sale not active");

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 10 at a time");

    require(
      msg.value >= PRICE * count, "Insufficient payment, 0.01 ETH per item"
    );

    ERC721 accessToken = ERC721(accessTokenAddress);

    for (uint256 i = 0; i < count; i++) {
      if (accessTokenIsActive) {
        require(
          accessToken.balanceOf(msg.sender) > 0,
          "Access token not owned"
        );
      }

      _mint(msg.sender, totalSupply());

      supplyCounter.increment();
    }
  }

  function totalSupply() public view returns (uint256) {
    return supplyCounter.current();
  }

  /** ACTIVATION **/

  bool public saleIsActive = true;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  bool public accessTokenIsActive = true;

  function setAccessTokenIsActive(bool accessTokenIsActive_) external onlyOwner
  {
    accessTokenIsActive = accessTokenIsActive_;
  }

  function setAccessTokenAddress(address accessTokenAddress_) external onlyOwner
  {
    accessTokenAddress = accessTokenAddress_;
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

  function withdraw() public nonReentrant {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(owner()), balance);
  }

  /** ROYALTIES **/

  function royaltyInfo(uint256, uint256 salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
  {
    return (address(this), (salePrice * 2000) / 10000);
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

// Contract created with Studio 721 v1.5.0
// https://721.so