// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./ECDSA.sol";

error InvalidPurchaseRequest();
error OfferExpired();
error OfferAtCapacity();
error InsufficientBalance();

contract FleshShop {
  using ECDSA for bytes32;

  address private receivable;
  address private verifier;
  IERC20 private flesh;
  mapping(uint256 => uint256) private purchases;

  event OfferPurchased(uint256 indexed offerId, address indexed account, uint256 key, uint256 cost);

  constructor(address _receivable, address _verifier, address _flesh) {
    receivable = _receivable;
    verifier = _verifier;
    flesh = IERC20(_flesh);
  }

  /**
   * Purchase offer.
   */
  function purchase(uint256 _id, uint256 _key, uint256 _cost, uint256 _spots, uint256 _expires, bytes memory _signature) external {
    if (!validate(_id, _key, _cost, _spots, _expires, _signature)) revert InvalidPurchaseRequest();
    if (block.timestamp > _expires)                                revert OfferExpired();
    if (purchases[_id] >= _spots)                                  revert OfferAtCapacity();
    if (flesh.balanceOf(msg.sender) < _cost)                       revert InsufficientBalance();

    emit OfferPurchased(_id, msg.sender, _key, _cost);

    purchases[_id]++;
    flesh.transferFrom(msg.sender, receivable, _cost);
  }

  /**
   * Accessor to purchases.
   */
  function getPurchases(uint256[] calldata _ids) external view returns (uint256[] memory _purchases) {
    _purchases = new uint256[](_ids.length);
    for (uint256 i; i < _ids.length; i++) {
      _purchases[i] = purchases[_ids[i]];
    }
  }

  /**
   * Hash claim parameters to validate claim request.
   */
  function getParams(uint256 _id, uint256 _key, uint256 _cost, uint256 _spots, uint256 _expires) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_id, _key, _cost, _spots, _expires));
  }

  /**
   * Validate offer parameters.
   */
  function validate(uint256 _id, uint256 _key, uint256 _cost, uint256 _spots, uint256 _expires, bytes memory _signature) private view returns (bool) {
    return ECDSA.recover(
      getParams(_id, _key, _cost, _spots, _expires).toEthSignedMessageHash(),
      _signature
    ) == verifier;
  }
}
