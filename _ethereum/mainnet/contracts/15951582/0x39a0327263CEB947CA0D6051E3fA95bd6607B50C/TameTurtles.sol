// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./OperatorFilterer.sol";
import "./PaymentMinimum.sol";

/// @author no-op.eth (nft-lab.xyz)
/// @title Tame Turtles
contract TameTurtles is ERC721A, Ownable, PaymentMinimum, OperatorFilterer {
  /** Maximum number of tokens per wallet */
  uint256 public constant MAX_WALLET = 5;
  /** Maximum amount of tokens in collection */
  uint256 public constant MAX_SUPPLY = 8888;
  /** Price per token */
  uint256 public cost = 0.05 ether;
  /** Base URI */
  string public baseURI;

  /** Public sale state */
  bool public saleActive = false;

  /** Notify on sale state change */
  event SaleStateChanged(bool _val);
  /** Notify on total supply change */
  event TotalSupplyChanged(uint256 _val);

  constructor(
    string memory _name, 
    string memory _symbol,
    uint256 _minimum,
    address _nftlab,
    address[] memory _shareholders, 
    uint256[] memory _shares
  ) 
    ERC721A(_name, _symbol) 
    PaymentMinimum(_minimum, _nftlab, _shareholders, _shares) 
    OperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), false) {}

  /// @notice Returns the base URI
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  /// @notice Sets public sale state
  /// @param _val New sale state
  function setSaleState(bool _val) external onlyOwner {
    saleActive = _val;
    emit SaleStateChanged(_val);
  }

  /// @notice Sets the price
  /// @param _val New price
  function setCost(uint256 _val) external onlyOwner {
    cost = _val;
  }

  /// @notice Sets the base metadata URI
  /// @param _val The new URI
  function setBaseURI(string calldata _val) external onlyOwner {
    baseURI = _val;
  }

  /// @notice Reserves a set of NFTs for collection owner (giveaways, etc)
  /// @param _amt The amount to reserve
  function reserve(uint256 _amt) external onlyOwner {
    _mint(msg.sender, _amt);

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Mints a new token in public sale
  /// @param _amt The number of tokens to mint
  /// @dev Must send cost * amt in ETH
  function mint(uint256 _amt) external payable {
    require(saleActive, "Sale is not yet active.");
    require(_numberMinted(msg.sender) + _amt <= MAX_WALLET, "Amount exceeds wallet limit.");
    require(totalSupply() + _amt <= MAX_SUPPLY, "Amount exceeds supply.");
    require(cost * _amt == msg.value, "ETH sent not equal to cost.");

    _safeMint(msg.sender, _amt);

    emit TotalSupplyChanged(totalSupply());
  }

  /// @dev Override to use filter operator
  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  /// @dev Override to use filter operator
  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  /// @dev Override to use filter operator
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  } 

}