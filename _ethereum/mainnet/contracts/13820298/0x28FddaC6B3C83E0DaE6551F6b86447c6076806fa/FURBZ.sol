// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./PaymentSplitter.sol";

/// @author no-op (nftlab: https://discord.gg/kH7Gvnr2qp)
/// @title Furbz
contract Furbz is ERC721Enumerable, Ownable, PaymentSplitter {
  /** Maximum amount of tokens in collection */
  uint256 public constant MAX_SUPPLY = 6969;
  /** Maximum number of tokens per tx */
  uint256 public constant MAX_TX = 9;
  /** Price per token */
  uint256 public constant COST = 0.0420 ether;
  /** Base URI */
  string private _uri;
  /** Public sale state */
  bool public saleActive = false;

  /** Notify on sale state change */
  event SaleStateChanged(bool val);
  /** Notify on total supply change */
  event TotalSupplyChanged(uint256 val);

  constructor(
    string memory name,
    string memory symbol,
    address[] memory shareholders,
    uint256[] memory shares
  ) 
    ERC721(name, symbol) 
    PaymentSplitter(shareholders, shares) {}

  /// @notice Sets public sale state
  /// @param val The new value
  function setSaleState(bool val) external onlyOwner {
    saleActive = val;
    emit SaleStateChanged(val);
  }

  /// @notice Sets the base metadata URI
  /// @param val The new URI
  function setBaseURI(string memory val) external onlyOwner {
    _uri = val;
  }

  /// @notice Reserves a set of NFTs for collection owner (giveaways, etc)
  /// @param amt The amount to reserve
  function reserve(uint256 amt) external onlyOwner {
    uint256 _currentSupply = totalSupply();
    for (uint256 i = 0; i < amt; i++) {
      _safeMint(msg.sender, _currentSupply + i);
    }

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Mints a new token in public sale
  /// @param amt The number of tokens to mint
  /// @dev Must send COST * amt in ETH
  function mint(uint256 amt) external payable {
    uint256 _currentSupply = totalSupply();
    require(saleActive, "Sale is not yet active.");
    require(_currentSupply + amt <= MAX_SUPPLY, "Amount exceeds supply.");
    require(COST * amt <= msg.value, "ETH sent is below cost.");

    for (uint256 i = 0; i < amt; i++) {
      _safeMint(msg.sender, _currentSupply + i);
    }

    emit TotalSupplyChanged(totalSupply());
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