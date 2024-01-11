// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./OrderTypes.sol";
import "./IComplication.sol";
import "./SignatureChecker.sol";
import "./IFeeManager.sol";

// external imports
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";

/**
 * @title InfinityExchange

NFTNFTNFT...........................................NFTNFTNFT
NFTNFT                                                 NFTNFT
NFT                                                       NFT
.                                                           .
.                                                           .
.                                                           .
.                                                           .
.               NFTNFTNFT            NFTNFTNFT              .
.            NFTNFTNFTNFTNFT      NFTNFTNFTNFTNFT           .
.           NFTNFTNFTNFTNFTNFT   NFTNFTNFTNFTNFTNFT         .
.         NFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFT        .
.         NFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFT        .
.         NFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFT        .
.          NFTNFTNFTNFTNFTNFTN   NFTNFTNFTNFTNFTNFT         .
.            NFTNFTNFTNFTNFT      NFTNFTNFTNFTNFT           .
.               NFTNFTNFT            NFTNFTNFT              .
.                                                           .
.                                                           .
.                                                           .
.                                                           .
NFT                                                       NFT
NFTNFT                                                 NFTNFT
NFTNFTNFT...........................................NFTNFTNFT 

*/
contract InfinityExchange is ReentrancyGuard, Ownable {
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  EnumerableSet.AddressSet private _currencies;
  EnumerableSet.AddressSet private _complications;

  address public immutable WETH;
  address public MATCH_EXECUTOR;
  bytes32 public immutable DOMAIN_SEPARATOR;
  uint16 public WETH_TRANSFER_GAS_UNITS = 50000;

  mapping(address => uint256) public userMinOrderNonce;
  mapping(address => mapping(uint256 => bool)) public isUserOrderNonceExecutedOrCancelled;

  event CancelAllOrders(address user, uint256 newMinNonce);
  event CancelMultipleOrders(address user, uint256[] orderNonces);
  event CurrencyAdded(address currencyRegistry);
  event ComplicationAdded(address complicationRegistry);
  event CurrencyRemoved(address currencyRegistry);
  event ComplicationRemoved(address complicationRegistry);
  event NewMatchExecutor(address matchExecutor);
  event NewWethTransferGasUnits(uint16 wethTransferGasUnits);

  event MatchOrderFulfilled(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    address seller,
    address buyer,
    address complication, // address of the complication that defines the execution
    address currency, // token address of the transacting currency
    uint256 amount // amount spent on the order
  );

  event TakeOrderFulfilled(
    bytes32 orderHash,
    address seller,
    address buyer,
    address complication, // address of the complication that defines the execution
    address currency, // token address of the transacting currency
    uint256 amount // amount spent on the order
  );

  constructor(
    address _WETH,
    address _matchExecutor
  ) {
    // Calculate the domain separator
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
        keccak256('InfinityExchange'),
        keccak256(bytes('1')), // for versionId = 1
        block.chainid,
        address(this)
      )
    );
    WETH = _WETH;
    MATCH_EXECUTOR = _matchExecutor;
  }

  fallback() external payable {}

  receive() external payable {}

  // =================================================== USER FUNCTIONS =======================================================

  function matchOrders(
    OrderTypes.MakerOrder[] calldata sells,
    OrderTypes.MakerOrder[] calldata buys,
    OrderTypes.OrderItem[][] calldata constructs
  ) external {
    uint256 startGas = gasleft();
    uint256 numSells = sells.length;
    require(msg.sender == MATCH_EXECUTOR, 'only match executor');
    require(numSells == buys.length && numSells == constructs.length, 'mismatched lengths');
    for (uint256 i = 0; i < numSells; ) {
      uint256 startGasPerOrder = gasleft() + ((startGas - gasleft()) / numSells);
      _matchOrders(sells[i], buys[i], constructs[i]);
      // refund gas to match executor
      _refundMatchExecutionGasFeeFromBuyer(startGasPerOrder, buys[i].signer);
      unchecked {
        ++i;
      }
    }
  }

  function matchOneToOneOrders(
    OrderTypes.MakerOrder[] calldata makerOrders1,
    OrderTypes.MakerOrder[] calldata makerOrders2
  ) external {
    uint256 startGas = gasleft();
    uint256 numMakerOrders = makerOrders1.length;
    require(msg.sender == MATCH_EXECUTOR, 'only match executor');
    require(numMakerOrders == makerOrders2.length, 'mismatched lengths');
    for (uint256 i = 0; i < numMakerOrders; ) {
      uint256 startGasPerOrder = gasleft() + ((startGas - gasleft()) / numMakerOrders);
      address complication = makerOrders1[i].execParams[0];
      require(_complications.contains(complication), 'invalid complication');
      // skip invalid orders
      if (IComplication(complication).canExecMatchOneToOne(makerOrders1[i], makerOrders2[i])) {
        bytes32 makerOrderHash = _hash(makerOrders1[i]);
        if (makerOrders1[i].isSellOrder) {
          _matchOneToManyOrders(false, makerOrderHash, makerOrders1[i], makerOrders2[i]);
          isUserOrderNonceExecutedOrCancelled[makerOrders1[i].signer][makerOrders1[i].constraints[6]] = true;
          _refundMatchExecutionGasFeeFromBuyer(startGasPerOrder, makerOrders2[i].signer);
        } else {
          _matchOneToManyOrders(true, makerOrderHash, makerOrders2[i], makerOrders1[i]);
          isUserOrderNonceExecutedOrCancelled[makerOrders1[i].signer][makerOrders1[i].constraints[6]] = true;
          _refundMatchExecutionGasFeeFromBuyer(startGasPerOrder, makerOrders1[i].signer);
        }
      }
      unchecked {
        ++i;
      }
    }
  }

  function matchOneToManyOrders(OrderTypes.MakerOrder calldata makerOrder, OrderTypes.MakerOrder[] calldata manyMakerOrders)
    external
  {
    uint256 startGas = gasleft();
    require(msg.sender == MATCH_EXECUTOR, 'only match executor');
    address complication = makerOrder.execParams[0];
    require(_complications.contains(complication), 'invalid complication');
    require(IComplication(complication).canExecMatchOneToMany(makerOrder, manyMakerOrders), 'cannot execute');
    bytes32 makerOrderHash = _hash(makerOrder);
    if (makerOrder.isSellOrder) {
      uint256 ordersLength = manyMakerOrders.length;
      for (uint256 i = 0; i < ordersLength; ) {
        // 20000 for the SSTORE op that updates maker nonce status
        uint256 startGasPerOrder = gasleft() + ((startGas + 20000 - gasleft()) / ordersLength);
        _matchOneToManyOrders(false, makerOrderHash, makerOrder, manyMakerOrders[i]);
        _refundMatchExecutionGasFeeFromBuyer(startGasPerOrder, manyMakerOrders[i].signer);
        unchecked {
          ++i;
        }
      }
      isUserOrderNonceExecutedOrCancelled[makerOrder.signer][makerOrder.constraints[6]] = true;
    } else {
      uint256 ordersLength = manyMakerOrders.length;
      for (uint256 i = 0; i < ordersLength; ) {
        _matchOneToManyOrders(true, makerOrderHash, manyMakerOrders[i], makerOrder);
        unchecked {
          ++i;
        }
      }
      isUserOrderNonceExecutedOrCancelled[makerOrder.signer][makerOrder.constraints[6]] = true;
      _refundMatchExecutionGasFeeFromBuyer(startGas, makerOrder.signer);
    }
  }

  function takeOrders(OrderTypes.MakerOrder[] calldata makerOrders, OrderTypes.TakerOrder[] calldata takerOrders)
    external
    payable
    nonReentrant
  {
    uint256 ordersLength = makerOrders.length;
    require(ordersLength == takerOrders.length, 'mismatched lengths');
    for (uint256 i = 0; i < ordersLength; ) {
      _takeOrders(makerOrders[i], takerOrders[i]);
      unchecked {
        ++i;
      }
    }
  }

  function takeMultipleOneOrders(OrderTypes.MakerOrder[] calldata makerOrders) external payable nonReentrant {
    uint256 numMakerOrders = makerOrders.length;
    for (uint256 i = 0; i < numMakerOrders; ) {
      bytes32 makerOrderHash = _hash(makerOrders[i]);
      require(isOrderValid(makerOrders[i], makerOrderHash), 'invalid maker order');
      bool isTimeValid = makerOrders[i].constraints[3] <= block.timestamp &&
        makerOrders[i].constraints[4] >= block.timestamp;
      require(isTimeValid, 'invalid time');
      _execTakeOneOrder(makerOrders[i], makerOrderHash);
      unchecked {
        ++i;
      }
    }
  }

  function transferMultipleNFTs(address to, OrderTypes.OrderItem[] calldata items) external nonReentrant {
    _transferMultipleNFTs(msg.sender, to, items);
  }

  /**
   * @notice Cancel all pending orders
   * @param minNonce minimum user nonce
   */
  function cancelAllOrders(uint256 minNonce) external {
    require(minNonce > userMinOrderNonce[msg.sender], 'nonce too low');
    require(minNonce < userMinOrderNonce[msg.sender] + 1000000, 'too many');
    userMinOrderNonce[msg.sender] = minNonce;
    emit CancelAllOrders(msg.sender, minNonce);
  }

  /**
   * @notice Cancel multiple orders
   * @param orderNonces array of order nonces
   */
  function cancelMultipleOrders(uint256[] calldata orderNonces) external {
    uint256 numNonces = orderNonces.length;
    require(numNonces > 0, 'cannot be empty');
    for (uint256 i = 0; i < numNonces; ) {
      require(orderNonces[i] >= userMinOrderNonce[msg.sender], 'nonce too low');
      require(!isUserOrderNonceExecutedOrCancelled[msg.sender][orderNonces[i]], 'nonce already executed or cancelled');
      isUserOrderNonceExecutedOrCancelled[msg.sender][orderNonces[i]] = true;
      unchecked {
        ++i;
      }
    }
    emit CancelMultipleOrders(msg.sender, orderNonces);
  }

  // ====================================================== VIEW FUNCTIONS ======================================================

  /**
   * @notice Check whether user order nonce is executed or cancelled
   * @param user address of user
   * @param nonce nonce of the order
   */
  function isNonceValid(address user, uint256 nonce) external view returns (bool) {
    return !isUserOrderNonceExecutedOrCancelled[user][nonce] && nonce > userMinOrderNonce[user];
  }

  function verifyOrderSig(OrderTypes.MakerOrder calldata order) external view returns (bool) {
    // Verify the validity of the signature
    (bytes32 r, bytes32 s, uint8 v) = abi.decode(order.sig, (bytes32, bytes32, uint8));
    return SignatureChecker.verify(_hash(order), order.signer, r, s, v, DOMAIN_SEPARATOR);
  }

  function verifyMatchOrders(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy,
    OrderTypes.OrderItem[] calldata constructedNfts
  ) public view returns (bool, uint256) {
    bool sidesMatch = sell.isSellOrder && !buy.isSellOrder;
    bool complicationsMatch = sell.execParams[0] == buy.execParams[0];
    bool currenciesMatch = sell.execParams[1] == buy.execParams[1] ||
      (sell.execParams[1] == address(0) && buy.execParams[1] == WETH);
    bool sellOrderValid = isOrderValid(sell, sellOrderHash);
    bool buyOrderValid = isOrderValid(buy, buyOrderHash);
    (bool executionValid, uint256 execPrice) = IComplication(sell.execParams[0]).canExecMatchOrder(
      sell,
      buy,
      constructedNfts
    );

    return (
      sidesMatch && complicationsMatch && currenciesMatch && sellOrderValid && buyOrderValid && executionValid,
      execPrice
    );
  }

  function verifyMatchOneToManyOrders(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy
  ) public view returns (bool) {
    bool sidesMatch = sell.isSellOrder && !buy.isSellOrder;
    bool complicationsMatch = sell.execParams[0] == buy.execParams[0];
    bool currenciesMatch = sell.execParams[1] == buy.execParams[1] ||
      (sell.execParams[1] == address(0) && buy.execParams[1] == WETH);
    bool sellOrderValid = isOrderValid(sell, sellOrderHash);
    bool buyOrderValid = isOrderValid(buy, buyOrderHash);

    return (sidesMatch && complicationsMatch && currenciesMatch && sellOrderValid && buyOrderValid);
  }

  function verifyTakeOrders(
    bytes32 makerOrderHash,
    OrderTypes.MakerOrder calldata maker,
    OrderTypes.TakerOrder calldata taker
  ) public view returns (bool) {
    bool sidesMatch = (maker.isSellOrder && !taker.isSellOrder) || (!maker.isSellOrder && taker.isSellOrder);
    bool makerOrderValid = isOrderValid(maker, makerOrderHash);
    bool executionValid = IComplication(maker.execParams[0]).canExecTakeOrder(maker, taker);
    return (sidesMatch && makerOrderValid && executionValid);
  }

  /**
   * @notice Verifies the validity of the order
   * @param order the order
   * @param orderHash computed hash of the order
   */
  function isOrderValid(OrderTypes.MakerOrder calldata order, bytes32 orderHash) public view returns (bool) {
    return
      _orderValidity(
        order.signer,
        order.sig,
        orderHash,
        order.execParams[0],
        order.execParams[1],
        order.constraints[6]
      );
  }

  function numCurrencies() external view returns (uint256) {
    return _currencies.length();
  }

  function getCurrencyAt(uint256 index) external view returns (address) {
    return _currencies.at(index);
  }

  function isValidCurrency(address currency) external view returns (bool) {
    return _currencies.contains(currency);
  }

  function numComplications() external view returns (uint256) {
    return _complications.length();
  }

  function getComplicationAt(uint256 index) external view returns (address) {
    return _complications.at(index);
  }

  function isValidComplication(address complication) external view returns (bool) {
    return _complications.contains(complication);
  }

  // ====================================================== INTERNAL FUNCTIONS ================================================

  function _matchOrders(
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy,
    OrderTypes.OrderItem[] calldata constructedNfts
  ) internal {
    bytes32 sellOrderHash = _hash(sell);
    bytes32 buyOrderHash = _hash(buy);
    // if this order is not valid, just return and continue with other orders
    (bool orderVerified, uint256 execPrice) = verifyMatchOrders(sellOrderHash, buyOrderHash, sell, buy, constructedNfts);
    if (!orderVerified) {
      return;
    }
    _execMatchOrders(sellOrderHash, buyOrderHash, sell, buy, constructedNfts, execPrice);
  }

  function _matchOneToManyOrders(
    bool isTakerSeller,
    bytes32 makerOrderHash,
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy
  ) internal {
    bytes32 sellOrderHash = isTakerSeller ? _hash(sell) : makerOrderHash;
    bytes32 buyOrderHash = isTakerSeller ? makerOrderHash : _hash(buy);
    // if this order is not valid, just return and continue with other orders
    bool orderVerified = verifyMatchOneToManyOrders(sellOrderHash, buyOrderHash, sell, buy);
    require(orderVerified, 'order not verified');
    _execMatchOneToManyOrders(isTakerSeller, sellOrderHash, buyOrderHash, sell, buy);
  }

  function _takeOrders(OrderTypes.MakerOrder calldata makerOrder, OrderTypes.TakerOrder calldata takerOrder) internal {
    bytes32 makerOrderHash = _hash(makerOrder);
    // if this order is not valid, just return and continue with other orders
    bool orderVerified = verifyTakeOrders(makerOrderHash, makerOrder, takerOrder);
    if (!orderVerified) {
      return;
    }
    // exec order
    _execTakeOrders(makerOrderHash, makerOrder, takerOrder);
  }

  function _orderValidity(
    address signer,
    bytes calldata sig,
    bytes32 orderHash,
    address complication,
    address currency,
    uint256 nonce
  ) internal view returns (bool) {
    bool orderExpired = isUserOrderNonceExecutedOrCancelled[signer][nonce] || nonce < userMinOrderNonce[signer];
    // Verify the validity of the signature
    (bytes32 r, bytes32 s, uint8 v) = abi.decode(sig, (bytes32, bytes32, uint8));
    bool sigValid = SignatureChecker.verify(orderHash, signer, r, s, v, DOMAIN_SEPARATOR);
    if (
      orderExpired ||
      !sigValid ||
      signer == address(0) ||
      !_currencies.contains(currency) ||
      !_complications.contains(complication)
    ) {
      return false;
    }
    return true;
  }

  function _execMatchOrders(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy,
    OrderTypes.OrderItem[] calldata constructedNfts,
    uint256 execPrice
  ) internal {
    // exec order
    _execMatchOrder(
      sellOrderHash,
      buyOrderHash,
      sell.signer,
      buy.signer,
      sell.constraints[6],
      buy.constraints[6],
      sell.constraints[5],
      constructedNfts,
      buy.execParams[0],
      buy.execParams[1],
      execPrice
    );
  }

  function _execMatchOrder(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    address seller,
    address buyer,
    uint256 sellNonce,
    uint256 buyNonce,
    uint256 minBpsToSeller,
    OrderTypes.OrderItem[] calldata constructedNfts,
    address complication,
    address currency,
    uint256 execPrice
  ) internal {
    // Update order execution status to true (prevents replay)
    isUserOrderNonceExecutedOrCancelled[seller][sellNonce] = true;
    isUserOrderNonceExecutedOrCancelled[buyer][buyNonce] = true;
    _transferNFTsAndFees(
      seller,
      buyer,
      constructedNfts,
      execPrice,
      currency,
      minBpsToSeller,
      complication
    );
    _emitEvent(sellOrderHash, buyOrderHash, seller, buyer, complication, currency, execPrice);
  }

  function _execMatchOneToManyOrders(
    bool isTakerSeller,
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy
  ) internal {
    // exec order
    isTakerSeller
      ? isUserOrderNonceExecutedOrCancelled[sell.signer][sell.constraints[6]] = true
      : isUserOrderNonceExecutedOrCancelled[buy.signer][buy.constraints[6]] = true;
    _doExecOneToManyOrders(
      sellOrderHash,
      buyOrderHash,
      sell.signer,
      buy.signer,
      sell.constraints[5],
      isTakerSeller ? sell.nfts : buy.nfts,
      buy.execParams[0],
      buy.execParams[1],
      isTakerSeller ? _getCurrentPrice(sell) : _getCurrentPrice(buy)
    );
  }

  function _doExecOneToManyOrders(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    address seller,
    address buyer,
    uint256 minBpsToSeller,
    OrderTypes.OrderItem[] calldata constructedNfts,
    address complication,
    address currency,
    uint256 execPrice
  ) internal {
    _transferNFTsAndFees(
      seller,
      buyer,
      constructedNfts,
      execPrice,
      currency,
      minBpsToSeller,
      complication
    );
    _emitEvent(sellOrderHash, buyOrderHash, seller, buyer, complication, currency, execPrice);
  }

  function _execTakeOrders(
    bytes32 makerOrderHash,
    OrderTypes.MakerOrder calldata makerOrder,
    OrderTypes.TakerOrder calldata takerOrder
  ) internal {
    isUserOrderNonceExecutedOrCancelled[makerOrder.signer][makerOrder.constraints[6]] = true;
    uint256 execPrice = _getCurrentPrice(makerOrder);
    // exec order
    bool isTakerSell = takerOrder.isSellOrder;
    if (isTakerSell) {
      _transferNFTsAndFees(
        msg.sender,
        makerOrder.signer,
        takerOrder.nfts,
        execPrice,
        makerOrder.execParams[1],
        makerOrder.constraints[5],
        makerOrder.execParams[0]
      );
      _emitTakerEvent(makerOrderHash, msg.sender, makerOrder.signer, makerOrder, execPrice);
    } else {
      _transferNFTsAndFees(
        makerOrder.signer,
        msg.sender,
        takerOrder.nfts,
        execPrice,
        makerOrder.execParams[1],
        makerOrder.constraints[5],
        makerOrder.execParams[0]
      );
      _emitTakerEvent(makerOrderHash, makerOrder.signer, msg.sender, makerOrder, execPrice);
    }
  }

  function _execTakeOneOrder(OrderTypes.MakerOrder calldata makerOrder, bytes32 makerOrderHash) internal {
    // record nonce
    isUserOrderNonceExecutedOrCancelled[makerOrder.signer][makerOrder.constraints[6]] = true;
    uint256 execPrice = _getCurrentPrice(makerOrder);
    if (makerOrder.isSellOrder) {
      _transferNFTsAndFees(
        makerOrder.signer,
        msg.sender,
        makerOrder.nfts,
        execPrice,
        makerOrder.execParams[1],
        makerOrder.constraints[5],
        makerOrder.execParams[0]
      );
      _emitTakerEvent(makerOrderHash, makerOrder.signer, msg.sender, makerOrder, execPrice);
    } else {
      _transferNFTsAndFees(
        msg.sender,
        makerOrder.signer,
        makerOrder.nfts,
        execPrice,
        makerOrder.execParams[1],
        makerOrder.constraints[5],
        makerOrder.execParams[0]
      );
      _emitTakerEvent(makerOrderHash, msg.sender, makerOrder.signer, makerOrder, execPrice);
    }
  }

  function _emitEvent(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    address seller,
    address buyer,
    address complication,
    address currency,
    uint256 amount
  ) internal {
    emit MatchOrderFulfilled(
      sellOrderHash,
      buyOrderHash,
      seller,
      buyer,
      complication,
      currency,
      amount
    );
  }

  function _emitTakerEvent(
    bytes32 orderHash,
    address seller,
    address buyer,
    OrderTypes.MakerOrder calldata order,
    uint256 amount
  ) internal {
    emit TakeOrderFulfilled(orderHash, seller, buyer, order.execParams[0], order.execParams[1], amount);
  }

  function _transferNFTsAndFees(
    address seller,
    address buyer,
    OrderTypes.OrderItem[] calldata nfts,
    uint256 amount,
    address currency,
    uint256 minBpsToSeller,
    address complication
  ) internal {
    // transfer NFTs
    _transferMultipleNFTs(seller, buyer, nfts);
    // transfer fees
    _transferFees(seller, buyer, amount, currency, minBpsToSeller, complication);
  }

  function _transferMultipleNFTs(
    address from,
    address to,
    OrderTypes.OrderItem[] calldata nfts
  ) internal {
    uint256 numNfts = nfts.length;
    for (uint256 i = 0; i < numNfts; ) {
      _transferNFTs(from, to, nfts[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Transfer NFT
   * @param from address of the sender
   * @param to address of the recipient
   * @param item item to transfer
   */
  function _transferNFTs(
    address from,
    address to,
    OrderTypes.OrderItem calldata item
  ) internal {
    if (IERC165(item.collection).supportsInterface(0x80ac58cd)) {
      _transferERC721s(from, to, item);
    } else if (IERC165(item.collection).supportsInterface(0xd9b67a26)) {
      _transferERC1155s(from, to, item);
    }
  }

  function _transferERC721s(
    address from,
    address to,
    OrderTypes.OrderItem calldata item
  ) internal {
    uint256 numTokens = item.tokens.length;
    for (uint256 i = 0; i < numTokens; ) {
      IERC721(item.collection).safeTransferFrom(from, to, item.tokens[i].tokenId);
      unchecked {
        ++i;
      }
    }
  }

  function _transferERC1155s(
    address from,
    address to,
    OrderTypes.OrderItem calldata item
  ) internal {
    uint256 numNfts = item.tokens.length;
    uint256[] memory tokenIdsArr = new uint256[](numNfts);
    uint256[] memory numTokensPerTokenIdArr = new uint256[](numNfts);
    for (uint256 i = 0; i < numNfts; ) {
      tokenIdsArr[i] = item.tokens[i].tokenId;
      numTokensPerTokenIdArr[i] = item.tokens[i].numTokens;
      unchecked {
        ++i;
      }
    }
    IERC1155(item.collection).safeBatchTransferFrom(from, to, tokenIdsArr, numTokensPerTokenIdArr, '0x0');
  }

  function _transferFees(
    address seller,
    address buyer,
    uint256 amount,
    address currency,
    uint256 minBpsToSeller,
    address complication
  ) internal {
    // protocol fee
    uint256 fees = _sendFeesToProtocol(complication, buyer, amount, currency);
    // check min bps to seller is met
    uint256 remainingAmount = amount - fees;
    require((remainingAmount * 10000) >= (minBpsToSeller * amount), 'Fees: Higher than expected');
    // ETH
    if (currency == address(0)) {
      require(msg.value >= amount, 'insufficient amount sent');
      // transfer amount to seller
      (bool sent, ) = seller.call{value: remainingAmount}('');
      require(sent, 'failed to send ether to seller');
    } else {
      // transfer final amount (post-fees) to seller
      IERC20(currency).safeTransferFrom(buyer, seller, remainingAmount);
    }
  }

  function _sendFeesToProtocol(
    address complication,
    address buyer,
    uint256 amount,
    address currency
  ) internal returns (uint256) {
    uint256 protocolFeeBps = IComplication(complication).getProtocolFee();
    uint256 protocolFee = (protocolFeeBps * amount) / 10000;
    if (currency != address(0)) {
      IERC20(currency).safeTransferFrom(buyer, address(this), protocolFee);
    }
    return protocolFee;
  }

  function _refundMatchExecutionGasFeeFromBuyer(uint256 startGas, address buyer) internal {
    uint256 gasCost = (startGas - gasleft() + WETH_TRANSFER_GAS_UNITS) * tx.gasprice;
    IERC20(WETH).safeTransferFrom(buyer, MATCH_EXECUTOR, gasCost);
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

  function _hash(OrderTypes.MakerOrder calldata order) internal pure returns (bytes32) {
    // keccak256('Order(bool isSellOrder,address signer,uint256[] constraints,OrderItem[] nfts,address[] execParams,bytes extraParams)OrderItem(address collection,TokenInfo[] tokens)TokenInfo(uint256 tokenId,uint256 numTokens)')
    bytes32 ORDER_HASH = 0x7bcfb5a29031e6b8d34ca1a14dd0a1f5cb11b20f755bb2a31ee3c4b143477e4a;
    bytes32 orderHash = keccak256(
      abi.encode(
        ORDER_HASH,
        order.isSellOrder,
        order.signer,
        keccak256(abi.encodePacked(order.constraints)),
        _nftsHash(order.nfts),
        keccak256(abi.encodePacked(order.execParams)),
        keccak256(order.extraParams)
      )
    );
    return orderHash;
  }

  function _nftsHash(OrderTypes.OrderItem[] calldata nfts) internal pure returns (bytes32) {
    // keccak256('OrderItem(address collection,TokenInfo[] tokens)TokenInfo(uint256 tokenId,uint256 numTokens)')
    bytes32 ORDER_ITEM_HASH = 0xf73f37e9f570369ceaab59cef16249ae1c0ad1afd592d656afac0be6f63b87e0;
    uint256 numNfts = nfts.length;
    bytes32[] memory hashes = new bytes32[](numNfts);
    for (uint256 i = 0; i < numNfts; ) {
      bytes32 hash = keccak256(abi.encode(ORDER_ITEM_HASH, nfts[i].collection, _tokensHash(nfts[i].tokens)));
      hashes[i] = hash;
      unchecked {
        ++i;
      }
    }
    bytes32 nftsHash = keccak256(abi.encodePacked(hashes));
    return nftsHash;
  }

  function _tokensHash(OrderTypes.TokenInfo[] calldata tokens) internal pure returns (bytes32) {
    // keccak256('TokenInfo(uint256 tokenId,uint256 numTokens)')
    bytes32 TOKEN_INFO_HASH = 0x88f0bd19d14f8b5d22c0605a15d9fffc285ebc8c86fb21139456d305982906f1;
    uint256 numTokens = tokens.length;
    bytes32[] memory hashes = new bytes32[](numTokens);
    for (uint256 i = 0; i < numTokens; ) {
      bytes32 hash = keccak256(abi.encode(TOKEN_INFO_HASH, tokens[i].tokenId, tokens[i].numTokens));
      hashes[i] = hash;
      unchecked {
        ++i;
      }
    }
    bytes32 tokensHash = keccak256(abi.encodePacked(hashes));
    return tokensHash;
  }

  // ====================================================== ADMIN FUNCTIONS ======================================================

  function rescueTokens(
    address destination,
    address currency,
    uint256 amount
  ) external onlyOwner {
    IERC20(currency).safeTransfer(destination, amount);
  }

  function rescueETH(address destination) external payable onlyOwner {
    (bool sent, ) = destination.call{value: msg.value}('');
    require(sent, 'failed');
  }

  function addCurrency(address _currency) external onlyOwner {
    _currencies.add(_currency);
    emit CurrencyAdded(_currency);
  }

  function addComplication(address _complication) external onlyOwner {
    _complications.add(_complication);
    emit ComplicationAdded(_complication);
  }

  function removeCurrency(address _currency) external onlyOwner {
    _currencies.remove(_currency);
    emit CurrencyRemoved(_currency);
  }

  function removeComplication(address _complication) external onlyOwner {
    _complications.remove(_complication);
    emit ComplicationRemoved(_complication);
  }

  function updateMatchExecutor(address _matchExecutor) external onlyOwner {
    MATCH_EXECUTOR = _matchExecutor;
    emit NewMatchExecutor(_matchExecutor);
  }

  function updateWethTranferGas(uint16 _wethTransferGasUnits) external onlyOwner {
    WETH_TRANSFER_GAS_UNITS = _wethTransferGasUnits;
    emit NewWethTransferGasUnits(_wethTransferGasUnits);
  }
}
