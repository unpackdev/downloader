// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Counters.sol";
import "./Strings.sol";

/// @author no-op.eth (nftlab: https://discord.gg/kH7Gvnr2qp)
/// @title Wildfire Bears
contract WildfireBears is ERC1155, Ownable, PaymentSplitter {
  /** Maximum number of tokens per tx */
  uint256 public constant MAX_TX = 10;
  /** Maximum amount of tokens in collection */
  uint256 public constant MAX_SUPPLY = 5555;
  /** Price per token */
  uint256 public constant COST = 0.01 ether;
  /** Name of collection */
  string public constant name = "Wildfire Bears";
  /** Symbol of collection */
  string public constant symbol = "WB";
  /** URI for the contract metadata */
  string public contractURI;
  
  /** Public sale state */
  bool public saleActive = false;

  /** Total supply */
  Counters.Counter private _supply;

  /** Notify on sale state change */
  event SaleStateChanged(bool val);
  /** Notify on presale state change */
  event PresaleStateChanged(bool val);
  /** Notify on total supply change */
  event TotalSupplyChanged(uint256 val);

  /** For URI conversions */
  using Strings for uint256;
  /** For supply count */
  using Counters for Counters.Counter;

  constructor(
    string memory _uri, 
    address[] memory shareholders, 
    uint256[] memory shares
  ) ERC1155(_uri) PaymentSplitter(shareholders, shares) {}

  /// @notice Sets public sale state
  /// @param val The new value
  function setSaleState(bool val) external onlyOwner {
    saleActive = val;
    emit SaleStateChanged(val);
  }

  /// @notice Sets the base metadata URI
  /// @param val The new URI
  function setBaseURI(string memory val) external onlyOwner {
    _setURI(val);
  }

  /// @notice Sets the contract metadata URI
  /// @param val The new URI
  function setContractURI(string memory val) external onlyOwner {
    contractURI = val;
  }

  /// @notice Returns the amount of tokens sold
  /// @return supply The number of tokens sold
  function totalSupply() public view returns (uint256) {
    return _supply.current();
  }

  /// @notice Returns the URI for a given token ID
  /// @param id The ID to return URI for
  /// @return Token URI
  function uri(uint256 id) public view override returns (string memory) {
    return string(abi.encodePacked(super.uri(id), id.toString()));
  }

  /// @notice Reserves a set of NFTs for collection owner (giveaways, etc)
  /// @param amt The amount to reserve
  function reserve(uint256 amt) external onlyOwner {
    uint256 _currentSupply = _supply.current();
    for (uint256 i = 0; i < amt; i++) {
      _supply.increment();
      _mint(msg.sender, _currentSupply + i, 1, "0x0000");
    }

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Mints a new token in public sale
  /// @param amt The number of tokens to mint
  /// @dev Must send COST * amt in ETH
  function mint(uint256 amt) external payable {
    uint256 _currentSupply = _supply.current();
    require(saleActive, "Sale is not yet active.");
    require(amt <= MAX_TX, "Amount of tokens exceeds transaction limit.");
    require(_currentSupply + amt <= MAX_SUPPLY, "Amount exceeds supply.");
    require(COST * amt <= msg.value, "ETH sent is below cost.");

    for (uint256 i = 0; i < amt; i++) {
      _supply.increment();
      _mint(msg.sender, _currentSupply + i, 1, "0x0000");
    }

    emit TotalSupplyChanged(totalSupply());
  }
}