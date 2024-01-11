// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Upgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

interface IArt {
  function SVG(uint256, uint256) external view returns (string memory);

  function getTitle(uint256) external view returns (string memory);

  function tokenURI(
    uint256,
    uint256,
    uint256
  ) external view returns (string memory);
}

contract Progressive is
  ERC721Upgradeable,
  ERC2981Upgradeable,
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable
{
  uint256 private _tokenSupply;

  mapping(uint256 => uint256) private _mintTime;
  mapping(uint256 => uint256) private _prevMintTime;
  uint256 private _lastMintTime;

  IArt public art;
  bool public artLocked;

  uint256 public price;
  uint256 public startTime;
  bool public mintIsActive;

  uint256 private PRICE_STEP;
  uint256 private PRICE_STEP_DURATION;

  function initialize(address artAddress_) external initializer {
    __ERC721_init("Progressive", "PROGRESSIVE");
    __ReentrancyGuard_init();
    __Ownable_init();

    art = IArt(artAddress_);
    price = 0.1 ether;
    PRICE_STEP = 20;
    PRICE_STEP_DURATION = 1 days / 20;
  }

  function currentPrice() public view returns (uint256) {
    uint256 d = currentDuration();
    if (d <= 1 days) {
      return price;
    }
    if (d >= 2 days) {
      return 0;
    }
    return price - ((d - 1 days) / PRICE_STEP_DURATION) * (price / PRICE_STEP);
  }

  function open() private view returns (bool) {
    return startTime != 0 && startTime <= block.timestamp && mintIsActive;
  }

  modifier costs() {
    require(msg.value >= currentPrice(), "Not enough ETH sent; check price!");
    _;
  }

  function mint(uint256 _tokenId) external payable nonReentrant costs {
    require(open(), "INACTIVE");
    require(_tokenId == _tokenSupply + 1, "INVALID");

    _tokenSupply++;
    _mintTime[_tokenSupply] = block.timestamp;
    _prevMintTime[_tokenSupply] = _lastMintTime != 0
      ? _lastMintTime
      : startTime;
    _lastMintTime = block.timestamp;
    _safeMint(_msgSender(), _tokenSupply);
  }

  struct stateContext {
    uint256 tokenId;
    string title;
    string svg;
    uint256 progress;
    uint256 time;
    uint256 price;
  }

  function currentState() external view returns (stateContext memory state) {
    require(open(), "INACTIVE");
    uint256 seed = _lastMintTime != 0 ? _lastMintTime : startTime;
    state.tokenId = _tokenSupply + 1;
    state.time = currentDuration();
    state.title = art.getTitle(seed);
    state.svg = art.SVG(state.time, seed);
    state.progress = toRate(state.time);
    state.price = currentPrice();
  }

  function currentDuration() private view returns (uint256) {
    uint256 from = _lastMintTime != 0 ? _lastMintTime : startTime;
    if (block.timestamp < from) {
      return 0;
    }
    return block.timestamp - from;
  }

  function toRate(uint256 _time) private pure returns (uint256) {
    return _time >= 1 days ? 100 : (_time * 100) / 1 days;
  }

  function tokenDuration(uint256 _tokenId) private view returns (uint256) {
    return _mintTime[_tokenId] - _prevMintTime[_tokenId];
  }

  function tokenSVG(uint256 _tokenId) external view returns (string memory) {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    return art.SVG(tokenDuration(_tokenId), _prevMintTime[_tokenId]);
  }

  /* token utility */

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function setStartTime(uint256 _time) external onlyOwner {
    startTime = _time;
  }

  function setMintIsActive(bool _mintIsActive) external onlyOwner {
    mintIsActive = _mintIsActive;
  }

  function setArtLocked() external onlyOwner {
    artLocked = true;
  }

  function setArtAddress(address _address) external onlyOwner {
    require(!artLocked);
    art = IArt(_address);
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    return
      art.tokenURI(_tokenId, tokenDuration(_tokenId), _prevMintTime[_tokenId]);
  }

  function totalSupply() external view returns (uint256) {
    return _tokenSupply;
  }

  function withdrawBalance() external onlyOwner {
    (bool success, ) = msg.sender.call{ value: address(this).balance }("");
    require(success);
  }

  function setRoyaltyInfo(address receiver_, uint96 royaltyBps_)
    external
    onlyOwner
  {
    _setDefaultRoyalty(receiver_, royaltyBps_);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC2981Upgradeable, ERC721Upgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
