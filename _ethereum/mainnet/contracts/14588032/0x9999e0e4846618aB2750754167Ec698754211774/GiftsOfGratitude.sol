// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//   ____           _   _ _             _      
//  / ___|_ __ __ _| |_(_) |_ _   _  __| | ___ 
// | |  _| '__/ _` | __| | __| | | |/ _` |/ _ \
// | |_| | | | (_| | |_| | |_| |_| | (_| |  __/
//  \____|_|  \__,_|\__|_|\__|\__,_|\__,_|\___|
//
// A collection of 2,222 unique Non-Fungible Power SUNFLOWERS living in 
// the metaverse. Becoming a GRATITUDE GANG NFT owner introduces you to 
// a FAMILY of heart-centered, purpose-driven, service-oriented human 
// beings.
//
// https://www.gratitudegang.io/
//

import "./Ownable.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";

import "./Strings.sol";
import "./ECDSA.sol";

import "./SafeERC20.sol";

import "./ERC1155Burnable.sol";
import "./ERC1155Pausable.sol";
import "./ERC1155Supply.sol";

// ============ Errors ============

error InvalidCall();

// ============ Interfaces ============

interface IERC20Burnable is IERC20 {
  /**
   * @dev Destroys `amount` tokens from `account`, deducting from the caller's
   * allowance.
   */
  function burnFrom(address account, uint256 amount) external;
}

// ============ Contract ============

/**
 * @dev Gratitude store where members can buy other NFTs
 */
