// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";

//    |\__/,|   (`\
//  _.|o o  |_   ) )
// -(((---(((--------

/// @author no-op.eth (nftlab: nft-lab.xyz)
/// @title Menacing Society | Access Pass (menacingsociety.com)
contract MenacingVIP is ERC1155, ERC1155Burnable, Ownable, PaymentSplitter {
  /** Name of collection */
  string public constant name = "Menacing Society | Access Pass";
  /** Symbol of collection */
  string public constant symbol = "MSVIP";
  /** Price per token */
  uint256 public constant COST = 0.1 ether;
  /** Max per Tx */
  uint256 public constant MAX_TX = 2;
  /** Maximum amount of tokens in collection */
  uint256 public MAX_SUPPLY = 100;
  /** URI for the contract metadata */
  string public contractURI;
  
  /** Public sale state */
  bool public saleActive = false;

  /** Total supply */
  uint256 private _supply = 0;

  /** Notify on sale state change */
  event SaleStateChanged(bool val);
  /** Notify on total supply change */
  event TotalSupplyChanged(uint256 val);

  /** For URI conversions */
  using Strings for uint256;

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
    return _supply;
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
    require(_supply + amt <= MAX_SUPPLY, "Amount exceeds supply.");

    _supply += amt;
    _mint(msg.sender, 0, amt, "0x0000");

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Mints a new token in public sale
  /// @param amt The number of tokens to mint
  /// @dev Must send COST * amt in ETH
  function mint(uint256 amt) external payable {
    require(saleActive, "Sale is not yet active.");
    require(amt <= MAX_TX, "Amount of tokens exceeds transaction limit.");
    require(_supply + amt <= MAX_SUPPLY, "Amount exceeds supply.");
    require(COST * amt == msg.value, "ETH sent is not equal to cost.");

    _supply += amt;
    _mint(msg.sender, 0, amt, "0x0000");

    emit TotalSupplyChanged(totalSupply());
  }
}