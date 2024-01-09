// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./IFurbz.sol";

/// @author no-op (nftlab: https://discord.gg/kH7Gvnr2qp)
/// @title Furbz
contract Furbz is IFurbz, ERC721Enumerable, Ownable {
  /** Maximum amount of tokens in collection */
  uint256 public constant MAX_SUPPLY = 6969;
  /** The auction house address (probably) */
  address public minter;
  /** Base URI */
  string private _uri;

  constructor(string memory name, string memory symbol) ERC721(name, symbol) {}
 
  /// @notice Sets the base metadata URI
  /// @param val The new URI
  function setBaseURI(string memory val) external override onlyOwner {
    _uri = val;
  }

  /// @notice Sets the address for who can mint from this contract
  /// @param val The address
  function setMinter(address val) external override onlyOwner {
    minter = val;
  }

  /// @notice Reserves a set of NFTs for collection owner (giveaways, etc)
  /// @param amt The amount to reserve
  function reserve(uint256 amt) external override onlyOwner {
    uint256 _currentSupply = totalSupply();
    for (uint256 i = 0; i < amt; i++) {
      _safeMint(msg.sender, _currentSupply + i);
    }
  }

  /// @notice Mints a new token
  /// @dev Only minter can do this
  function mint() external override returns (uint256) {
    uint256 _currentSupply = totalSupply();
    require(msg.sender == minter, "Address is not minter.");
    require(_currentSupply + 1 <= MAX_SUPPLY, "Amount exceeds supply.");
    _safeMint(msg.sender, _currentSupply);
    return _currentSupply;
  }

  /// @notice Burns a token
  /// @param id The token ID to be burned
  /// @dev Only minter can do this
  function burn(uint256 id) external override {
    require(msg.sender == minter, "Address is not minter.");
    _burn(id);
  }

  /// @notice Returns base URI
  /// @dev Refers to uri var for super baseURI function
  function _baseURI()
    internal
    view
    virtual
    override
    returns (string memory)
  {
    return _uri;
  }
}