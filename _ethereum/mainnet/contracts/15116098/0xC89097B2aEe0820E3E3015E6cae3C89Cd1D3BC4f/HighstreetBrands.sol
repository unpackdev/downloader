// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155Supply.sol";
import "./ERC1155Burnable.sol";
import "./Strings.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./MinterAccessControl.sol";
/**
 * @title Product NFT
 *
 * @notice Each prodcut has its own NFT, will be minted to user when trade in product
 *
 * @notice The tokenId of the NFT is determined according to the order of the tradein
 */
contract HighstreetBrands is Context, ERC1155Burnable, ERC1155Supply, Ownable, MinterAccessControl {

  using Strings for uint256;

  /// @dev a list of maxSupply of corresponding tokenId
  mapping(uint256 => uint256) private _maxSupply;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  event SetMaxSupply(uint256 indexed id, uint256 amount);

  /**
    * @dev Fired in mintBatch()
    *
    * @param to an address which received nfts
    * @param start a first number of this batch
    * @param count a number of of this batch
    */
  event MintBatch(address indexed to, uint256[] start, uint256[] count);

  /**
    * @dev Fired in updateBaseURI()
    *
    * @param sender an address which performed an operation, usually token owner
    * @param uri a stringof base uri for this nft
    */
  event UpdateBaseUri(address indexed sender, string uri);

  /**
    * @dev Creates/deploys an instance of the NFT
    *
    * @param name_ the name of this nft
    * @param symbol_ the symbol of this nft
    * @param uri_ a string of base uri for this nft
    */
  constructor(
    string memory name_,
    string memory symbol_,
    string memory uri_
  ) ERC1155(uri_) {
    _name = name_;
    _symbol = symbol_;
  }

  function name() public view virtual returns (string memory) {
    return _name; 
  }

  function symbol() public view virtual returns (string memory) {
    return _symbol;
  }

  function decimals() public view virtual returns (uint8) {
    return 0;
  }

  function uri(uint256 id_) public view override returns (string memory) {
    require(exists(id_), "URI query for nonexistent token");
    return bytes(super.uri(id_)).length > 0 ? string(abi.encodePacked(super.uri(id_), id_.toString())) : "";
  }

  /**
    * @notice Service function to grant minter role
    *
    * @dev this function can only be called by owner
    *
    * @param addr_ an address which is granted minter role
    */
  function grantMinterRole(address addr_) public onlyOwner {
    _grantMinterRole(addr_);
  }

  /**
    * @notice Service function to revoke minter role
    *
    * @dev this function can only be called by owner
    *
    * @param addr_ an address which is revorked minter role
    */
  function revokeMinterRole(address addr_) external onlyOwner {
    _revokeMinterRole(addr_);
  }

  /**
    * @notice Service function to update base uri
    *
    * @dev this function can only be called by owner
    *
    * @param uri_ a string for updating base uri
    */
  function updateBaseUri(string memory uri_) external onlyOwner {
    _setURI(uri_);
    emit UpdateBaseUri(_msgSender(), uri_);
  }

  /**
    * @notice Service function to mint nft
    *
    * @dev this function can only be called by minters
    *
    * @param to_ an address which received nft
    * @param id_ a number of id to be minted
    * @param amount_ a number of how much token would be minted
    * @param data_ extra data
    */
  function mint(
    address to_,
    uint256 id_,
    uint256 amount_,
    bytes memory data_
  ) external
    onlyMinter
  {
    _mint(to_, id_, amount_, data_);
  }

  /**
    * @notice Service function to mint nfts at same time
    *
    * @dev this function can only be called by minters
    *
    * @param to_ an address which received nft
    * @param ids_ a first number of this batch
    * @param amounts_ a number of of this batch
    * @param data_ extra data
    */
  function mintBatch(
    address to_,
    uint256[] memory ids_,
    uint256[] memory amounts_,
    bytes memory data_
  ) external
    onlyMinter
  {
    _mintBatch(to_, ids_, amounts_, data_);
  }

  function setMaxSupply(uint256 id_, uint256 amount_) external virtual onlyMinter {
    require(amount_ >= totalSupply(id_), "invalid amount");
    _maxSupply[id_] = amount_;
    emit SetMaxSupply(id_, amount_);
  }

  function maxSupply(uint256 id_) public view returns (uint256) {
    return _maxSupply[id_];
  }

  /**
  *
  * @dev Additionally to the parent smart contract, return string of base uri
  */
  function _baseURI() internal view returns (string memory) {
    return uri(0);
  }

  function _beforeTokenTransfer(
    address operator_, 
    address from_,
    address to_,
    uint256[] memory ids_,
    uint256[] memory amounts_,
    bytes memory data_
  ) internal
    virtual
    override(ERC1155, ERC1155Supply)
  {
    if (from_ == address(0)) {
      for (uint256 i = 0; i < ids_.length; i++) {
        require(
          totalSupply(ids_[i]) + amounts_[i] <= _maxSupply[ids_[i]],
          "cap exceeded"
        );
      }
    }
    super._beforeTokenTransfer(operator_, from_, to_, ids_, amounts_, data_);
  }

}
