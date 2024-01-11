// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./OrderTypes.sol";
import "./IComplication.sol";
import "./Ownable.sol";

/**
 * @title InfinityOrderBookComplication
 * @notice Complication to execute orderbook orders
 */
contract InfinityOrderBookComplication is IComplication, Ownable {
  uint256 public PROTOCOL_FEE;

  event NewProtocolFee(uint256 protocolFee);
  event NewErrorbound(uint256 errorBound);

  /**
   * @notice Constructor
   * @param _protocolFee protocol fee (200 --> 2%, 400 --> 4%)
   */
  constructor(uint256 _protocolFee) {
    PROTOCOL_FEE = _protocolFee;
  }

  // ======================================================= EXTERNAL FUNCTIONS ==================================================

  function canExecMatchOrder(
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy,
    OrderTypes.OrderItem[] calldata constructedNfts
  ) external view override returns (bool, uint256) {
    (bool _isPriceValid, uint256 execPrice) = isPriceValid(sell, buy);
    return (
      isTimeValid(sell, buy) &&
        _isPriceValid &&
        areNumItemsValid(sell, buy, constructedNfts) &&
        doItemsIntersect(sell.nfts, constructedNfts) &&
        doItemsIntersect(buy.nfts, constructedNfts) &&
        doItemsIntersect(sell.nfts, buy.nfts),
      execPrice
    );
  }

  function canExecMatchOneToMany(
    OrderTypes.MakerOrder calldata makerOrder,
    OrderTypes.MakerOrder[] calldata manyMakerOrders
  ) external view override returns (bool) {
    uint256 numItems;
    bool isOrdersTimeValid = true;
    bool itemsIntersect = true;
    uint256 ordersLength = manyMakerOrders.length;
    for (uint256 i = 0; i < ordersLength; ) {
      if (!isOrdersTimeValid || !itemsIntersect) {
        return false; // short circuit
      }

      uint256 nftsLength = manyMakerOrders[i].nfts.length;
      for (uint256 j = 0; j < nftsLength; ) {
        numItems += manyMakerOrders[i].nfts[j].tokens.length;
        unchecked {
          ++j;
        }
      }

      isOrdersTimeValid =
        isOrdersTimeValid &&
        manyMakerOrders[i].constraints[3] <= block.timestamp &&
        manyMakerOrders[i].constraints[4] >= block.timestamp;

      itemsIntersect = itemsIntersect && doItemsIntersect(makerOrder.nfts, manyMakerOrders[i].nfts);

      unchecked {
        ++i;
      }
    }

    bool _isTimeValid = isOrdersTimeValid &&
      makerOrder.constraints[3] <= block.timestamp &&
      makerOrder.constraints[4] >= block.timestamp;

    uint256 currentMakerOrderPrice = _getCurrentPrice(makerOrder);
    uint256 sumCurrentOrderPrices = _sumCurrentPrices(manyMakerOrders);

    bool _isPriceValid = false;
    if (makerOrder.isSellOrder) {
      _isPriceValid = sumCurrentOrderPrices >= currentMakerOrderPrice;
    } else {
      _isPriceValid = sumCurrentOrderPrices <= currentMakerOrderPrice;
    }

    return (numItems == makerOrder.constraints[0]) && _isTimeValid && itemsIntersect && _isPriceValid;
  }

  function canExecMatchOneToOne(OrderTypes.MakerOrder calldata makerOrder1, OrderTypes.MakerOrder calldata makerOrder2)
    external
    view
    override
    returns (bool)
  {
    bool numItemsValid = makerOrder2.constraints[0] == makerOrder1.constraints[0] &&
      makerOrder2.constraints[0] == 1 &&
      makerOrder2.nfts.length == 1 &&
      makerOrder2.nfts[0].tokens.length == 1 &&
      makerOrder1.nfts.length == 1 &&
      makerOrder1.nfts[0].tokens.length == 1;
    bool _isTimeValid = makerOrder2.constraints[3] <= block.timestamp &&
      makerOrder2.constraints[4] >= block.timestamp &&
      makerOrder1.constraints[3] <= block.timestamp &&
      makerOrder1.constraints[4] >= block.timestamp;
    bool _isPriceValid = false;
    if (makerOrder1.isSellOrder) {
      _isPriceValid = _getCurrentPrice(makerOrder2) >= _getCurrentPrice(makerOrder1);
    } else {
      _isPriceValid = _getCurrentPrice(makerOrder2) <= _getCurrentPrice(makerOrder1);
    }
    return numItemsValid && _isTimeValid && doItemsIntersect(makerOrder1.nfts, makerOrder2.nfts) && _isPriceValid;
  }

  function canExecTakeOrder(OrderTypes.MakerOrder calldata makerOrder, OrderTypes.TakerOrder calldata takerOrder)
    external
    view
    override
    returns (bool)
  {
    return (makerOrder.constraints[3] <= block.timestamp &&
      makerOrder.constraints[4] >= block.timestamp &&
      areTakerNumItemsValid(makerOrder, takerOrder) &&
      doItemsIntersect(makerOrder.nfts, takerOrder.nfts));
  }

  // ======================================================= PUBLIC FUNCTIONS ==================================================

  function isTimeValid(OrderTypes.MakerOrder calldata sell, OrderTypes.MakerOrder calldata buy)
    public
    view
    returns (bool)
  {
    return
      sell.constraints[3] <= block.timestamp &&
      sell.constraints[4] >= block.timestamp &&
      buy.constraints[3] <= block.timestamp &&
      buy.constraints[4] >= block.timestamp;
  }

  function isPriceValid(OrderTypes.MakerOrder calldata sell, OrderTypes.MakerOrder calldata buy)
    public
    view
    returns (bool, uint256)
  {
    (uint256 currentSellPrice, uint256 currentBuyPrice) = (_getCurrentPrice(sell), _getCurrentPrice(buy));
    return (currentBuyPrice >= currentSellPrice, currentBuyPrice);
  }

  function areNumItemsValid(
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy,
    OrderTypes.OrderItem[] calldata constructedNfts
  ) public pure returns (bool) {
    uint256 numConstructedItems = 0;
    uint256 nftsLength = constructedNfts.length;
    for (uint256 i = 0; i < nftsLength; ) {
      unchecked {
        numConstructedItems += constructedNfts[i].tokens.length;
        ++i;
      }
    }
    return numConstructedItems >= buy.constraints[0] && buy.constraints[0] <= sell.constraints[0];
  }

  function areTakerNumItemsValid(OrderTypes.MakerOrder calldata makerOrder, OrderTypes.TakerOrder calldata takerOrder)
    public
    pure
    returns (bool)
  {
    uint256 numTakerItems = 0;
    uint256 nftsLength = takerOrder.nfts.length;
    for (uint256 i = 0; i < nftsLength; ) {
      unchecked {
        numTakerItems += takerOrder.nfts[i].tokens.length;
        ++i;
      }
    }
    return makerOrder.constraints[0] == numTakerItems;
  }

  function doItemsIntersect(OrderTypes.OrderItem[] calldata order1Nfts, OrderTypes.OrderItem[] calldata order2Nfts)
    public
    pure
    returns (bool)
  {
    uint256 order1NftsLength = order1Nfts.length;
    uint256 order2NftsLength = order2Nfts.length;
    // case where maker/taker didn't specify any items
    if (order1NftsLength == 0 || order2NftsLength == 0) {
      return true;
    }

    uint256 numCollsMatched = 0;
    // check if taker has all items in maker
    for (uint256 i = 0; i < order2NftsLength; ) {
      for (uint256 j = 0; j < order1NftsLength; ) {
        if (order1Nfts[j].collection == order2Nfts[i].collection) {
          // increment numCollsMatched
          unchecked {
            ++numCollsMatched;
          }
          // check if tokenIds intersect
          bool tokenIdsIntersect = doTokenIdsIntersect(order1Nfts[j], order2Nfts[i]);
          require(tokenIdsIntersect, 'tokenIds dont intersect');
          // short circuit
          break;
        }
        unchecked {
          ++j;
        }
      }
      unchecked {
        ++i;
      }
    }

    return numCollsMatched == order2NftsLength;
  }

  function doTokenIdsIntersect(OrderTypes.OrderItem calldata item1, OrderTypes.OrderItem calldata item2)
    public
    pure
    returns (bool)
  {
    uint256 item1TokensLength = item1.tokens.length;
    uint256 item2TokensLength = item2.tokens.length;
    // case where maker/taker didn't specify any tokenIds for this collection
    if (item1TokensLength == 0 || item2TokensLength == 0) {
      return true;
    }
    uint256 numTokenIdsPerCollMatched = 0;
    for (uint256 k = 0; k < item2TokensLength; ) {
      for (uint256 l = 0; l < item1TokensLength; ) {
        if (
          item1.tokens[l].tokenId == item2.tokens[k].tokenId && item1.tokens[l].numTokens == item2.tokens[k].numTokens
        ) {
          // increment numTokenIdsPerCollMatched
          unchecked {
            ++numTokenIdsPerCollMatched;
          }
          // short circuit
          break;
        }
        unchecked {
          ++l;
        }
      }
      unchecked {
        ++k;
      }
    }

    return numTokenIdsPerCollMatched == item2TokensLength;
  }

  /**
   * @notice Return protocol fee for this complication
   * @return protocol fee
   */
  function getProtocolFee() external view override returns (uint256) {
    return PROTOCOL_FEE;
  }

  // ============================================== INTERNAL FUNCTIONS ===================================================

  function _sumCurrentPrices(OrderTypes.MakerOrder[] calldata orders) internal view returns (uint256) {
    uint256 sum = 0;
    uint256 ordersLength = orders.length;
    for (uint256 i = 0; i < ordersLength; ) {
      sum += _getCurrentPrice(orders[i]);
      unchecked {
        ++i;
      }
    }
    return sum;
  }

  function _getCurrentPrice(OrderTypes.MakerOrder calldata order) internal view returns (uint256) {
    (uint256 startPrice, uint256 endPrice) = (order.constraints[1], order.constraints[2]);
    uint256 duration = order.constraints[4] - order.constraints[3];
    uint256 priceDiff = startPrice > endPrice ? startPrice - endPrice : endPrice - startPrice;
    if (priceDiff == 0 || duration == 0) {
      return startPrice;
    }
    uint256 elapsedTime = block.timestamp - order.constraints[3];
    uint256 PRECISION = 10**4; // precision for division; similar to bps
    uint256 portionBps = elapsedTime > duration ? PRECISION : ((elapsedTime * PRECISION) / duration);
    priceDiff = (priceDiff * portionBps) / PRECISION;
    return startPrice > endPrice ? startPrice - priceDiff : startPrice + priceDiff;
  }

  // ====================================== ADMIN FUNCTIONS ======================================

  function setProtocolFee(uint256 _protocolFee) external onlyOwner {
    PROTOCOL_FEE = _protocolFee;
    emit NewProtocolFee(_protocolFee);
  }
}
