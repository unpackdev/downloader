// SPDX-License-Identifier: MIT
/*

███████████
████████████████████████████
██████████████████████████████████
██████████████████████████████████
█████    ██████    █████     █████     ██████   ███████    ███      █████   ████████
███   ███  ██  ███  ███  █████████    ██    █   ██    ██   ███    ███   ██  ██
███  ███████  █████  ██  █████████    ██        ██    ██  ██ ██   ██        ██
███  ███████  █████  ███     █████     ██████   ███████  ██   █   ██        ███████
███  ███████  █████  ████████ ████          ██  ██       ███████  ██        ██
███  ████  ██  ███  ███ █████ ████    ██   ███  ██      ██     ██  ██   ██  ██
█████     ████     ████      █████     █████    ██      █      ██   █████   ███████
██████████████████████████████████
██████████████████████████████████   ███████████████████████████████████████████████
███████████████████████████
██████████

*/

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract CosSpace is ERC721Enumerable, Ownable {
  uint256 public constant MAX_SUPPLY = 20000;
  uint8 public constant LAND_WIDTH = 200;
  uint8 public constant LAND_HEIGHT = 100;
  string private tokenBaseURI;
  address controller;

  struct Rect {
    uint8 width;
    uint8 height;
  }

  mapping(uint256 => Rect) public tokenRect; // tokenId to Rect struct
  mapping(uint256 => uint256) public rectOrigin; // tokenId to tokenId of Rect origin

  constructor() ERC721("COS.SPACE", "SPACE") {}

  modifier onlyController() {
    require(msg.sender == controller, "Not controller");
    _;
  }

  // For owner
  function setController(address newAddress) external onlyOwner {
    controller = newAddress;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    tokenBaseURI = baseURI;
  }

  function renounceOwnership() public view override onlyOwner {
    revert("Not allowed");
  }

  // For controller
  function mintToken(address to, uint256 tokenId) external onlyController {
    _safeMint(to, tokenId);
  }

  function burnToken(uint256 tokenId) external onlyController {
    _burn(tokenId);
  }

  function exists(uint256 tokenId) external view onlyController returns (bool) {
    return _exists(tokenId);
  }

  function setRectOrigin(uint256 tokenId, uint256 originTokenId)
    external
    onlyController
  {
    rectOrigin[tokenId] = originTokenId;
  }

  function setWH(
    uint256 tokenId,
    uint8 width,
    uint8 height
  ) external onlyController {
    if (width > 1 || height > 1 || tokenRect[tokenId].width > 0) {
      tokenRect[tokenId] = Rect(width, height);
    }
  }

  function getWH(uint256 tokenId)
    public
    view
    returns (uint8 width, uint8 height)
  {
    Rect memory rect = tokenRect[tokenId];
    width = (rect.width == 0) ? 1 : rect.width;
    height = (rect.height == 0) ? 1 : rect.height;
  }

  // Internal functions
  function _baseURI() internal view virtual override returns (string memory) {
    return tokenBaseURI;
  }
}
