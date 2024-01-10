// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract FounderBatClub is Ownable, Pausable, ERC721A, ReentrancyGuard {

  address payable public fundsTo;

  uint256 public whitelistMaxSupply = 666;
  uint256 immutable whitelistPrice = 0.18 ether;
  uint256 constant whitelistMaxMint = 3;
  uint256 public whitelistSupply;
  mapping(address => bool) public whitelist;
  mapping(address => uint256) public whitelistMintedAmount;

  // Maximum supply of the NFT
  uint256 public maxSupply = 3333;
  uint256 public tokenPrice = 0.2 ether;

  uint256 public whitelistStartTime;
	uint256 public publicSaleStartTime;

  constructor(
    address payable _fundsTo,
    uint256 _whitelistStartTime,
    uint256 _publicSaleStartTime,
    uint256 _maxSupply
  ) ERC721A("Founder Bat Club", "FBC") {
    fundsTo = _fundsTo;
    require(block.timestamp < _whitelistStartTime && _whitelistStartTime < _publicSaleStartTime, "invalid start time");
    whitelistStartTime = _whitelistStartTime;
    publicSaleStartTime = _publicSaleStartTime;
    maxSupply = _maxSupply;
  }

  function getTokenPrice() public view returns (uint256) {
    if (isWhitelistSale()) {
      return whitelistPrice;
    }
    return tokenPrice;
  }

  function getMintableAmount(address wallet) public view returns (uint256) {
    if (isWhitelistSale() && whitelist[wallet]) {
      uint256 amount = whitelistMaxMint - whitelistMintedAmount[wallet];
      if (whitelistMaxSupply - whitelistSupply < amount) {
        return whitelistMaxSupply - whitelistSupply;
      }
      return amount;
    } else if (block.timestamp >= publicSaleStartTime) {
      return maxSupply - totalSupply();
    }
    return 0;
  }

  function mint(uint256 quantity) external payable nonReentrant whenNotPaused {
    require(block.timestamp >= whitelistStartTime, "not start yet");
    require(msg.value == getTokenPrice() * quantity, "wrong amount");
    require(totalSupply() + quantity <= maxSupply, "out of stock");

    if (isWhitelistSale()) {
      require(whitelist[msg.sender], "not in whitelist");
      require(whitelistSupply + quantity <= whitelistMaxSupply, "out of stock");
      require(whitelistMintedAmount[msg.sender] + quantity <= whitelistMaxMint, "max per wallet reached");
      whitelistSupply += quantity;
      whitelistMintedAmount[msg.sender] += quantity;
    }

    _safeMint(msg.sender, quantity);
  }

  function isWhitelistSale() internal view returns (bool) {
    return block.timestamp >= whitelistStartTime && block.timestamp < publicSaleStartTime;
  }

  // ADMIN Functions
  function preserveMint(address[] calldata toAddresses, uint256[] calldata quantity) external onlyOwner {
    require(block.timestamp < whitelistStartTime, "can only mint before sale");
    require(toAddresses.length == quantity.length, "length mismatch");
    for (uint256 i = 0; i < toAddresses.length; i++) {
      // count as first tier, whitelist supply
      whitelistSupply += quantity[i];
      _safeMint(toAddresses[i], quantity[i]);
    }
  }

  function setPaused(bool _setPaused) external onlyOwner {
		return (_setPaused) ? _pause() : _unpause();
	}

  function setWhitelist(address[] calldata addresses, bool status) external onlyOwner {
    for (uint256 i =0; i < addresses.length; i++) {
      whitelist[addresses[i]] = status;
    }
  }

  function setWhitelistMaxSupply(uint256 _maxSupply) external onlyOwner {
    require(_maxSupply >= whitelistSupply, "must greater than current supply");
    whitelistMaxSupply = _maxSupply;
  }

  function setMaxSupply(uint256 _maxSupply) external onlyOwner {
    require(_maxSupply >= totalSupply(), "must greater than current supply");
    maxSupply = _maxSupply;
  }

  function setPublicSaleTime(uint256 _startTime) external onlyOwner {
    require(_startTime > block.timestamp, "can't set to past");
    require(_startTime > whitelistStartTime, "can't set before whitelist start time");
    publicSaleStartTime = _startTime;
  }

  function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
    tokenPrice = _tokenPrice;
  }

  function updateFundsTo(address payable newFundsTo) external onlyOwner {
    fundsTo = newFundsTo;
  }

  function claimBalance() external onlyOwner {
    (bool success, ) = fundsTo.call{value: address(this).balance}("");
    require(success, "transfer failed");
  }

  function reclaimERC20(IERC20 erc20Token) external onlyOwner {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

	function reclaimERC721(IERC721 erc721Token, uint256 id) external onlyOwner {
    erc721Token.safeTransferFrom(address(this), msg.sender, id);
	}

  // metadata URI
  string private _baseTokenURI;
  string private _defaultURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return bytes(_baseTokenURI).length == 0 ? _defaultURI : _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setDefaultURI(string calldata baseURI) external onlyOwner {
    _defaultURI = baseURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (bytes(_baseTokenURI).length == 0) {
      return _defaultURI;
    }
    return super.tokenURI(tokenId);
  }
}
