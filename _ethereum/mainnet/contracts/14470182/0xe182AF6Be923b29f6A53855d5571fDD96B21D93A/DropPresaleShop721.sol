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
error CannotBuyFromEndedSale();
error CannotExceedPerTransactionCap();
error CannotExceedPerCallerCap();
error CannotExceedTotalCap();
error CannotUnderpayForMint();
error RefundTransferFailed();
error SweepingTransferFailed();

/**
  @title A contract for selling NFTs via a merkle-based whitelist presale with
    conversion into a public sale.
  @author Tim Clancy
  @author Qazawat Zirak
  @author Rostislav Khlebnikov
  @author Nikita Elunin
  @author 0xthrpw

  This contract is a modified version of SuperFarm mint shops optimized for the
  specific use case of:
    1. selling a single type of ERC-721 item from a single contract
    2. running potentially multiple whitelisted presales with potentially
       multiple different participants and different prices
    3. selling the item for both ETH and an ERC-20 token during the presale
    4. converting into a public sale that can sell for ETH only

  This launchpad contract sells new items by minting them into existence. It
  cannot be used to sell items that already exist.

  March 10th, 2022.
*/
contract DropPresaleShop721 is
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

  /**
    The number of whitelists that have been added. This is used for looking up
    specific whitelist details from the `whitelists` mapping.
  */
  uint256 public immutable whitelistCount;

  /**
    This struct is used at the moment of contract construction to specify a
    presale whitelist that should apply to the sale this shop runs.

    @param root The hash root of merkle tree uses to validate a caller's
      inclusion in this whitelist.
    @param startTime The starting time of this whitelist. When this is set to a
      time earlier than the contract's `startTime` storage variable, that means
      that this whitelist will begin earlier than the public sale. In effect,
      that means that this whitelist will define a presale.
    @param endTime The ending time of this whitelist. For standard presale
      behavior, this should be set equal to the contract's `startTime` storage
      variable to end the presale when the public sale begins. This can be set
      later than the contract's `startTime` storage variable, but it will have
      no effect. A presale whitelist may not be used once the public sale has
      begun. Likewise, a presale may not run longer than the public item sale.
      The public item sale `endTime` storage variable of this contract will
      always override a whitelist's ending time.
    @param price The price that applies to this presale whitelist.
    @param token The address of the token with which purchases in this whitelist
      will be made. If this is the zero address, then this whitelist will
      conduct purchases using ETH.
  */
  struct CreateWhitelist {
    bytes32 root;
    uint256 startTime;
    uint256 endTime;
    uint256 price;
    address token;
  }

  /// A mapping to look up whitelist details for a given whitelist ID.
  mapping ( uint256 => CreateWhitelist ) public whitelists;

  /// A mapping to track the number of items purchases by each caller.
  mapping ( address => uint256 ) public purchaseCounts;

  /// The total number of items sold by the shop.
  uint256 public sold;

  /**
    This struct is used at the moment of NFT purchase to let a caller submit
    proof that they are actually entitled to a position on a presale whitelist.

    @param id The ID of the whitelist to check proof against.
    @param index The element index in the original array for proof verification.
    @param allowance The quantity available to the caller for presale purchase.
    @param proof A submitted proof that the user is on the whitelist.
  */
  struct WhitelistProof {
    uint256 id;
    uint256 index;
    uint256 allowance;
    bytes32[] proof;
  }

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
  }

  /**
    Construct a new shop with configuration details about the intended sale.

    @param _collection The address of the ERC-721 item being sold.
    @param _configuration A parameter containing shop configuration information,
      passed here as a struct to avoid a stack-to-deep error.
    @param _whitelists The array of whitelist creation data containing details
      for any presales being run.
  */
  constructor (
    address _collection,
    ShopConfiguration memory _configuration,
    CreateWhitelist[] memory _whitelists
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

    // Store all of the whitelists.
    whitelistCount = _whitelists.length;
    for (uint256 i = 0; i < _whitelists.length; i++) {
      whitelists[i] = _whitelists[i];
    }
  }

  /**
    A private helper function to sell an item to a public sale participant. This
    selling function refunds any overpayment to the user; refunding overpayment
    is expected to be a common situation given the price decay in the Dutch
    auction.

    @param _amount The number of items that the caller would like to purchase.
  */
  function sellPublic (
    uint256 _amount
  ) private {
    uint256 totalCharge = price * _amount;

    // Reject the purchase if the caller is underpaying.
    if (msg.value < totalCharge) { revert CannotUnderpayForMint(); }

    // Refund the caller's excess payment if they overpaid.
    if (msg.value > totalCharge) {
      uint256 excess = msg.value - totalCharge;
      (bool returned, ) = payable(_msgSender()).call{ value: excess }("");
      if (!returned) { revert RefundTransferFailed(); }
    }
  }

  /**
    Calculate a root hash from given parameters.

    @param _index The index of the hashed node from the list.
    @param _node The index of the hashed node at that index.
    @param _merkleProof An array of one required merkle hash per level.

    @return The root hash from given parameters.
  */
  function getRootHash (
    uint256 _index,
    bytes32 _node,
    bytes32[] calldata _merkleProof
  ) private pure returns (bytes32) {
    uint256 path = _index;
    for (uint256 i = 0; i < _merkleProof.length; i++) {
      if ((path & 0x01) == 1) {
        _node = keccak256(abi.encodePacked(_merkleProof[i], _node));
      } else {
        _node = keccak256(abi.encodePacked(_node, _merkleProof[i]));
      }
      path /= 2;
    }
    return _node;
  }

  /**
    A helper function to verify an access against a targeted on-chain merkle
    root.

    @param _accesslistId The id of the accesslist containing the merkleRoot.
    @param _index The index of the hashed node from off-chain list.
    @param _node The actual hashed node which needs to be verified.
    @param _merkleProof The merkle hashes from the off-chain merkle tree.

    @return Whether the provided merkle proof is verifiably part of the on-chain
      root.
  */
  function verify (
    uint256 _accesslistId,
    uint256 _index,
    bytes32 _node,
    bytes32[] calldata _merkleProof
  ) private view returns (bool) {
    if (whitelists[_accesslistId].root == 0) {
      return false;
    } else if (block.timestamp < whitelists[_accesslistId].startTime) {
      return false;
    } else if (block.timestamp > whitelists[_accesslistId].endTime) {
      return false;
    } else if (
      getRootHash(_index, _node, _merkleProof) != whitelists[_accesslistId].root
    ) {
      return false;
    }
    return true;
  }

  /**
    A private helper function to sell an item to a whitelist presale
    participant.

    @param _amount The number of items that the caller would like to purchase.
    @param _whitelist A whitelist proof for users to submit with their claim to
      verify that they are in fact on the whitelist.
  */
  function sellWhitelist (
    uint256 _amount,
    WhitelistProof calldata _whitelist
  ) private {

    // Verify that the caller is on the merkle whitelist.
    bool verified = verify(
      _whitelist.id,
      _whitelist.index,
      keccak256(
        abi.encodePacked(
          _whitelist.index,
          _msgSender(),
          _whitelist.allowance
        )
      ),
      _whitelist.proof
    );

    // Reject the purchase if the caller is not a valid whitelist member.
    if (!verified) { revert CannotVerifyAsWhitelistMember(); }

    // Reject the purchase if the caller is exceeding their whitelist allowance.
    if (purchaseCounts[_msgSender()] + _amount > _whitelist.allowance) {
      revert CannotExceedWhitelistAllowance();
    }

    // Calculate the sale token and price.
    address token = whitelists[_whitelist.id].token;
    uint256 whitelistPrice = whitelists[_whitelist.id].price * _amount;

    // The zero address indicates that the purchase asset is Ether.
    if (token == address(0)) {
      if (msg.value != whitelistPrice) {
        revert CannotTransferIncorrectAmount();
      }

    // Otherwise, the caller is making their purchase with an ERC-20 token.
    } else {
      IERC20(token).safeTransferFrom(
        _msgSender(),
        address(this),
        whitelistPrice
      );
    }
  }

  /**
    Allow a caller to purchase an item.

    @param _amount The amount of items that the caller would like to purchase.
    @param _whitelist The caller-subumitted whitelist proof to check if they
      belong on a presale whitelist.
  */
  function mint (
    uint256 _amount,
    WhitelistProof calldata _whitelist
  ) external payable nonReentrant {

    // Reject purchases for no items.
    if (_amount < 1) { revert CannotBuyZeroItems(); }

    /*
      Reject purchases that happen after the end of the public sale. Do note
      that this means that whitelist sales with an ending duration _after_ the
      end of the public sale are ignored completely. In other words: the ending
      time of the public sale takes precedent over the ending time of a
      whitelisted presale. A whitelisted presale may not continue selling items
      after the public sale has ended.
    */
    if (block.timestamp >= endTime) { revert CannotBuyFromEndedSale(); }

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

    /*
      If the current timestamp is greater than this contract's `startTime`, the
      public sale has begun and all users will be directed to the public sale
      functionality.
    */
    if (block.timestamp >= startTime) {
      sellPublic(_amount);

    /*
      Otherwise, since the public sale has not begun, attempt to sell to this
      user as a member of the presale whitelist.
    */
    } else {
      sellWhitelist(_amount, _whitelist);
    }

    // Update the count of items sold.
    sold += _amount;

    // Update the caller's purchase count.
    purchaseCounts[_msgSender()] += _amount;

    // Mint the items.
    ITiny721(collection).mint_Qgo(_msgSender(), _amount);
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
