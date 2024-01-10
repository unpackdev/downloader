// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownableish.sol";
import "./Stringish.sol";
import "./ERC721.sol";
import "./SafeTransferLib.sol";
import "./ReentrancyGuard.sol";

error MaxDecreasedOrUnchanged(uint256 currentMax);
error SalesCurrentlyPaused();
error TokenAlreadyMinted(uint256 tokenId);
error TokenDoesNotExist(uint256 tokenId);
error WrongEtherAmount(uint256 required);

contract BlancosNFT is Ownableish, ReentrancyGuard, ERC721 {
  using Stringish for uint256;

  uint256 public PRICE_PER_MINT = 0.10 ether;
  string public baseURI = "https://blancos.xyz/api/boundless/";
  bool public isPaused = false;

  uint256 public totalSupply;
  uint256 public MAX_SUPPLY = 10;
  event MaxSupplyIncreased(uint256 maxSupply);

  constructor() payable ERC721("Boundless Blancos", "BLANCOS") {}

  modifier whenNotPaused() {
    if (isPaused) revert SalesCurrentlyPaused();
    _;
  }

  function mint(uint256 id) external payable whenNotPaused nonReentrant {
    if (id == 0 || id > MAX_SUPPLY) revert TokenDoesNotExist(id);
    if (ownerOf[id] != address(0)) revert TokenAlreadyMinted(id);
    if (msg.value < PRICE_PER_MINT) revert WrongEtherAmount(PRICE_PER_MINT);
    ++totalSupply;
    _mint(msg.sender, id);
  }

  function togglePause() external onlyOwner {
    isPaused = !isPaused;
  }

  function _setMintPrice(uint256 _price) external onlyOwner {
    PRICE_PER_MINT = _price;
  }

  function _setBaseURI(string memory _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  function _setMaxSupply(uint256 _max) external onlyOwner {
    if (_max <= MAX_SUPPLY) revert MaxDecreasedOrUnchanged(MAX_SUPPLY);
    MAX_SUPPLY = _max;
    emit MaxSupplyIncreased(_max);
  }

  function withdraw() external onlyOwner {
    SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
    if (ownerOf[id] == address(0)) revert TokenDoesNotExist(id);
    return string(abi.encodePacked(baseURI, id.toString()));
  }

  function supportsInterface(bytes4 interfaceId)
    public
    pure
    override(Ownableish, ERC721)
    returns (bool)
  {
    return
      interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
      interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
      interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
      interfaceId == 0x01ffc9a7; // ERC165 Interface ID for ERC721Metadata
  }
}
