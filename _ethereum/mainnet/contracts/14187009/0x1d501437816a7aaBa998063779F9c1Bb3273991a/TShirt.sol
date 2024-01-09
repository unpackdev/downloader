// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";

import "./TShirtRenderer.sol";
import "./Base64.sol";

contract TShirt is ERC721, ERC721Enumerable, Pausable, Ownable, ITShirtRenderer {
  using Address for address payable;
  using Counters for Counters.Counter;

  address public rendererAddress;

  Counters.Counter private _tokenIdCounter;
  uint256 public constant MAX_SUPPLY = 999;

  // tokenId => minted Options
  mapping(uint256 => Options) private tokens;

  event Purchased(address owner, uint256 tokenId, Options options);

  constructor() ERC721('T-Shirt Exchange', 'TSHIRT') {}

  function setRendererAddress(address to) public onlyOwner {
    rendererAddress = to;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function getCost(uint256 design) public view override returns (uint256) {
    return ITShirtRenderer(rendererAddress).getCost(design);
  }

  function render(uint256 tokenId, Options memory options) public view override returns (string memory) {
    return ITShirtRenderer(rendererAddress).render(tokenId, options);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'id');
    return render(tokenId, tokens[tokenId]);
  }

  function withdraw(uint256 amount, address to) external onlyOwner {
    require(amount > 0 && amount <= address(this).balance, 'oob');
    payable(to).sendValue(amount);
  }

  function purchase(Options memory options) external payable {
    // supply check
    require(_tokenIdCounter.current() <= MAX_SUPPLY, 'max');

    // validate design
    require(options.background > 0 && options.outline > 0 && options.fill > 0, 'color');
    require(options.background != options.outline, 'mono');

    // price check
    require(msg.value >= getCost(options.design), 'cost');

    // save options and increment tokenId
    _tokenIdCounter.increment();
    tokens[_tokenIdCounter.current()] = options;

    // mint token to sender
    _safeMint(_msgSender(), _tokenIdCounter.current());

    // emit event
    emit Purchased(_msgSender(), _tokenIdCounter.current(), options);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
