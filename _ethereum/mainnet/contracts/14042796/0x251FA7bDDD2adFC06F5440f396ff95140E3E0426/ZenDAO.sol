//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IERC721Metadata.sol";
import "./Counters.sol";

error WhitelistNotActive();
error SaleNotActive();
error ExceedsWhitelistAllowance();
error NumberExceedsMaxAllowed();
error ExceedsMaxSupply();
error InsufficientFundsSent();
error ArrayLengthMismatch();
error TokenAlreadyMinted();

// solhint-disable-next-line no-empty-blocks
contract OSOwnableDelegateProxy {

}

contract OSProxyRegistry {
  mapping(address => OSOwnableDelegateProxy) public proxies;
}

contract ZenDAO is Ownable, ERC721, IERC721Metadata {
  using Counters for Counters.Counter;

  uint256 public constant MAX_SUPPLY = 1100;
  uint256 public constant MAX_PUBLIC_MINT = 2;
  uint256 public cost = 0 ether;

  string private _name = "ZenDAO";
  string private _symbol = "ZDAO";
  Counters.Counter private _tokenIdTracker;
  string private _baseURI;
  string private _uriExtension = ".json";

  OSProxyRegistry private immutable _osProxyRegistry;

  constructor(OSProxyRegistry osProxyRegistry) {
    _osProxyRegistry = osProxyRegistry;
    _tokenIdTracker.increment();
  }

  function mint(uint256 numberOfTokens) external payable {
    if (Address.isContract(_msgSender())) revert InvalidRecipient();
    if (numberOfTokens > MAX_PUBLIC_MINT) revert NumberExceedsMaxAllowed();
    if (cost * numberOfTokens > msg.value)
      revert InsufficientFundsSent();
    if (_tokenIdTracker.current() + numberOfTokens > MAX_SUPPLY + 1)
      revert ExceedsMaxSupply();

    _mintN(_msgSender(), numberOfTokens);
  }

  function reserve(uint256 numberOfTokens) external onlyOwner {
    if (_tokenIdTracker.current() + numberOfTokens > MAX_SUPPLY + 1)
      revert ExceedsMaxSupply();

    _mintN(_msgSender(), numberOfTokens);
  }

  function setCost(uint256 cost_) external onlyOwner {
    cost = cost_;
  }

  function withdraw() external onlyOwner {
    Address.sendValue(payable(_msgSender()), address(this).balance);
  }

  function name() external view returns (string memory) {
    return _name;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function totalSupply() external view returns (uint256) {
    return _tokenIdTracker.current() - 1;
  }

  function setBaseURI(string memory newBaseURI) public onlyOwner {
    _baseURI = newBaseURI;
  }

  function setURIExtension(string memory uriExtension) public onlyOwner {
    _uriExtension = uriExtension;
  }

  function isApprovedForAll(address owner_, address operator)
    public
    view
    override(IERC721, ERC721)
    returns (bool)
  {
    return
      (address(_osProxyRegistry) != address(0) &&
        address(_osProxyRegistry.proxies(owner_)) == operator) ||
      super.isApprovedForAll(owner_, operator);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    if (_exists(tokenId) != true) revert TokenDoesNotExist();

    return bytes(_baseURI).length > 0
        ? string(abi.encodePacked(_baseURI, Strings.toString(tokenId), _uriExtension))
        : "";
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(IERC165, ERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function _mintN(address to, uint256 numberOfTokens) internal {
    for (uint256 i = 0; i < numberOfTokens; i++) {
      _mint(to, _tokenIdTracker.current());
      _tokenIdTracker.increment();
    }
  }

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}

  fallback() external payable {}
}
