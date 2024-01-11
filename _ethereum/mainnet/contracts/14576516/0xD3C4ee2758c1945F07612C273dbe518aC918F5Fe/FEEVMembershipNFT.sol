// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./AccessControl.sol";
import "./ERC165.sol";
import "./IERC2981.sol";

import "./FeevieNFT.sol";

contract FEEVMembershipNFT is AccessControl, ERC721, ERC721Enumerable, IERC2981 {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  uint256 private constant INITIAL_MINT_LIMIT = 130;

  string public baseURI;
  uint256 public maxSupply;
  uint256[] public priceRanges;
  uint256[] public prices;
  address public feevieNFT;
  address private royaltyReceiver;
  uint256 private royaltyBPS;
  address private initialMintRecipient;
  uint256 private amountOfInitiallyMintedTokens;
  address public owner;

  constructor(
    string memory _name,
    string memory _symbol,
    address _owner,
    address _minter,
    address _initialMintRecipient,
    uint256 _maxSupply,
    address _royaltyReceiver,
    string memory _initialURI,
    address _feevieNFT,
    uint256[] memory _priceRanges,
    uint256[] memory _prices
  ) ERC721(_name, _symbol) {
    maxSupply = _maxSupply;
    _tokenIdCounter.increment();
    _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    _grantRole(MINTER_ROLE, _owner);
    _grantRole(MINTER_ROLE, _minter);
    baseURI = _initialURI;
    royaltyBPS = 800;
    royaltyReceiver = _royaltyReceiver;
    priceRanges = _priceRanges;
    prices = _prices;
    feevieNFT = _feevieNFT;
    initialMintRecipient = _initialMintRecipient;
    owner = _owner;

    FeevieNFT(feevieNFT).setMembershipNFT(address(this));
  }

  /// @dev Function to mint initial amount of tokens to the feev.eth
  /// @param amount Amount of tokens to mint
  /// @notice It is possible to mint only 130 tokens
  function initialMint(uint256 amount) external {
    require(amountOfInitiallyMintedTokens + amount <= INITIAL_MINT_LIMIT, "Reached limit for minting");

    for (uint256 i = 0; i < amount; i++) {
      uint256 tokenId = _tokenIdCounter.current();
      _tokenIdCounter.increment();
      _safeMint(initialMintRecipient, tokenId);
    }

    FeevieNFT(feevieNFT).safeMint(initialMintRecipient, amount);
    amountOfInitiallyMintedTokens += amount;
  }

  /// @dev Function to mint new NFT tokens
  /// @param to Address of new NFTs' owner
  /// @param tokensAmount Amount of NFTs to mint
  /// @notice It can be called only by address with minter role
  function safeMint(address to, uint256 tokensAmount) public onlyRole(MINTER_ROLE) {
    require(_tokenIdCounter.current() + tokensAmount <= maxSupply, "Reached limit for minting");

    for (uint256 i = 0; i < tokensAmount; i++) {
      uint256 tokenId = _tokenIdCounter.current();
      _tokenIdCounter.increment();
      _safeMint(to, tokenId);
    }
    FeevieNFT(feevieNFT).safeMint(to, tokensAmount);
  }

  /// @dev Change owner address
  /// @param newOwner Address of new owner
  function changeOwner(address newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
    owner = newOwner;
    _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
    _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  /// @dev Change baseURI
  /// @param newURI New uri to new folder with metadata
  /// @notice It can be called only by owner
  function setBaseURI(string memory newURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
    baseURI = newURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  /// @dev Function to set new royalties for each NFT token in the collection
  /// @param _royaltyBPS Royalty amount in BPS (0 - 0%, 100% - 10000)
  /// @param _royaltyReceiver Address of royalty receiver
  /// @notice It can be called only by administrator
  function setRoyalties(uint256 _royaltyBPS, address _royaltyReceiver)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    royaltyBPS = _royaltyBPS;
    royaltyReceiver = _royaltyReceiver;
  }

  /// @dev Getter for info about royalty
  /// @param tokenId Id of NFT token
  /// @param salePrice Price to calculate royalty
  /// @return receiver Address of royalty receiver
  /// @return royaltyAmount Amount of calculated royalty
  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    uint256 price = (salePrice * royaltyBPS) / 10000;
    return (royaltyReceiver, price);
  }

  /// @dev Getter for price of minting
  /// @param tokensAmount Amount of NFT tokens to mint
  /// @return uint256 calculated price of minting
  function getPrice(uint256 tokensAmount) external view returns (uint256) {
    uint256 currentSupply = totalSupply();
    uint256 price = 0;

    for (
      uint256 tokenNumber = currentSupply + 1;
      tokenNumber <= currentSupply + tokensAmount;
      tokenNumber++
    ) {
      for (uint256 rangeIndex = 0; rangeIndex < priceRanges.length; rangeIndex++) {
        if (tokenNumber > priceRanges[rangeIndex]) {
          continue;
        } else {
          price += prices[rangeIndex];
          break;
        }
      }
    }

    return price;
  }

  function isApprovedForAll(address _owner, address _operator)
    public
    view
    override
    returns (bool isOperator)
  {
    if (_operator == feevieNFT) {
      return true;
    }

    return super.isApprovedForAll(_owner, _operator);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    super.transferFrom(from, to, tokenId);
    FeevieNFT(feevieNFT).onMembershipNFTTransfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    super.safeTransferFrom(from, to, tokenId, "");
    FeevieNFT(feevieNFT).onMembershipNFTTransfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    super.safeTransferFrom(from, to, tokenId, _data);
    FeevieNFT(feevieNFT).onMembershipNFTTransfer(from, to, tokenId);
  }

  /// @dev Hook which is called on Feevie contract after Feevie token transfer
  function onFeevieTransfer(
    address from,
    address to,
    uint256 tokenId
  ) external {
    require(msg.sender == feevieNFT, "Only for feevie contract");
    super._transfer(from, to, tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId), "ERC721: nonexistent token");
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable, IERC165, AccessControl)
    returns (bool)
  {
    if (interfaceId == type(IERC2981).interfaceId) {
      return true;
    }

    return super.supportsInterface(interfaceId);
  }
}
