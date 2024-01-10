// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./ITiny721.sol";

/*
  It saves bytecode to revert on custom errors instead of using require
  statements. We are just declaring these errors for reverting with upon various
  conditions later in this contract.
*/
error CannotEndSaleBeforeItStarts();
error CannotEndAtHigherPrice();
error CannotTransferIncorrectAmount();
error PaymentTransferFailed();
error CannotVerifyAsWhitelistMember();
error CannotExceedWhitelistAllowance();
error CannotBuyZeroItems();
error CannotBuyBeforeSaleStarts();
error CannotBuyFromEndedSale();
error CannotExceedPerTransactionCap();
error CannotExceedPerCallerCap();
error CannotExceedTotalCap();
error CannotUnderpayForMint();
error RefundTransferFailed();
error SweepingTransferFailed();

/**
  @title A contract for selling NFTs for a flat price with presale.
  @author Tim Clancy
  @author Qazawat Zirak
  @author Rostislav Khlebnikov
  @author Nikita Elunin
  @author 0xthrpw

  This contract is a modified version of SuperFarm mint shops optimized for the
  specific use case of:
    1. selling a single type of ERC-721 item from a single contract for ETH

  This launchpad contract sells new items by minting them into existence. It
  cannot be used to sell items that already exist.

  March 10th, 2022.
*/
contract DropShop721 is
  Ownable, ReentrancyGuard
{
  using SafeERC20 for IERC20;

  /// The address of the ERC-721 item being sold.
  address public immutable collection;

  /// The time when the public sale begins.
  uint256 public immutable startTime;

  /// The time when the public sale ends.
  uint256 public immutable endTime;

  /// The maximum number of items from the `collection` that may be sold.
  uint256 public immutable totalCap;

  /// The maximum number of items that a single address may purchase.
  uint256 public immutable callerCap;

  /// The maximum number of items that may be purchased in a single transaction.
  uint256 public immutable transactionCap;

  /// The price at which to sell the item.
  uint256 public immutable price;

  /// The destination of claimed payments.
  address public immutable paymentDestination;

  /// A mapping to track the number of items purchases by each caller.
  mapping ( address => uint256 ) public purchaseCounts;

  /// The total number of items sold by the shop.
  uint256 public sold;

  /*
    A struct used to pass shop configuration details upon contract construction.

    @param startTime The time when the public sale begins.
    @param endTime The time when the public sale ends.
    @param totalCap The maximum number of items from the `collection` that may
      be sold.
    @param callerCap The maximum number of items that a single address may
      purchase.
    @param transactionCap The maximum number of items that may be purchased in
      a single transaction.
    @param price The price to sell the item at.
  */
  struct ShopConfiguration {
    uint256 startTime;
    uint256 endTime;
    uint256 totalCap;
    uint256 callerCap;
    uint256 transactionCap;
    uint256 price;
    address paymentDestination;
  }

  /**
    Construct a new shop with configuration details about the intended sale.

    @param _collection The address of the ERC-721 item being sold.
    @param _configuration A parameter containing shop configuration information,
      passed here as a struct to avoid a stack-to-deep error.
  */
  constructor (
    address _collection,
    ShopConfiguration memory _configuration
  ) {

    // Perform basic input validation.
    if (_configuration.endTime < _configuration.startTime) {
      revert CannotEndSaleBeforeItStarts();
    }

    // Once input parameters have been validated, set storage.
    collection = _collection;
    startTime = _configuration.startTime;
    endTime = _configuration.endTime;
    totalCap = _configuration.totalCap;
    callerCap = _configuration.callerCap;
    transactionCap = _configuration.transactionCap;
    price = _configuration.price;
    paymentDestination = _configuration.paymentDestination;
  }

  /**
    Allow a caller to purchase an item.

    @param _amount The amount of items that the caller would like to purchase.
  */
  function mint (
    uint256 _amount
  ) public virtual payable nonReentrant {

    // Reject purchases for no items.
    if (_amount < 1) { revert CannotBuyZeroItems(); }

    /// Reject purchases that happen before the start of the sale.
    if (block.timestamp < startTime) { revert CannotBuyBeforeSaleStarts(); }

    /// Reject purchases that happen after the end of the sale.
    if (block.timestamp > endTime) { revert CannotBuyFromEndedSale(); }

    // Reject purchases that exceed the per-transaction cap.
    if (_amount > transactionCap) {
      revert CannotExceedPerTransactionCap();
    }

    // Reject purchases that exceed the per-caller cap.
    if (purchaseCounts[_msgSender()] + _amount > callerCap) {
      revert CannotExceedPerCallerCap();
    }

    // Reject purchases that exceed the total sale cap.
    if (sold + _amount > totalCap) { revert CannotExceedTotalCap(); }

    // Reject the purchase if the caller is underpaying.
    uint256 totalCharge = price * _amount;
    if (msg.value < totalCharge) { revert CannotUnderpayForMint(); }

    // Refund the caller's excess payment if they overpaid.
    if (msg.value > totalCharge) {
      uint256 excess = msg.value - totalCharge;
      (bool returned, ) = payable(_msgSender()).call{ value: excess }("");
      if (!returned) { revert RefundTransferFailed(); }
    }

    // Update the count of items sold.
    sold += _amount;

    // Update the caller's purchase count.
    purchaseCounts[_msgSender()] += _amount;

    // Mint the items.
    ITiny721(collection).mint_Qgo(_msgSender(), _amount);
  }

  /**
    Allow any caller to send this contract's balance of Ether to the payment
    destination.
  */
  function claim () external nonReentrant {
    (bool success, ) = payable(paymentDestination).call{
      value: address(this).balance
    }("");
    if (!success) { revert SweepingTransferFailed(); }
  }

  /**
    Allow the owner to sweep either Ether or a particular ERC-20 token from the
    contract and send it to another address. This allows the owner of the shop
    to withdraw their funds after the sale is completed.

    @param _token The token to sweep the balance from; if a zero address is sent
      then the contract's balance of Ether will be swept.
    @param _amount The amount of token to sweep.
    @param _destination The address to send the swept tokens to.
  */
  function sweep (
    address _token,
    address _destination,
    uint256 _amount
  ) external onlyOwner nonReentrant {

    // A zero address means we should attempt to sweep Ether.
    if (_token == address(0)) {
      (bool success, ) = payable(_destination).call{ value: _amount }("");
      if (!success) { revert SweepingTransferFailed(); }

    // Otherwise, we should try to sweep an ERC-20 token.
    } else {
      IERC20(_token).safeTransfer(_destination, _amount);
    }
  }
}
