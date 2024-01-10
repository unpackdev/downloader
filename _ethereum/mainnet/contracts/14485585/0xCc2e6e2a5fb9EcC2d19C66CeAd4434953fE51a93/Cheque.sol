// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Pausable.sol";
import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Counters.sol";

import "./ICheque.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functios using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract Cheque is
  Context,
  Ownable,
  ERC721Enumerable,
  ERC721Pausable,
  ICheque
{
  using Counters for Counters.Counter;

  uint256 public maxSupply;

  Counters.Counter private _tokenIdTracker;
  address private _proxy;
  string private _baseTokenURI;

  constructor(
    string memory name,
    string memory symbol,
    string memory baseTokenURI,
    uint256 maxTokenSupply,
    address proxy
  ) ERC721(name, symbol) {
    _baseTokenURI = baseTokenURI;
    maxSupply = maxTokenSupply;
    _tokenIdTracker.increment();

    _proxy = proxy;
  }

  modifier onlyProxy() {
    require(_msgSender() == _proxy, "Only proxy can perform this action");
    _;
  }

  function mintedCount() external view returns (uint256) {
    return _tokenIdTracker.current() - 1;
  }

  function setBaseURI(string memory uri) external onlyOwner {
    _baseTokenURI = uri;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }
  
  function mint(address to) public virtual onlyProxy returns (uint256) {
    require(_tokenIdTracker.current() <= maxSupply, "Max supply reached");
  
    // We cannot just use balanceOf to create the new tokenId because tokens
    // can be burned (destroyed), so we need a separate counter.
    _mint(to, _tokenIdTracker.current());
    _tokenIdTracker.increment();
    return _tokenIdTracker.current() - 1;
  }

  /**
   * @dev Burns `tokenId`. See {ERC721-_burn}.
   *
   * Requirements:
   *
   * - The caller must own `tokenId` or be an approved operator.
   */
  function burn(uint256 tokenId) public virtual {
    //solhint-disable-next-line max-line-length
    require(_msgSender() == _proxy || _isApprovedOrOwner(_msgSender(), tokenId), "Caller is not proxy, owner nor approved");
    _burn(tokenId);
  }
  
  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC721Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function pause() external virtual onlyOwner {
    _pause();
  }
  
  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC721Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function unpause() external virtual onlyOwner {
    _unpause();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721Enumerable, ERC721Pausable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
