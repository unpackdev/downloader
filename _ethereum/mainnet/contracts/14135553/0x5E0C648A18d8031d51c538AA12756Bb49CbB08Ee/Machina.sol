// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./MerkleProof.sol";
import "./ERC721Enumerable.sol";

/// @author no-op (nftlab: https://discord.gg/kH7Gvnr2qp)
/// @title Broken Machina
contract BrokenMachina is ERC721Enumerable, PaymentSplitter, Ownable {
  /** Maximum number of tokens per tx */
  uint256 public constant MAX_TX = 10;
  /** Maximum amount of tokens in collection */
  uint256 public constant MAX_SUPPLY = 10000;
  /** Base URI */
  string public baseURI;

  /** Merkle tree for whitelist */
  bytes32 public merkleRoot;

  /** Public sale state */
  bool public saleActive = false;
  /** Presale state */
  bool public presaleActive = false;

  /** Notify on sale state change */
  event SaleStateChanged(bool val);
  /** Notify on presale state change */
  event PresaleStateChanged(bool val);
  /** Notify on total supply change */
  event TotalSupplyChanged(uint256 val);

  constructor(
    address[] memory shareholders, 
    uint256[] memory shares
  ) ERC721("Broken Machina", "BM") PaymentSplitter(shareholders, shares) {}

  /// @notice Returns the URI for a given token
  /// @param tokenId The token to get a URI for
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "Token does not exist.");
    return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
  }

  /// @notice Checks if an address is whitelisted
  /// @param addr Address to check
  /// @param proof Merkle proof
  function isWhitelisted(address addr, bytes32[] calldata proof) public view returns (bool) {
    bytes32 _leaf = keccak256(abi.encodePacked(addr));
    return MerkleProof.verify(proof, merkleRoot, _leaf);
  }

  /// @notice Calculates whitelist pack discounts
  /// @param amt Number being purchased
  function whitelistCost(uint256 amt) public pure returns (uint256) {
    if (amt % 10 == 0) { return amt * 0.04 ether; }
    if (amt % 5 == 0) { return amt * 0.05 ether; }
    if (amt % 3 == 0)  { return amt * 0.0533 ether; }
    return amt * 0.06 ether;
  }

  /// @notice Calculates pack discounts
  /// @param amt Number being purchased
  function cost(uint256 amt) public pure returns (uint256) {
    if (amt % 10 == 0) { return amt * 0.065 ether; }
    if (amt % 5 == 0) { return amt * 0.068 ether; }
    if (amt % 3 == 0)  { return amt * 0.07 ether; }
    return amt * 0.09 ether;
  }

  /// @notice Sets public sale state
  /// @param val The new value
  function setSaleState(bool val) external onlyOwner {
    saleActive = val;
    emit SaleStateChanged(val);
  }

  /// @notice Sets presale state
  /// @param val The new value
  function setPresaleState(bool val) external onlyOwner {
    presaleActive = val;
    emit PresaleStateChanged(val);
  }

  /// @notice Sets the whitelist
  /// @param val Root
  function setWhitelist(bytes32 val) external onlyOwner {
    merkleRoot = val;
  }

  /// @notice Sets the base metadata URI
  /// @param val The new URI
  function setBaseURI(string calldata val) external onlyOwner {
    baseURI = val;
  }

  /// @notice Reserves a set of NFTs for collection owner (giveaways, etc)
  /// @param amt The amount to reserve
  function reserve(uint256 amt) external onlyOwner {
    uint256 _currentSupply = totalSupply();
    for (uint256 i = 0; i < amt; i++) {
      _mint(msg.sender, _currentSupply + i);
    }

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Mints a new token in public sale
  /// @param amt The number of tokens to mint
  /// @dev Must send COST * amt in ETH
  function mint(uint256 amt) external payable {
    uint256 _currentSupply = totalSupply();
    require(saleActive, "Sale is not yet active.");
    require(amt <= MAX_TX, "Amount of tokens exceeds transaction limit.");
    require(_currentSupply + amt <= MAX_SUPPLY, "Amount exceeds supply.");
    require(cost(amt) <= msg.value, "ETH sent is below cost.");

    for (uint256 i = 0; i < amt; i++) {
      _safeMint(msg.sender, _currentSupply + i);
    }

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Mints a new token in presale
  /// @param amt The number of tokens to mint
  /// @param proof Merkle proof
  /// @dev Must send COST * amt in ETH
  function preMint(uint256 amt, bytes32[] calldata proof) external payable {
    uint256 _currentSupply = totalSupply();
    require(presaleActive, "Presale is not yet active.");
    require(isWhitelisted(msg.sender, proof), "Address is not whitelisted.");
    require(_currentSupply + amt <= MAX_SUPPLY, "Amount exceeds supply.");
    require(whitelistCost(amt) <= msg.value, "ETH sent is below cost.");
    for (uint256 i = 0; i < amt; i++) {
      _safeMint(msg.sender, _currentSupply + i);
    }

    emit TotalSupplyChanged(totalSupply());
  }
}