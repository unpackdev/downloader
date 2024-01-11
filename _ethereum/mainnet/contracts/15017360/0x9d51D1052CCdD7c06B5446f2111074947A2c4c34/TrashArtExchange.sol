// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./ERC165Checker.sol";
import "./ArrayUtils.sol";
import "./IAtomicMatchHandler.sol";
import "./IHasSecondarySaleFees.sol";

contract TrashArtExchange is ReentrancyGuard, Ownable {
  using SafeERC20 for IERC20;
  using ERC165Checker for address;

  /*
   * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
   * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
   *
   * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
   */
  bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

  /* Cancelled / finalized orders, by hash. */
  mapping(bytes32 => bool) public cancelledOrFinalized;

  /* Orders verified by on-chain approval (alternative to ECDSA signatures so that smart contracts can place orders directly). */
  mapping(bytes32 => bool) public approvedOrders;

  /** referrers */
  mapping(address => address) public referrers; // user address => referrer address
  mapping(address => uint256) public referralsCount; // referrer address => referrals count

  /* Recipient of protocol fees. */
  // address public protocolFeeRecipient;

  /* Relayer info (Fees has two decimals by default, so 100 => 1%) */
  struct Relayer {
    address protocolFeeRecipient;
    address relayerAddress;
    uint256 relayerFee;
    uint256 protocolFee;
    uint256 referralFee;
    ReferralSide referralSide;
    bool referralEnabled; // True if referral system is enabled
    bool referralRegistrationEnabled; // True if new referrals are enabled
    IAtomicMatchHandler atomicMatchHandler;
  }

  /* Registerd Relayers */
  mapping(address => Relayer) public registeredRelayers;

  /* Registererd Payment Tokens */
  mapping(address => bool) public registeredPaymentTokens;

  /* Discount for payment tokens of relayers if available else 0 
    (Discount on native relayer token can be used for early incentives) */
  mapping(address => mapping(address => uint256)) public paymentTokenDiscounts;

  /* An ECDSA signature. */
  struct Sig {
    /* v parameter */
    uint8 v;
    /* r parameter */
    bytes32 r;
    /* s parameter */
    bytes32 s;
  }

  /**
   * Side: buy or sell.
   */
  enum Side {
    Buy,
    Sell
  }

  /**
   * Currently supported kinds of sale.
   */
  enum SaleKind {
    FixedPrice,
    DutchAuction,
    EnglishAuction
  }

  /**
   * Type of the asset.
   */
  enum AssetType {
    ERC721,
    ERC1155
  }

  /**
   * From which side to take the referral discount
   */
  enum ReferralSide {
    Protocol,
    Relayer,
    Seller
  }

  /* An order on the exchange. */
  struct Order {
    /* Asset address (ERC165 | ERC721 | ERC1155)*/
    address asset;
    /* Asset ID */
    uint256 assetId;
    /* Asset Amount (Used for ERC1155 collections) */
    uint256 assetAmount;
    /* Asset Type (ERC721 | ERC1155)*/
    AssetType assetType;
    /* Exchange address. */
    address exchange;
    /* Relayer address. */
    address relayer;
    /* Order maker address. */
    address maker;
    /* Order taker address, if specified. */
    address taker;
    /* Relayer Fee of the order. */
    uint256 relayerFee;
    /* Protocol fee of the order.*/
    uint256 protocolFee;
    /* Side (buy/sell). */
    Side side;
    /* Kind of sale. */
    SaleKind saleKind;
    /* Token used to pay for the order, or the zero-address as a sentinel value for Ether. */
    address paymentToken;
    /* Opening price of the order (in paymentTokens). 
        (This is the initial price for english auction & the opening price for dutch auction) */
    uint256 basePrice;
    /* Auction reserve parameter - minimum bid increment for English auctions, starting/ending price difference. */
    uint256 reservePrice;
    /* Listing timestamp. */
    uint256 listingTime;
    /* Expiration timestamp - 0 for no expiry. */
    uint256 expirationTime;
    /* Order salt, used to prevent duplicate hashes. */
    uint256 salt;
  }

  // address is 0x14 bytes, uint256 has 0x20 bytes, enum is 1
  uint256 constant ORDER_SIZE = ((0x14 * 6) + (0x20 * 9) + 3);

  event OrderApprovedPartOne(
    bytes32 indexed hash,
    address asset,
    uint256 assetId,
    uint256 assetAmount,
    AssetType assetType,
    address exchange,
    address relayer,
    address indexed maker,
    address taker,
    uint256 relayerFee,
    uint256 protocolFee,
    Side side,
    SaleKind saleKind
  );
  event OrderApprovedPartTwo(
    bytes32 indexed hash,
    address paymentToken,
    uint256 basePrice,
    uint256 topPrice,
    uint256 listingTime,
    uint256 expirationTime,
    uint256 salt,
    bool orderbookInclusionDesired
  );
  event OrderCancelled(bytes32 indexed hash);
  event OrdersMatched(bytes32 buyHash, bytes32 sellHash, address indexed maker, address indexed taker, uint256 price);
  event ReferralRecorded(address user, address referrer);
  event ReferralPaid(address user, address referrer, address paymentToken, uint256 amount);
  event RelayerAdded(Relayer indexed relayer);

  constructor(Relayer memory relayer) {
    setRelayer(relayer);
  }

  function changeFee(uint256 fee) public {
    require(registeredRelayers[msg.sender].protocolFeeRecipient != address(0), "TrashArtExchange: not authorized");
    Relayer storage _relayer = registeredRelayers[msg.sender];
    _relayer.relayerFee = fee;
  }

  /**
   * Registers/Updates a relayer address and its relevant fee
   */
  function setRelayer(Relayer memory relayer) public onlyOwner {
    require(relayer.relayerAddress != address(0), "TrashArtExchange: relayerAddress zero address");
    require(relayer.protocolFeeRecipient != address(0), "TrashArtExchange: protocolFeeRecipient zero address");
    if (address(registeredRelayers[relayer.relayerAddress].relayerAddress) == address(0)) emit RelayerAdded(relayer);
    registeredRelayers[relayer.relayerAddress] = relayer;
  }

  /**
   * Set the payment token discount for relayers
   */
  function setPaymentTokenDiscount(
    address relayer,
    address token,
    uint256 discount
  ) internal onlyOwner {
    require(discount > 0 && discount <= 10000, "Invalid Discount!");
    paymentTokenDiscounts[relayer][token] = discount;
  }

  /**
   * @dev Change the protocol fee recipient (owner only)
   * @param newProtocolFeeRecipient New protocol fee recipient address
   */
  function changeProtocolFeeRecipient(address relayer, address newProtocolFeeRecipient) internal onlyOwner {
    registeredRelayers[relayer].protocolFeeRecipient = newProtocolFeeRecipient;
  }

  /**
   * @dev Hash an order, returning the canonical order hash, without the message prefix
   * @param order Order to hash
   * @return hash of order
   */
  function hashOrder(Order memory order) internal pure returns (bytes32 hash) {
    /* Unfortunately abi.encodePacked doesn't work here, stack size constraints. */
    bytes memory array = new bytes(ORDER_SIZE);
    uint256 index;
    assembly {
      index := add(array, 0x20)
    }
    index = ArrayUtils.unsafeWriteAddress(index, order.asset);
    index = ArrayUtils.unsafeWriteUint(index, order.assetId);
    index = ArrayUtils.unsafeWriteUint(index, order.assetAmount);
    index = ArrayUtils.unsafeWriteUint8(index, uint8(order.assetType));
    index = ArrayUtils.unsafeWriteAddress(index, order.exchange);
    index = ArrayUtils.unsafeWriteAddress(index, order.relayer);
    index = ArrayUtils.unsafeWriteAddress(index, order.maker);
    index = ArrayUtils.unsafeWriteAddress(index, order.taker);
    index = ArrayUtils.unsafeWriteUint(index, order.relayerFee);
    index = ArrayUtils.unsafeWriteUint(index, order.protocolFee);
    index = ArrayUtils.unsafeWriteUint8(index, uint8(order.side));
    index = ArrayUtils.unsafeWriteUint8(index, uint8(order.saleKind));
    index = ArrayUtils.unsafeWriteAddress(index, order.paymentToken);
    index = ArrayUtils.unsafeWriteUint(index, order.basePrice);
    index = ArrayUtils.unsafeWriteUint(index, order.reservePrice);
    index = ArrayUtils.unsafeWriteUint(index, order.listingTime);
    index = ArrayUtils.unsafeWriteUint(index, order.expirationTime);
    index = ArrayUtils.unsafeWriteUint(index, order.salt);
    assembly {
      hash := keccak256(add(array, 0x20), ORDER_SIZE)
    }
    return hash;
  }

  /**
   * @dev Hash an order, returning the hash that a client must sign, including the standard message prefix
   * @param order Order to hash
   * @return Hash of message prefix and order hash per Ethereum format
   */
  function hashToSign(Order memory order) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashOrder(order)));
  }

  function getHash(Order memory order) external pure returns (bytes32, bytes32) {
    return (hashOrder(order), hashToSign(order));
  }

  /**
   * @dev Assert an order is valid and return its hash
   * @param order Order to validate
   * @param sig ECDSA signature
   */
  function requireValidOrder(Order memory order, Sig memory sig) public view returns (bytes32) {
    bytes32 hash = hashToSign(order);
    require(validateOrder(hash, order, sig), "Invalid Order");
    return hash;
  }

  /**
   * @dev Validate order parameters (does *not* check signature validity)
   * @param order Order to validate
   */
  function validateOrderParameters(Order memory order) public view returns (bool) {
    /* Order must be targeted at this protocol version (this Exchange contract). */
    if (order.exchange != address(this)) {
      return false;
    }

    // only allow transactions for relayers
    if (registeredRelayers[order.relayer].relayerAddress == address(0)) {
      return false;
    }

    /* Order must possess valid sale kind parameter combination. */
    if (!validateParameters(order.saleKind, order.expirationTime)) {
      return false;
    }

    /** Order must have current valid fee. */
    if (
      order.protocolFee < registeredRelayers[order.relayer].protocolFee ||
      order.relayerFee < registeredRelayers[order.relayer].relayerFee
    ) {
      return false;
    }

    return true;
  }

  /**
   * @dev Validate a provided previously approved / signed order, hash, and signature.
   * @param hash Order hash (already calculated, passed to avoid recalculation)
   * @param order Order to validate
   * @param sig ECDSA signature
   */
  function validateOrder(
    bytes32 hash,
    Order memory order,
    Sig memory sig
  ) public view returns (bool) {
    /* Not done in an if-conditional to prevent unnecessary ecrecover evaluation, which seems to happen even though it should short-circuit. */

    /* Order must have valid parameters. */
    if (!validateOrderParameters(order)) {
      return false;
    }

    /* Order must have not been canceled or already filled. */
    if (cancelledOrFinalized[hash]) {
      return false;
    }

    /* Order authentication. Order must be either:
        /* (a) previously approved */
    if (approvedOrders[hash]) {
      return true;
    }

    /* or (b) ECDSA-signed by maker. */
    if (ecrecover(hash, sig.v, sig.r, sig.s) == order.maker) {
      return true;
    }

    return false;
  }

  /**
   * @dev Approve an order and optionally mark it for orderbook inclusion. Must be called by the maker of the order
   * @param order Order to approve
   * @param orderbookInclusionDesired Whether orderbook providers should include the order in their orderbooks
   */
  function approveOrder(Order memory order, bool orderbookInclusionDesired) public {
    /* CHECKS */

    /* Assert sender is authorized to approve order. */
    require(msg.sender == order.maker, "Not approved");

    /* Calculate order hash. */
    bytes32 hash = hashToSign(order);

    /* Assert order has not already been approved. */
    require(!approvedOrders[hash], "Not approved");

    /* EFFECTS */

    /* Mark order as approved. */
    approvedOrders[hash] = true;

    /* Log approval event. Must be split in two due to Solidity stack size limitations. */
    {
      emit OrderApprovedPartOne(
        hash,
        order.asset,
        order.assetId,
        order.assetAmount,
        order.assetType,
        order.exchange,
        order.relayer,
        order.maker,
        order.taker,
        order.relayerFee,
        order.protocolFee,
        order.side,
        order.saleKind
      );
    }
    {
      emit OrderApprovedPartTwo(
        hash,
        order.paymentToken,
        order.basePrice,
        order.reservePrice,
        order.listingTime,
        order.expirationTime,
        order.salt,
        orderbookInclusionDesired
      );
    }
  }

  /**
   * @dev Cancel an order, preventing it from being matched. Must be called by the maker of the order
   * @param order Order to cancel
   * @param sig ECDSA signature
   */
  function cancelOrder(Order memory order, Sig memory sig) public {
    /* CHECKS */

    /* Calculate order hash. */
    bytes32 hash = requireValidOrder(order, sig);

    /* Assert sender is authorized to cancel order. */
    require(msg.sender == order.maker, "Not authorized");

    /* EFFECTS */

    /* Mark order as cancelled, preventing it from being matched. */
    cancelledOrFinalized[hash] = true;

    /* Log cancel event. */
    emit OrderCancelled(hash);
  }

  /**
   * @dev Calculate the current price of an order (convenience function)
   * @param order Order to calculate the price of
   * @return The current price of the order
   */
  function calculateCurrentPrice(Order memory order) public view returns (uint256) {
    if (order.saleKind == SaleKind.DutchAuction) return calculateDutchAuctionCurrentPrice(order);
    return order.basePrice;
  }

  /**
   * @dev Return whether or not two orders can be matched with each other by basic parameters (does not check order signatures)
   * @param buy Buy-side order
   * @param sell Sell-side order
   * @return Whether or not the two orders can be matched
   */
  function ordersCanMatch(Order memory buy, Order memory sell) public view returns (bool) {
    return (/* Must be opposite-side. */
    (buy.side == Side.Buy && sell.side == Side.Sell) &&
      /* Must use same asset. */
      (buy.asset == sell.asset) &&
      (buy.assetId == sell.assetId) &&
      (buy.assetType == sell.assetType) &&
      /* Must use same payment token. */
      (buy.paymentToken == sell.paymentToken) &&
      /* Must match maker/taker addresses. */
      (sell.taker == address(0) || sell.taker == buy.maker) &&
      (buy.taker == address(0) || buy.taker == sell.maker) &&
      /** Buy price must satify sell price */
      canPriceMatch(sell, buy) &&
      /* Buy-side order must be settleable. */
      canSettleOrder(buy.listingTime, buy.expirationTime) &&
      /* Sell-side order must be settleable. */
      canSettleOrder(sell.listingTime, sell.expirationTime));
  }

  function recordReferral(address _user, address _referrer) internal {
    if (_user != address(0) && _referrer != address(0) && _user != _referrer && referrers[_user] == address(0)) {
      referrers[_user] = _referrer;
      referralsCount[_referrer] += 1;
      emit ReferralRecorded(_user, _referrer);
    }
  }

  /**
   * @dev Atomically match two orders, ensuring validity of the match, and execute all associated state transitions. Protected against reentrancy by a contract-global lock.
   * @param buy Buy-side order
   * @param buySig Buy-side order signature
   * @param sell Sell-side order
   * @param sellSig Sell-side order signature
   */
  function atomicMatch(
    Order memory buy,
    Sig memory buySig,
    Order memory sell,
    Sig memory sellSig,
    address referrer
  ) external payable nonReentrant {
    /** Record Referral */
    recordReferral(sell.maker, referrer);

    /* CHECKS */

    /* Ensure buy order validity and calculate hash if necessary. */
    bytes32 buyHash;
    if (buy.maker == msg.sender) {
      require(validateOrderParameters(buy), "Invalid order params!");
    } else {
      buyHash = requireValidOrder(buy, buySig);
    }

    /* Ensure sell order validity and calculate hash if necessary. */
    bytes32 sellHash;
    if (sell.maker == msg.sender) {
      require(validateOrderParameters(sell), "Invalid order params!");
    } else {
      sellHash = requireValidOrder(sell, sellSig);
    }

    /* Must be matchable. */
    require(ordersCanMatch(buy, sell), "Order Failed to match!");

    /* EFFECTS */

    /* Mark previously signed or approved orders as finalized. */
    if (msg.sender != buy.maker) {
      cancelledOrFinalized[buyHash] = true;
    }
    if (msg.sender != sell.maker) {
      cancelledOrFinalized[sellHash] = true;
    }

    /* INTERACTIONS */

    /* Execute funds transfer and pay fees. */
    uint256 price = executeFundsTransfer(buy, sell);

    /* Execute Asset transfer according to AssetType */
    executeAssetTransfer(sell.maker, buy.maker, sell.asset, sell.assetId, sell.assetAmount, sell.assetType);

    IAtomicMatchHandler atomicMatchHandler = registeredRelayers[sell.relayer].atomicMatchHandler;
    if (address(atomicMatchHandler) != address(0))
      atomicMatchHandler.onAtomicMatch(sell.asset, sell.assetId, sell.assetAmount, sell.maker, buy.maker, price);

    /* Log match event. */
    emit OrdersMatched(buyHash, sellHash, sell.maker, buy.maker, price);
  }

  /**
   * @dev Execute all ERC20 token / Ether transfers associated with an order match (fees and buyer => seller transfer)
   * @param buy Buy-side order
   * @param sell Sell-side order
   */
  function executeFundsTransfer(Order memory buy, Order memory sell) internal returns (uint256) {
    /* Only payable in the special case of unwrapped Ether. */
    if (sell.paymentToken != address(0)) {
      require(msg.value == 0, "Invalid Payment");
    }

    /* Calculate match price. */
    uint256 price = calculateCurrentPrice(sell);

    uint256 totalFee = chargeFee(sell, price, buy.maker);

    /* Special-case Ether, order must be matched by buyer. */
    if (sell.paymentToken == address(0)) {
      require(msg.value >= price, "Invalid Payment");
      payable(sell.maker).transfer(price - totalFee);
      /* Allow overshoot for variable-price auctions, refund difference. */
      uint256 extra = msg.value - price;
      if (extra > 0) {
        payable(buy.maker).transfer(extra);
      }
    }
    /** If ERC20 token payment method is used */
    else {
      IERC20(sell.paymentToken).safeTransferFrom(buy.maker, sell.maker, price - totalFee);
    }

    /* This contract should never hold Ether, however, we cannot assert this, since it is impossible to prevent anyone from sending Ether e.g. with selfdestruct. */
    return price;
  }

  /**
   * @dev Charge a fee in Eth or Tokens
   * @param sellOrder sell order
   * @param amount amount of order
   * @param buyer Relayer address
   */
  function chargeFee(
    Order memory sellOrder,
    uint256 amount,
    address buyer
  ) internal returns (uint256) {
    uint256 totalFee;
    Relayer memory relayerInfo = registeredRelayers[sellOrder.relayer];
    uint256 referralFee = payReferrerCommission(sellOrder.maker, buyer, amount, sellOrder.paymentToken, relayerInfo);
    totalFee += referralFee; // if referral side is seller, don't need to do anything after this, else need to subtract referral fee from either protocol or relayer fee
    if (relayerInfo.protocolFee != 0) {
      uint256 feeAmount = (amount * relayerInfo.protocolFee) / 10000;
      if (referralFee != 0 && relayerInfo.referralSide == ReferralSide.Protocol) {
        feeAmount -= referralFee;
      }
      totalFee = feeAmount;
      /** Eth as payment method */
      if (sellOrder.paymentToken == address(0))
        payable(relayerInfo.protocolFeeRecipient).transfer(feeAmount);
        /** Token as payment method */
      else IERC20(sellOrder.paymentToken).safeTransferFrom(buyer, relayerInfo.protocolFeeRecipient, feeAmount);
    }
    // Charge fee if RelayerFee is not zero and Relayer discount for this token is not 100%
    uint256 tokenDiscount = paymentTokenDiscounts[sellOrder.relayer][sellOrder.paymentToken];
    if (relayerInfo.relayerFee != 0 && tokenDiscount != 10000) {
      uint256 feeAmount = (amount * relayerInfo.protocolFee) / 10000;
      if (referralFee != 0 && relayerInfo.referralSide == ReferralSide.Relayer) {
        feeAmount -= referralFee;
      }
      /** apply discount if available */
      if (tokenDiscount > 0) feeAmount = feeAmount - ((feeAmount * tokenDiscount) / 10000);
      totalFee += feeAmount;
      /** Eth as payment method */
      if (sellOrder.paymentToken == address(0))
        payable(sellOrder.relayer).transfer(feeAmount);
        /** Token as payment method */
      else IERC20(sellOrder.paymentToken).safeTransferFrom(buyer, sellOrder.relayer, feeAmount);
    }
    // Charge Royalty fee if any
    if (sellOrder.asset.supportsInterface(_INTERFACE_ID_FEES)) {
      address payable[] memory recipients = IHasSecondarySaleFees(sellOrder.asset).getFeeRecipients(sellOrder.assetId);
      uint256[] memory fees = IHasSecondarySaleFees(sellOrder.asset).getFeeBps(sellOrder.assetId);
      if (recipients.length > 0) {
        for (uint256 i = 0; i < recipients.length; i++) {
          uint256 fee = (amount * fees[i]) / 10000;
          totalFee += fee;
          if (sellOrder.paymentToken == address(0)) recipients[i].transfer(fee);
          else IERC20(sellOrder.paymentToken).safeTransferFrom(buyer, recipients[i], fees[i]);
        }
      }
    }
    return totalFee;
  }

  function payReferrerCommission(
    address seller,
    address buyer,
    uint256 amount,
    address paymentToken,
    Relayer memory relayerInfo
  ) internal returns (uint256) {
    if (!relayerInfo.referralEnabled) return 0;

    uint256 referrerCommission = (amount * relayerInfo.referralFee) / 10000;
    address referrer = referrers[seller];
    if (referrer != address(0)) {
      if (paymentToken == address(0)) payable(referrer).transfer(referrerCommission);
      else IERC20(paymentToken).safeTransferFrom(buyer, referrer, referrerCommission);
    }
    emit ReferralPaid(seller, referrer, paymentToken, referrerCommission);
    return referrerCommission;
  }

  /** Transfer Asset */
  function executeAssetTransfer(
    address from,
    address to,
    address asset,
    uint256 assetId,
    uint256 assetAmount,
    AssetType assetType
  ) internal {
    if (assetType == AssetType.ERC721) {
      IERC721(asset).safeTransferFrom(from, to, assetId);
    } else {
      IERC1155(asset).safeTransferFrom(from, to, assetId, assetAmount, "");
    }
  }

  /**
   * @dev Check whether the parameters of a sale are valid
   * @param saleKind Kind of sale
   * @param expirationTime Order expiration time
   * @return Whether the parameters were valid
   */
  function validateParameters(SaleKind saleKind, uint256 expirationTime) public pure returns (bool) {
    /* Auctions must have a set expiration date. */
    return (saleKind == SaleKind.FixedPrice || expirationTime > 0);
  }

  /**
   * @dev Return whether or not an order can be settled
   * @dev Precondition: parameters have passed validateParameters
   * @param listingTime Order listing time
   * @param expirationTime Order expiration time
   */
  function canSettleOrder(uint256 listingTime, uint256 expirationTime) public view returns (bool) {
    return (listingTime < block.timestamp) && (expirationTime == 0 || block.timestamp < expirationTime);
  }

  /** Verify if price for both orders can match
   * @param sell Sell order
   * @param buy Buy Order
   */
  function canPriceMatch(Order memory sell, Order memory buy) internal view returns (bool) {
    return
      sell.saleKind == SaleKind.DutchAuction
        ? buy.basePrice >= calculateDutchAuctionCurrentPrice(sell)
        : buy.basePrice >= sell.basePrice;
  }

  /**
   * @dev Calculate the settlement price of an order
   * @dev Precondition: parameters have passed validateParameters.
   * @param sellOrder Dutch Auction Order
   */
  function calculateDutchAuctionCurrentPrice(Order memory sellOrder) public view returns (uint256 finalPrice) {
    uint256 diff = ((sellOrder.basePrice - sellOrder.reservePrice) * (block.timestamp - sellOrder.listingTime)) /
      (sellOrder.expirationTime - sellOrder.listingTime);
    return sellOrder.basePrice - diff;
  }

  /** This contract should not hold any eth, if sent directly by mistake, should be returned immediately to the sender */
  receive() external payable {
    payable(msg.sender).transfer(msg.value);
  }

  /** This contract should not hold any ERC20 tokens, if sent by mistake, this method can be used to drain them.
        If you are the sender, feel free to contact us, we would be glad to return them :)
        NOTE: Approved tokens for orders cannot be drain by this method! 
    */
  function drainERC20Token(
    IERC20 token,
    uint256 amount,
    address to
  ) external onlyOwner {
    token.safeTransfer(to, amount);
  }
}
