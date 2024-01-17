// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./IERC20Upgradeable.sol";

interface IDelegate {
  struct ERC1155Pair {
    IERC1155 token;
    uint256 tokenId;
    uint256 amount;
  }

  struct ERC721Pair {
    IERC721 token;
    uint256 tokenId;
  }

  function delegateType() external view returns (uint256);

  function executeSell(
    address seller,
    address buyer,
    bytes calldata data
  ) external returns (bool);

  function executeBuy(
    address seller,
    address buyer,
    bytes calldata data
  ) external returns (bool);

  function executeBid(
    address seller,
    address previousBidder,
    address bidder,
    bytes calldata data
  ) external returns (bool);

  function executeAuctionComplete(
    address seller,
    address buyer,
    bytes calldata data
  ) external returns (bool);

  function executeAuctionRefund(
    address seller,
    address lastBidder,
    bytes calldata data
  ) external returns (bool);
}

library Market {
  uint256 constant INTENT_SELL = 1;
  uint256 constant INTENT_AUCTION = 2;
  uint256 constant INTENT_BUY = 3;

  uint8 constant SIGN_V1 = 1;
  uint8 constant SIGN_V3 = 3;

  struct OrderItem {
    uint256 price;
    bytes data;
  }

  struct Order {
    uint256 salt;
    address user;
    uint256 network;
    uint256 intent;
    uint256 delegateType;
    uint256 deadline;
    IERC20Upgradeable currency;
    bytes dataMask;
    OrderItem[] items;
    // signature
    bytes32 r;
    bytes32 s;
    uint8 v;
    uint8 signVersion;
  }

  struct Fee {
    uint256 percentage;
    address to;
  }

  struct SettleDetail {
    Market.Op op;
    uint256 orderIdx;
    uint256 itemIdx;
    uint256 price;
    bytes32 itemHash;
    IDelegate executionDelegate;
    bytes dataReplacement;
    uint256 bidIncentivePct;
    uint256 aucMinIncrementPct;
    uint256 aucIncDurationSecs;
    Fee[] fees;
  }

  struct SettleShared {
    uint256 salt;
    uint256 deadline;
    uint256 amountToEth;
    uint256 amountToWeth;
    address user;
    bool canFail;
  }

  struct RunInput {
    Order[] orders;
    SettleDetail[] details;
    SettleShared shared;
    // signature
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  struct OngoingAuction {
    uint256 price;
    uint256 netPrice;
    uint256 endAt;
    address bidder;
  }

  enum InvStatus {
    NEW,
    AUCTION,
    COMPLETE,
    CANCELLED,
    REFUNDED
  }

  enum Op {
    INVALID,
    // off-chain
    COMPLETE_SELL_OFFER, // buyer takes order
    COMPLETE_BUY_OFFER, // seller takes offer
    CANCEL_OFFER,
    // auction
    BID,
    COMPLETE_AUCTION,
    REFUND_AUCTION,
    REFUND_AUCTION_STUCK_ITEM
  }

  enum DelegationType {
    INVALID,
    ERC721,
    ERC1155
  }
}

interface IX2Y2Exchange {
  function run1(
    Market.Order memory order,
    Market.SettleShared memory shared,
    Market.SettleDetail memory detail
  ) external returns (uint256);

  function run(Market.RunInput memory input) external payable;
}

interface IX2Y2Adapter {
  /**
   *  @dev seller makes order, buyer takes order with eth.
   *  @param input usually, RunInput only has one SettleDetail in array.
   *  @param buyer buyer
   */
  function runForEth(Market.RunInput memory input, address buyer)
    external
    payable;
}
