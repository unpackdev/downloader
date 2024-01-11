// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

error PauseError();
error QuantityError();
error SupplyError();
error ValueError();
error BalanceError();
error NonExistantToken();

contract NFT is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  struct Config {
    uint256 price;
    uint256 maxSupply;
    uint256 maxPerTx;
    uint256 maxPerWallet;
    uint256 freePerWallet;
    uint256 teamReserve;
    string baseURI;
    string unrevealedURI;
    bool paused;
    bool revealed;
  }

  Config public config;

  modifier checkPause() {
    if (config.paused) {
      revert PauseError();
    }
    _;
  }

  modifier checkQuantity(uint256 quantity) {
    if (quantity == 0) {
      revert QuantityError();
    }

    if (quantity > config.maxPerTx) {
      revert QuantityError();
    }
    _;
  }

  modifier checkSupply(uint256 quantity) {
    if ((totalSupply() + quantity) > config.maxSupply) {
      revert SupplyError();
    }
    _;
  }

  modifier checkBalance(uint256 quantity) {
    if ((balanceOf(msg.sender) + quantity) > config.maxPerWallet) {
      revert BalanceError();
    }
    _;
  }

  modifier checkValue(uint256 quantity) {
    uint256 price = config.price * quantity;

    if (
      (config.freePerWallet > 0) &&
      (balanceOf(msg.sender) < config.freePerWallet)
    ) {
      price = price - (config.price * config.freePerWallet);
    }

    if (msg.value < price) {
      revert ValueError();
    }
    _;
  }

  modifier tokenExists(uint256 tokenId) {
    if (!_exists(tokenId)) {
      revert NonExistantToken();
    }
    _;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    Config memory _config
  ) ERC721A(_name, _symbol) {
    config = _config;

    mintTeamReserve();
  }

  function mint(uint256 quantity)
    external
    payable
    checkPause
    checkSupply(quantity)
    checkQuantity(quantity)
    checkBalance(quantity)
    checkValue(quantity)
    nonReentrant
  {
    _safeMint(msg.sender, quantity);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    tokenExists(tokenId)
    returns (string memory)
  {
    if (!config.revealed) {
      return config.unrevealedURI;
    }

    return
      string(abi.encodePacked(config.baseURI, tokenId.toString(), '.json'));
  }

  function mintTeamReserve() internal onlyOwner {
    if (config.teamReserve > 0) {
      _safeMint(owner(), config.teamReserve);
    }
  }

  function setConfig(Config memory _config) public onlyOwner nonReentrant {
    config = _config;
  }

  function reveal(string memory _baseURI) public onlyOwner nonReentrant {
    config.baseURI = _baseURI;
    config.revealed = true;
  }

  function flipPause() public onlyOwner nonReentrant {
    config.paused = !config.paused;
  }

  function withdraw() public payable onlyOwner nonReentrant {
    (bool success, ) = payable(owner()).call{value: address(this).balance}('');
    require(success);
  }
}
