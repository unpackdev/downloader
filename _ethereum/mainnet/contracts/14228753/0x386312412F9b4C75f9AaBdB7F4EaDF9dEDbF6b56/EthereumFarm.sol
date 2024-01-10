// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// Everdragons2 website: https://everdragons2.com

import "./Ownable.sol";
import "./ECDSA.sol";

import "./console.sol";

// A contract to allow people to buy on Ethereum and receive tokens on Polygon
contract EthereumFarm is Ownable {
  using ECDSA for bytes32;

  event ValidatorSet(address validator);
  event CrossChainPurchase(uint16 nonce);

  uint256 public proceedsBalance;

  address public validator;
  bool public saleEnded;

  struct Purchase {
    address buyer;
    uint8 quantity;
  }

  mapping(uint16 => Purchase) public purchasedTokens;

  constructor(address _validator) {
    setValidator(_validator);
  }

  function setValidator(address validator_) public onlyOwner {
    require(validator_ != address(0), "validator cannot be 0x0");
    validator = validator_;
    emit ValidatorSet(validator);
  }

  function endSale() external onlyOwner {
    saleEnded = true;
  }

  function buyTokenCrossChain(
    uint8 quantity,
    uint16 nonce_,
    uint256 cost,
    bytes memory signature
  ) external payable {
    require(quantity > 0, "Wrong quantity");
    require(!saleEnded, "Sale ended");
    require(purchasedTokens[nonce_].quantity == 0, "Nonce already used");
    require(_isSignedByValidator(encodeForSignature(_msgSender(), quantity, nonce_, cost), signature), "invalid signature");
    require(msg.value >= cost, "Insufficient payment");
    proceedsBalance += msg.value;
    purchasedTokens[nonce_] = Purchase(_msgSender(), quantity);
    emit CrossChainPurchase(nonce_);
  }

  function _isSignedByValidator(bytes32 _hash, bytes memory _signature) private view returns (bool) {
    return validator != address(0) && validator == _hash.recover(_signature);
  }

  function encodeForSignature(
    address to,
    uint8 quantity,
    uint16 nonce_,
    uint256 cost
  ) public pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          "\x19\x01", // EIP-191
          to,
          quantity,
          nonce_,
          cost
        )
      );
  }

  function withdrawProceeds(address beneficiary, uint256 amount) public onlyOwner {
    if (amount == 0) {
      amount = proceedsBalance;
    }
    require(amount <= proceedsBalance, "Insufficient funds");
    proceedsBalance -= amount;
    (bool success, ) = beneficiary.call{value: amount}("");
    require(success);
  }
}
