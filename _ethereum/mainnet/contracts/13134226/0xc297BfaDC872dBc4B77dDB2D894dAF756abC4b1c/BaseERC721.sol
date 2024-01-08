// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./AccessControl.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

abstract contract BaseERC721 is ERC721Enumerable, Ownable, AccessControl {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;

  string private __baseURI;
  string private _contractURI;

  uint256 public mintLimit;
  uint256 public numberMinted = 0;

  mapping(address => uint256[]) public userOwnedTokens;

  function getOwnedTokens() external view returns (uint256[] memory) {
    return userOwnedTokens[msg.sender];
  }

  constructor (
    string memory name,
    string memory symbol,
    uint256 __mintLimit,
    string memory baseURI,
    string memory __contractURI
  ) ERC721(name, symbol) {
    _setupRole(MINTER_ROLE, msg.sender);
    mintLimit = __mintLimit;
    __baseURI = baseURI;
    _contractURI = __contractURI;
  }

  // Opensea custom method
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function _baseURI() internal view override(ERC721) returns (string memory) {
    return __baseURI;
  }

  modifier onlyMinter {
    require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
    _;
  }

  function isOwner(uint256 _tokenId) internal view returns(bool) {
    return msg.sender == ownerOf(_tokenId);
  }

  function _mint() internal virtual onlyMinter returns (uint256) {
    require(numberMinted < mintLimit, string(abi.encodePacked('Mint limit reached (', Strings.toString(mintLimit), ')')));
    _tokenIds.increment();
    uint256 tokenId = _tokenIds.current();

    ERC721._safeMint(msg.sender, tokenId);
    numberMinted++;
    userOwnedTokens[msg.sender].push(tokenId);

    return tokenId;
  }

  function _buy(uint256 tokenId) internal {
    ERC721._approve(msg.sender, tokenId);
    userOwnedTokens[msg.sender].push(tokenId);
  }

  function confirmTokenExists(uint256 tokenId) internal view {
    require(_exists(tokenId), 'tokenId does not exist');
  }

  function confirmTokenOwner(uint256 tokenId) internal view {
    require(isOwner(tokenId), 'token not owned by sender');
  }

  function supportsInterface(bytes4 interfaceId) public view virtual
    override(ERC721Enumerable, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual
  override(ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, amount);
  }
}
