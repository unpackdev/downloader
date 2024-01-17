// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";

error SaleEnded();
error QuantityBelowMinimum();
error InvalidEtherValue();
error NotSupported();
error InvalidProof();
error ExceedsAllocation();

contract SmashversePresale is Ownable, Pausable, PaymentSplitter {
  uint256 public immutable unitPrice;
  bytes32 public whitelistMerkleRoot;
  bool public ended;
  mapping(address => uint256) public quantityPurchased;

  event Sale(address indexed buyer, uint256 amount, uint256 quantity);
  event PresaleEnded();

  constructor(
    address[] memory payees_,
    uint256[] memory shares_,
    uint256 unitPrice_,
    bytes32 whitelistMerkleRoot_
  ) PaymentSplitter(payees_, shares_) {
    unitPrice = unitPrice_;
    whitelistMerkleRoot = whitelistMerkleRoot_;
  }

  modifier whenSaleRunning() {
    if (hasSaleEnded()) revert SaleEnded();
    _;
  }

  function hasSaleEnded() public view returns (bool) {
    return ended;
  }

  function isSaleRunning() public view returns (bool) {
    return !hasSaleEnded();
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function endSale() external onlyOwner {
    if (hasSaleEnded()) revert SaleEnded();
    ended = true;
    emit PresaleEnded();
  }

  function buy(
    uint256 quantity_,
    uint256 proofQuantity_,
    bytes32[] calldata proof_
  ) external payable whenSaleRunning whenNotPaused {
    if (quantity_ == 0) revert QuantityBelowMinimum();

    uint256 expectedAmount = quantity_ * unitPrice;

    if (msg.value != expectedAmount) revert InvalidEtherValue();

    // confirm the total quantity they're entitled to
    if (!verifyWhitelistProof(proof_, msg.sender, proofQuantity_))
      revert InvalidProof();

    // check that the amount being purchased won't push the address over their allocation
    if (quantityPurchased[msg.sender] + quantity_ > proofQuantity_)
      revert ExceedsAllocation();

    quantityPurchased[msg.sender] += quantity_;

    emit Sale(msg.sender, msg.value, quantity_);
  }

  function setWhitelistMerkleRoot(bytes32 whitelistMerkleRoot_)
    external
    onlyOwner
  {
    whitelistMerkleRoot = whitelistMerkleRoot_;
  }

  function verifyWhitelistProof(
    bytes32[] calldata proof_,
    address account_,
    uint256 quantity_
  ) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(account_, quantity_));
    return MerkleProof.verify(proof_, whitelistMerkleRoot, leaf);
  }

  // reverts if receiving any eth directly
  receive() external payable override {
    revert NotSupported();
  }

  // fallback function
  fallback() external payable {
    revert NotSupported();
  }
}
