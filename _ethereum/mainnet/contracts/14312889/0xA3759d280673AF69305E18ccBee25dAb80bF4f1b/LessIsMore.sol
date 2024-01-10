// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*
     _
   8   8                                                                                D D
 8       8                                                                             D    D
8         8                                                                            D      D
8         8 ========================================================================== D       D
 8       8           ____  ____   ____    _____  ____    _      _  ___   ____   ____   D        D
   8 _ 8     |      |     |      |          |   |        |\    /| /   \ |    | |       D         D
   8   8     |      |____ |____  |____      |   |____    | \  / ||     ||___/  |____   D         D
 8       8   |      |          |      |     |        |   |  \/  ||     ||   \  |       D         D
8         8  |_____ |____ _____| _____|   __|__ _____|   |      | \___/ |    \ |____   D        D
8         8 ========================================================================== D      D
 8       8                                                                             D    D
   8 _ 8                                                                                D D
*/

import "./ERC721.sol";
import "./IERC2981.sol";
import "./IERC20.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract LessIsMore is ERC721, ERC721Enumerable, ERC721URIStorage, IERC2981, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenCounter;

  uint256 private constant DICK_LIMIT = 888;
  uint256 private constant MINT_LIMIT = 8;
  uint256 public constant PUBLIC_SALE_PRICE = 0.069 ether;
  bool public isPublicSaleActive = true;
  bool public actualBaseURIHasBeenSet = false;
  bool private isOpenSeaProxyActive = true;
  address private _openSeaProxyRegistryAddress;
  // Placeholder Balls Base URI
  string private _baseURIextended = "https://gateway.pinata.cloud/ipfs/QmNbV68iV4aTq2qnQvHuULoTqE35s6Ews2EdrFnw1CL7oM/";

  constructor(address openSeaProxyRegistryAddress) ERC721("LessIsMore", "LIM") {}

  function setBaseURI(string memory baseURI_) external onlyOwner() {
    require(!actualBaseURIHasBeenSet, "BaseURI has already been set, king. Nice try tho champ... Maybe next time!");
      _baseURIextended = baseURI_;
      // Provenance Hash (Sha256) of Actual BaseRUI's CID: 
      // 7ab17347adf3b34eac9f08c98fb1e045e13a7bed4013e212624e3eaa2d06ff02
      actualBaseURIHasBeenSet = true;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return _baseURIextended;
  }
 
  /**
   * @notice Mint some, king.
   */
  function mint(uint256 numberOfTokens)
    external
    payable
    nonReentrant
    isCorrectPayment(PUBLIC_SALE_PRICE, numberOfTokens)
    publicSaleActive
    canMintLessIsMore(numberOfTokens)
  {
    for (uint256 i = 0; i < numberOfTokens; i++) {
      _safeMint(msg.sender, nextTokenId());
    }
  }

  // Required Solidity overrides, king.
  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
      internal
      override(ERC721, ERC721Enumerable)
  {
      super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
      super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
      public
      view
      override(ERC721, ERC721URIStorage)
      returns (string memory)
  {
      return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721, IERC165, ERC721Enumerable)
      returns (bool)
  {
      return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  // Disable gasless listings for security in case
  // opensea ever shuts down/is compromised, king.
  function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
    external
    onlyOwner
  {
    isOpenSeaProxyActive = _isOpenSeaProxyActive;
  }

  // Helpers, king.
  function setIsPublicSaleActive(bool _isPublicSaleActive) external onlyOwner {
    isPublicSaleActive = _isPublicSaleActive;
  }

  function nextTokenId() private returns (uint256) {
    _tokenCounter.increment();
    return _tokenCounter.current();
  }

  modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
    require(numberOfTokens > 0, "Gotta mint more than zero dicks, king.");
    require(price * numberOfTokens == msg.value, "Incorrect ETH value sent, king.");
    _;
  }

  modifier publicSaleActive() {
    require(isPublicSaleActive, "Public sale ain't open, king.");
    _;
  }
  modifier canMintLessIsMore(uint256 numberOfTokens) {
    require(
      _tokenCounter.current() + numberOfTokens <= DICK_LIMIT,
      "Not enough digital dongs left, king."
    );
    _;
  }
   modifier underMintLimit(uint256 numberOfTokens) {
    require(
      numberOfTokens <= MINT_LIMIT,
      "Only 8 digital dicks at a time, king."
    );
    _;
  }

  // Leave a little bit Ether For The Boys (10^17 Wei = 0.1 Ether))
  function withdraw() external onlyOwner {
    uint256 lilBits = 100000000000000000;
    uint256 balance = address(this).balance;
    require(balance > lilBits, "Woah Woah Woah! Save Some For Gas, King.");
    payable(msg.sender).transfer(balance - lilBits);
  }

  function withdrawAll() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function withdrawTokens(IERC20 token) external onlyOwner {
    uint256 balance = token.balanceOf(address(this));
    token.transfer(msg.sender, balance);
  }

  // Allowlist user's OpenSea proxy accounts to enable gas-less listings, king. 
  function isApprovedForAll(address owner, address operator)
    public
    view
    override
    returns (bool)
  {
    ProxyRegistry proxyRegistry = ProxyRegistry(_openSeaProxyRegistryAddress);
    if (
      isOpenSeaProxyActive && address(proxyRegistry.proxies(owner)) == operator
    ) {
      return true;
    }
    return super.isApprovedForAll(owner, operator);
  }

  /**
   * @dev See {IERC165-royaltyInfo}.
   */
  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    require(_exists(tokenId), "Nonexistent token, king.");
    return (address(this), SafeMath.div(SafeMath.mul(salePrice, 8), 100));
  }
}

 // These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {}
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}