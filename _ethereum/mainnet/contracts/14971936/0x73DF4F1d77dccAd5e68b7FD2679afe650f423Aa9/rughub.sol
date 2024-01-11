//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721AUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract RugHub is
  ERC721AUpgradeable,
  OwnableUpgradeable,
  UUPSUpgradeable,
  ReentrancyGuardUpgradeable
{
  uint256 public constant PRICE = 69000000000000000;
  uint256 public constant TOTAL_SUPPLY = 10000;
  uint256 public constant RESERVE_AMOUNT = 200;
  uint256 public constant MAX_MINT_AMOUNT = 69;
  address internal _rugHubWallet;
  uint256 internal _mintStartsAt;
  string internal _uri;

  function initialize(
    uint256 mintStartsAt,
    address rugHubWallet,
    string calldata uri
  )
  initializerERC721A
  initializer
  public
  {
    __ERC721A_init('RugHub', 'RUG');
    __Ownable_init();

    _mintStartsAt = mintStartsAt;
    _rugHubWallet = rugHubWallet;
    _uri = uri;

  }

  function setMintStartsAt(uint256 timestamp)
  external
  onlyOwner
  {
    _mintStartsAt = timestamp;
  }

  function getMintStartsAt()
  external
  view
  returns (uint256)
  {
    return _mintStartsAt;
  }

  function setRugHubWallet(address wallet)
  external
  onlyOwner
  {
    _rugHubWallet = wallet;
  }

  function getRugHubWallet()
  external
  view
  returns (address)
  {
    return _rugHubWallet;
  }

  function pullRug(uint256 quantity)
  external
  payable
  nonReentrant
  {
    require(block.timestamp >= _mintStartsAt, "Minting has not started yet you naughty boy");
    require(totalSupply() + quantity <= TOTAL_SUPPLY, "Can't mint over the maximum supply");
    require(quantity <= MAX_MINT_AMOUNT, "Can't mint more than 69 at a time ;)");
    require(_rugHubWallet != address(0), "Rughub wallet not set yet");

    uint256 totalPrice = (quantity * PRICE);
    require(msg.value >= totalPrice, "Insufficient eth sent");

    _mint(_msgSender(), quantity);
    payable(_rugHubWallet).transfer(totalPrice);

    // refund remaining eth
    if (msg.value > totalPrice) {
      uint256 change = msg.value - totalPrice;

      payable(_msgSender()).transfer(change);
    }
  }

  function withdraw()
  external
  onlyOwner
  {
    uint256 balance = address(this).balance;
    payable(_rugHubWallet).transfer(balance);
  }

  function setBaseURI(string memory uri)
  external
  onlyOwner
  {
    _uri = uri;
  }

  function _baseURI()
  internal
  override
  view
  virtual
  returns (string memory) {
    return _uri;
  }

  function pullReserveRug()
  public
  virtual
  onlyOwner
  nonReentrant
  {
    require(totalSupply() + RESERVE_AMOUNT <= TOTAL_SUPPLY, "Can't mint over the maximum supply");

    _mint(_msgSender(), RESERVE_AMOUNT);
  }

  function _authorizeUpgrade(address newImplementation)
  internal
  virtual
  override
  onlyOwner
  {}
}
