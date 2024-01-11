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

import "./FEEVMembershipNFT.sol";

contract FeevieNFT is AccessControl, ERC721, ERC721Enumerable, IERC2981 {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  string public baseURI;
  address public owner;
  address public membershipNFT;
  uint256 private royaltyBPS;
  address private royaltyReceiver;

  constructor(
    string memory _name,
    string memory _symbol,
    address _owner,
    address _royaltyReceiver,
    string memory _initialURI
  ) ERC721(_name, _symbol) {
    _tokenIdCounter.increment();
    _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    baseURI = _initialURI;
    royaltyBPS = 800;
    royaltyReceiver = _royaltyReceiver;
    owner = _owner;
  }

  /// @dev Function to mint new NFT tokens
  /// @param to Address of new NFTs' owner
  /// @param tokensAmount Amount of NFTs to mint
  /// @notice It can be called only by address with minter role
  function safeMint(address to, uint256 tokensAmount) public onlyRole(MINTER_ROLE) {
    for (uint256 i = 0; i < tokensAmount; i++) {
      uint256 tokenId = _tokenIdCounter.current();
      _tokenIdCounter.increment();
      _safeMint(to, tokenId);
    }
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

  /// @dev Function to set connected FEEV MC NFT contract
  /// @param _membershipNFT Address of FEEV MC NFT contract
  /// @notice Address can be set once
  function setMembershipNFT(address _membershipNFT) external {
    require(membershipNFT == address(0), "MembershipNFT is already set");
    _grantRole(MINTER_ROLE, _membershipNFT);
    membershipNFT = _membershipNFT;
  }

  function isApprovedForAll(address _owner, address _operator)
    public
    view
    override
    returns (bool isOperator)
  {
    if (_operator == membershipNFT) {
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
    FEEVMembershipNFT(membershipNFT).onFeevieTransfer(from, to, tokenId);
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
    FEEVMembershipNFT(membershipNFT).onFeevieTransfer(from, to, tokenId);
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
    FEEVMembershipNFT(membershipNFT).onFeevieTransfer(from, to, tokenId);
  }

  /// @dev Hook which is called on FEEV MC contract after MC token transfer
  function onMembershipNFTTransfer(
    address from,
    address to,
    uint256 tokenId
  ) external {
    require(msg.sender == membershipNFT, "Only for membership NFT contract");
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