contract GiftsOfGratitude is 
  Ownable,
  ReentrancyGuard,
  ERC1155Burnable,
  ERC1155Pausable,
  ERC1155Supply,
  AccessControl
{
  using Strings for uint256;

  // ============ Structs ============

  struct Token {
    uint256 maxSupply;
    uint256 ethPrice;
    uint256 gratisPrice;
    bool active;
  }

  // ============ Constants ============

  bytes32 public constant FUNDER_ROLE = keccak256("FUNDER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");

  IERC20Burnable public immutable GRATIS;

  // ============ Storage ============

  //a count of total items
  uint256 public totalTokens;
  //mapping of token id to token info (max, price)
  mapping(uint256 => Token) private _tokens;
  //the contract metadata
  string private _contractURI;

  // ============ Deploy ============

  /**
   * @dev Sets the base token uri
   */
  constructor(
    string memory contract_uri, 
    string memory token_uri,
    IERC20Burnable gratis,
    address admin
  ) ERC1155(token_uri) {
    _contractURI = contract_uri;
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    _setupRole(PAUSER_ROLE, admin);
    GRATIS = gratis;
  }

  // ============ Read Methods ============

  /**
   * @dev Returns the contract URI
   */
  function contractURI() external view returns(string memory) {
    return _contractURI;
  }

  /**
   * @dev Returns true if the token exists
   */
  function exists(uint256 id) public view override returns(bool) {
    return _tokens[id].active;
  }

  /**
   * @dev Get the maximum supply for a token
   */
  function maxSupply(uint256 id) public view returns(uint256) {
    return _tokens[id].maxSupply;
  }

  /**
   * @dev Get the mint supply for a token
   */
  function ethPrice(uint256 id) public view returns(uint256) {
    return _tokens[id].ethPrice;
  }

  /**
   * @dev Get the mint supply for a token
   */
  function gratisPrice(uint256 id) public view returns(uint256) {
    return _tokens[id].gratisPrice;
  }

  /**
   * @dev Returns the name
   */
  function name() external pure returns(string memory) {
    return "Gifts of Gratitude";
  }

  /**
   * @dev Get the remaining supply for a token
   */
  function remainingSupply(uint256 id) public view returns(uint256) {
    uint256 max = maxSupply(id);
    if (max == 0) revert InvalidCall();
    return max - totalSupply(id);
  }

  /**
   * @dev Returns the symbol
   */
  function symbol() external pure returns(string memory) {
    return "GOG";
  }

  /**
   * @dev Returns the max and price for a token
   */
  function tokenInfo(uint256 id) 
    external view returns(uint256 max, uint256 eth, uint256 gratis, uint256 supply)
  {
    return (
      _tokens[id].maxSupply, 
      _tokens[id].ethPrice, 
      _tokens[id].gratisPrice, 
      totalSupply(id)
    );
  }

  /**
   * @dev See {IERC1155MetadataURI-uri}.
   *
   * This implementation returns the same URI for *all* token types. It relies
   * on the token type ID substitution mechanism
   * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
   *
   * Clients calling this function must replace the `\{id\}` substring with the
   * actual token type ID.
   */
  function uri(uint256 id) public view virtual override returns(string memory) {
    if (exists(id)) {
      return string(abi.encodePacked(super.uri(id), "/", id.toString(), ".json"));
    }
    
    return string(abi.encodePacked(super.uri(id), "/{id}.json"));
  }

  // ============ Write Methods ============

  /**
   * @dev Allows anyone to mint by purchasing with eth
   */
  function buy(address to, uint256 id, uint256 quantity) 
    external payable nonReentrant 
  {
    //get price
    uint256 price = ethPrice(id) * quantity;
    //if there is a price and the amount sent is less than
    if (price == 0 || msg.value < price) revert InvalidCall();
    //we are okay to mint
    _mintSupply(to, id, quantity);
  }

  /**
   * @dev Allows anyone to redeem with a voucher (proof)
   */
  function redeem(
    address to, 
    uint256 id, 
    uint256 quantity, 
    bytes memory voucher
  ) external nonReentrant {
    //make sure the minter signed this off
    if (!hasRole(MINTER_ROLE, ECDSA.recover(
      ECDSA.toEthSignedMessageHash(
        keccak256(abi.encodePacked("redeem", to, id, quantity))
      ),
      voucher
    ))) revert InvalidCall();

    //we are okay to mint
    _mintSupply(to, id, quantity);
  }

  /**
   * @dev Allows anyone to mint by purchasing with eth
   */
  function support(address to, uint256 id, uint256 quantity) 
    external payable nonReentrant 
  {
    //get price
    uint256 price = gratisPrice(id) * quantity;
    //if there is a price and the amount sent is less than
    if( price == 0) revert InvalidCall();
    //burn it. muhahaha
    GRATIS.burnFrom(to, price);
    //we are okay to mint
    _mintSupply(to, id, quantity);
  }

  // ============ Admin Methods ============

  /**
   * @dev Adds a token that can be minted
   */
  function addToken(uint256 id, uint256 max, uint256 eth, uint256 gratis) 
    external onlyRole(CURATOR_ROLE) 
  {
    _tokens[id] = Token(max, eth, gratis, true);
    totalTokens++;
  }

  /**
   * @dev Allows admin to mint
   */
  function mint(address to, uint256 id, uint256 quantity) 
    external onlyRole(MINTER_ROLE) 
  {
    _mintSupply(to, id, quantity);
  }

  /**
   * @dev Pauses all token transfers.
   */
  function pause() public virtual onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   */
  function unpause() public virtual onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  /**
   * @dev Allows admin to update URI
   */
  function updateURI(string memory newuri) 
    external onlyRole(CURATOR_ROLE) 
  {
    _setURI(newuri);
  }

  /**
   * @dev Sends the entire contract balance to a `recipient`. 
   */
  function withdraw(address recipient) 
    external nonReentrant onlyRole(FUNDER_ROLE)
  {
    Address.sendValue(payable(recipient), address(this).balance);
  }

  /**
   * @dev This contract should not hold any tokens in the first place. 
   * This method exists to transfer out tokens funds.
   */
  function withdraw(IERC20 erc20, address recipient, uint256 amount) 
    external nonReentrant onlyRole(FUNDER_ROLE)
  {
    SafeERC20.safeTransfer(erc20, recipient, amount);
  }

  // ============ Internal Methods ============

  /**
   * @dev Mint token considering max supply
   */
  function _mintSupply(address to, uint256 id, uint256 quantity) internal {
    //if the id does not exists
    if (!exists(id)) revert InvalidCall();
    //get max and calculated supply
    uint256 max = maxSupply(id);
    uint256 supply = totalSupply(id) + quantity;
    //if there is a max supply and it was exceeded
    if(max > 0 && supply > max) revert InvalidCall();
    //we are okay to mint
    _mint(to, id, quantity, "");
  }

  // ============ Overrides ============

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) 
    public 
    view 
    virtual 
    override(AccessControl, ERC1155) 
    returns(bool) 
  {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev Describes linear override for `_beforeTokenTransfer` used in 
   * both `ERC721` and `ERC721Pausable`
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override(ERC1155, ERC1155Pausable, ERC1155Supply) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
}