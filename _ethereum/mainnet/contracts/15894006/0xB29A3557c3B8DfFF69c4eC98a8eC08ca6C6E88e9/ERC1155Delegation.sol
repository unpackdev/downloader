// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./AccessControl.sol";
import "./MarketConsts.sol";
import "./IDelegate.sol";

contract ERC1155Delegate is IDelegate, AccessControl, IERC1155Receiver {
  bytes32 public constant DELEGATION_CALLER = keccak256("DELEGATION_CALLER");

  struct Pair {
    IERC1155 token;
    uint256 tokenId;
    uint256 amount;
  }

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function onERC1155Received(
    address, // operator,
    address, // from,
    uint256, // id,
    uint256, // value,
    bytes calldata // data
  ) external override returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address, // operator,
    address, // from,
    uint256[] calldata, // ids,
    uint256[] calldata, // values,
    bytes calldata // data
  ) external override returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  function decode(bytes calldata data) internal pure returns (Pair[] memory) {
    return abi.decode(data, (Pair[]));
  }

  function delegateType() external view returns (uint256) {
    // return uint256(Market.DelegationType.ERC1155);
    return 2;
  }

  function executeSell(
    address seller,
    address buyer,
    bytes calldata data
  ) external onlyRole(DELEGATION_CALLER) returns (bool) {
    Pair[] memory pairs = decode(data);
    for (uint256 i = 0; i < pairs.length; i++) {
      Pair memory p = pairs[i];
      _assertAmount(p);
      p.token.safeTransferFrom(seller, buyer, p.tokenId, p.amount, "");
    }
    return true;
  }

  function executeBuy(
    address seller,
    address buyer,
    bytes calldata data
  ) external onlyRole(DELEGATION_CALLER) returns (bool) {
    Pair[] memory pairs = decode(data);
    for (uint256 i = 0; i < pairs.length; i++) {
      Pair memory p = pairs[i];
      _assertAmount(p);
      p.token.safeTransferFrom(seller, buyer, p.tokenId, p.amount, "");
    }
    return true;
  }

  function executeBid(
    address seller,
    address previousBidder,
    address, // bidder,
    bytes calldata data
  ) external onlyRole(DELEGATION_CALLER) returns (bool) {
    if (previousBidder == address(0)) {
      Pair[] memory pairs = decode(data);
      for (uint256 i = 0; i < pairs.length; i++) {
        Pair memory p = pairs[i];
        _assertAmount(p);
        p.token.safeTransferFrom(
          seller,
          address(this),
          p.tokenId,
          p.amount,
          ""
        );
      }
    }
    return true;
  }

  function executeAuctionComplete(
    address, // seller,
    address buyer,
    bytes calldata data
  ) external onlyRole(DELEGATION_CALLER) returns (bool) {
    Pair[] memory pairs = decode(data);
    for (uint256 i = 0; i < pairs.length; i++) {
      Pair memory p = pairs[i];
      _assertAmount(p);
      p.token.safeTransferFrom(address(this), buyer, p.tokenId, p.amount, "");
    }
    return true;
  }

  function executeAuctionRefund(
    address seller,
    address, // lastBidder,
    bytes calldata data
  ) external onlyRole(DELEGATION_CALLER) returns (bool) {
    Pair[] memory pairs = decode(data);
    for (uint256 i = 0; i < pairs.length; i++) {
      Pair memory p = pairs[i];
      _assertAmount(p);
      p.token.safeTransferFrom(address(this), seller, p.tokenId, p.amount, "");
    }
    return true;
  }

  function transferBatch(Pair[] memory pairs, address to) public {
    for (uint256 i = 0; i < pairs.length; i++) {
      Pair memory p = pairs[i];
      _assertAmount(p);
      p.token.safeTransferFrom(msg.sender, to, p.tokenId, p.amount, "");
    }
  }

  function _assertAmount(Pair memory p) internal {
    require(p.amount > 0, "Delegate: amount > 0");
  }
}
