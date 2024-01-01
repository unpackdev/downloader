/**
 *
 * Developed by
 *                        _       _             _ _
 *                       | |     | |           | (_)
 *     __ _ _ __ ___   __| |  ___| |_ _   _  __| |_  ___
 *    / _` | '__/ _ \ / _` | / __| __| | | |/ _` | |/ _ \
 *   | (_| | | | (_) | (_| |_\__ \ |_| |_| | (_| | | (_) |
 *    \__,_|_|  \___/ \__,_(_)___/\__|\__,_|\__,_|_|\___/
 *
 *
 * @title Auction contract
 * @author arod.studio and Fingerprints DAO
 * @dev This contract is used to auction Panopticon collection.
 * @notice This contract implements a Dutch Auction for NFTs (Non-Fungible Tokens).
 * The auction starts at a high price, decreasing over time until a bid is made or
 * a reserve price is reached. Users bid for a quantity of NFTs. They can withdraw
 * their funds after the auction, or claim a refund if conditions are met.
 * Additionally, users can claim additional NFTs using their prospective refunds
 * while the auction is ongoing.
 * The auction can be paused, unpaused, and configured by an admin.
 * Security features like reentrancy guard and overflow/underflow checks.
 *
 * SPDX-License-Identifier: MIT
 */

pragma solidity 0.8.17;

import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";

import "./IDutchAuction.sol";
import "./INFT.sol";

/**
 * @title Dutch Auction Contract
 * @dev This contract manages a dutch auction for NFT tokens. Users can bid,
 * claim refunds, claim tokens, and admins can refund users.
 * The contract is pausable and non-reentrant for safety.
 */
contract DutchAuction is
  IDutchAuction,
  AccessControl,
  Pausable,
  ReentrancyGuard
{
  /// @notice Merkle root hash for discount addresses
  bytes32 public merkleRoot;

  /// @notice NFT contract address
  INFT public nftContractAddress;

  /// @notice Treasury address that will receive funds
  address public treasuryAddress;

  /// @dev Settled Price in wei
  uint256 private _settledPriceInWei;

  /// @dev Auction Config
  Config private _config;

  /// @dev Total minted tokens
  uint16 private _totalMinted;

  /// @dev Funds withdrawn or not
  bool private _withdrawn;

  /// @dev discount value in percentage
  uint16 constant discount = 100; // 10%

  /// @dev counter of discounted nfts sold
  uint16 private _discountedNFTs = 0;

  /// @dev Mapping of user address to User data
  mapping(address => User) private _userData;

  modifier validConfig() {
    if (_config.startTime == 0) revert ConfigNotSet();
    _;
  }

  modifier validTime() {
    Config memory config = _config;
    if (block.timestamp > config.endTime || block.timestamp < config.startTime)
      revert InvalidStartEndTime(config.startTime, config.endTime);
    _;
  }

  /// @notice DutchAuction Constructor
  /// @param _nftAddress NFT contract address
  /// @param _treasuryAddress Treasury address
  constructor(address _nftAddress, address _treasuryAddress) {
    nftContractAddress = INFT(_nftAddress);
    treasuryAddress = _treasuryAddress;

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  /// @notice Change merkle root hash
  function setMerkleRoot(
    bytes32 merkleRootHash
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    merkleRoot = merkleRootHash;
  }

  /// @notice Verify merkle proof of the address
  function verifyAddress(
    bytes32[] calldata _merkleProof,
    address _address
  ) private view returns (bool) {
    if (_merkleProof.length == 0) return false;
    bytes32 leaf = keccak256(abi.encodePacked(_address));
    return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
  }

  function hasDiscount(
    bytes32[] calldata _merkleProof,
    address _address
  ) external view returns (bool) {
    return verifyAddress(_merkleProof, _address);
  }

  /// @notice Set auction config
  /// @dev Only admin can set auction config
  /// @param startAmountInWei Auction start amount in wei
  /// @param endAmountInWei Auction end amount in wei
  /// @param refundDelayTime Delay time which users need to wait to claim refund after the auction ends
  /// @param startTime Auction start time
  /// @param endTime Auction end time
  function setConfig(
    uint256 startAmountInWei,
    uint256 endAmountInWei,
    uint16 refundDelayTime,
    uint64 startTime,
    uint64 endTime
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_config.startTime != 0 && _config.startTime <= block.timestamp)
      revert ConfigAlreadySet();

    if (startTime == 0 || startTime >= endTime)
      revert InvalidStartEndTime(startTime, endTime);
    if (startAmountInWei == 0 || startAmountInWei <= endAmountInWei)
      revert InvalidAmountInWei();

    _settledPriceInWei = endAmountInWei;

    _config = Config({
      startAmountInWei: startAmountInWei,
      endAmountInWei: endAmountInWei,
      refundDelayTime: refundDelayTime,
      startTime: startTime,
      endTime: endTime
    });
  }

  /**
   * @dev Sets the address of the NFT contract.
   *
   * Requirements:
   * - Caller must have the DEFAULT_ADMIN_ROLE.
   * - New address must not be the zero address.
   *
   * @param newAddress The address of the new NFT contract.
   */
  function setNftContractAddress(
    address newAddress
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(
      newAddress != address(0),
      "Invalid address: zero address not allowed"
    );
    nftContractAddress = INFT(newAddress);
  }

  /// @notice Sets treasury address
  /// @param _treasuryAddress New treasury address
  function setTreasuryAddress(
    address _treasuryAddress
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(
      _treasuryAddress != address(0),
      "Invalid address: zero address not allowed"
    );
    treasuryAddress = _treasuryAddress;
  }

  /// @notice Pause the auction
  function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  /// @notice Unpause the auction
  function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  /// @notice Get auction config
  /// @return config Auction config
  function getConfig() external view returns (Config memory) {
    return _config;
  }

  /// @notice Get user data
  /// @param user User address
  /// @return User struct
  function getUserData(address user) external view returns (User memory) {
    return _userData[user];
  }

  /// @notice Get auction's settled price
  /// @return price Auction's settled price
  function getSettledPriceInWei() public view returns (uint256) {
    return _settledPriceInWei;
  }

  /// @notice Get auction's settled price with discount
  /// @return price Auction's settled price with _discount applied
  function getSettledPriceWithDiscountInWei() public view returns (uint256) {
    return _settledPriceInWei - ((_settledPriceInWei * discount) / 1000);
  }

  /// @notice Get auction's current price
  /// @return price Auction's current price
  function getCurrentPriceInWei() public view returns (uint256) {
    Config memory config = _config; // storage to memory
    // Return startAmountInWei if auction not started
    if (block.timestamp <= config.startTime) return config.startAmountInWei;
    // Return endAmountInWei if auction ended
    if (block.timestamp >= config.endTime) return config.endAmountInWei;

    // Declare variables to derive in the subsequent unchecked scope.
    uint256 duration;
    uint256 elapsed;
    uint256 remaining;

    // Skip underflow checks as startTime <= block.timestamp < endTime.
    unchecked {
      // Derive the duration for the order and place it on the stack.
      duration = config.endTime - config.startTime;

      // Derive time elapsed since the order started & place on stack.
      elapsed = block.timestamp - config.startTime;

      // Derive time remaining until order expires and place on stack.
      remaining = duration - elapsed;
    }

    return
      (config.startAmountInWei * remaining + config.endAmountInWei * elapsed) /
      duration;
  }

  /// @notice Make bid to purchase NFTs
  /// @param qty Amount of tokens to purchase
  function bid(
    uint16 qty,
    bytes32[] calldata _merkleProof
  ) external payable nonReentrant whenNotPaused validConfig validTime {
    if (qty < 1) revert InvalidQuantity();

    uint16 available = nftContractAddress.tokenIdMax() -
      nftContractAddress.currentTokenId();

    if (qty > available) {
      revert MaxSupplyReached();
    }

    uint256 price = getCurrentPriceInWei();
    if (msg.value < qty * price) revert NotEnoughValue();

    User storage bidder = _userData[msg.sender]; // get user's current bid total
    bidder.contribution = bidder.contribution + uint216(msg.value);
    bidder.tokensBidded = bidder.tokensBidded + qty;

    _totalMinted += qty;

    // @dev if it's the last bid, set the price as the settled price
    if (qty == available) {
      _settledPriceInWei = price;
    }

    if (verifyAddress(_merkleProof, msg.sender)) {
      _discountedNFTs += qty;
      bidder.tokensBiddedWithDiscount = bidder.tokensBiddedWithDiscount + qty;
    }

    // if (msg.value > payment) {
    //   uint256 refundInWei = msg.value - payment;
    //   (bool success, ) = msg.sender.call{value: refundInWei}("");
    //   if (!success) revert TransferFailed();
    // }
    // mint tokens to user
    _mintTokens(msg.sender, qty);

    emit Bid(msg.sender, qty, price, verifyAddress(_merkleProof, msg.sender));
  }

  /// @notice Return user's claimable tokens count
  /// @param user User address
  /// @return claimable Claimable tokens count
  function getClaimableTokens(
    address user
  ) public view returns (uint32 claimable) {
    User storage bidder = _userData[user]; // get user's current bid total
    uint256 price = getCurrentPriceInWei();
    claimable = uint32(bidder.contribution / price) - bidder.tokensBidded;
    uint16 available = nftContractAddress.tokenIdMax() -
      nftContractAddress.currentTokenId();
    if (claimable > available) claimable = available;
  }

  /// @notice Claim additional NFTs without additional payment
  /// @param amount Number of tokens to claim
  function claimTokens(
    uint16 amount,
    bytes32[] calldata _merkleProof
  ) external nonReentrant whenNotPaused validConfig validTime {
    User storage bidder = _userData[msg.sender]; // get user's current bid total
    uint256 price = getCurrentPriceInWei();
    uint32 claimable = getClaimableTokens(msg.sender);
    if (amount > claimable) amount = uint16(claimable);
    if (amount == 0) revert NothingToClaim();

    uint16 available = nftContractAddress.tokenIdMax() -
      nftContractAddress.currentTokenId();
    bidder.tokensBidded = bidder.tokensBidded + amount;
    _totalMinted += amount;

    if (amount == available) {
      _settledPriceInWei = price;
    }

    if (verifyAddress(_merkleProof, msg.sender)) {
      _discountedNFTs += amount;
      bidder.tokensBiddedWithDiscount =
        bidder.tokensBiddedWithDiscount +
        amount;
    }

    _mintTokens(msg.sender, amount);

    emit Claim(msg.sender, amount, verifyAddress(_merkleProof, msg.sender));
  }

  /// @notice Admin withdraw funds
  /// @dev Only admin can withdraw funds
  function withdrawFunds() external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_config.endTime >= block.timestamp) revert NotEnded();
    if (_withdrawn) revert AlreadyWithdrawn();
    _withdrawn = true;

    uint256 amountWithoutDiscount = (_totalMinted - _discountedNFTs) *
      getSettledPriceInWei();
    uint256 amountWithDiscount = _discountedNFTs *
      getSettledPriceWithDiscountInWei();
    uint256 amount = amountWithoutDiscount + amountWithDiscount;

    (bool success, ) = treasuryAddress.call{value: amount}("");
    if (!success) revert TransferFailed();
  }

  /**
   * @notice Allows a participant to claim their refund after the auction ends.
   * Refund is calculated based on the difference between their contribution and the final settled price.
   * This function can only be called after the refund delay time has passed post-auction end.
   * Note: If the function reverts with 'ClaimRefundNotReady', it means the refund delay time has not passed yet.
   */
  function claimRefund() external nonReentrant whenNotPaused validConfig {
    Config memory config = _config;
    if (config.endTime + config.refundDelayTime >= block.timestamp)
      revert ClaimRefundNotReady();

    _claimRefund(msg.sender);
  }

  /**
   * @notice Admin-enforced claim of refunds for a list of user addresses.
   * This function is identical to `claimRefund` but allows an admin to force
   * users to claim their refund. Can only be called after the refund delay time has passed post-auction end.
   * Only callable by addresses with the DEFAULT_ADMIN_ROLE.
   * Note: If the function reverts with 'ClaimRefundNotReady', it means the refund delay time has not passed yet.
   * @param accounts An array of addresses for which refunds will be claimed.
   */
  function refundUsers(
    address[] memory accounts
  )
    external
    nonReentrant
    whenNotPaused
    validConfig
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    Config memory config = _config;
    if (config.endTime + config.refundDelayTime >= block.timestamp)
      revert ClaimRefundNotReady();

    uint256 length = accounts.length;
    for (uint16 i = 0; i != length; ++i) {
      _claimRefund(accounts[i]);
    }
  }

  /**
   * @dev Internal function for processing refunds.
   * The function calculates the refund as the user's total contribution minus the amount spent on bidding.
   * It then sends the refund (if any) to the user's account.
   * Note: If the function reverts with 'UserAlreadyClaimed', it means the user has already claimed their refund.
   * @param account Address of the user claiming the refund.
   */
  function _claimRefund(address account) internal {
    User storage user = _userData[account];
    if (user.refundClaimed) revert UserAlreadyClaimed();
    user.refundClaimed = true;

    uint256 paidWithoutDiscount = (getSettledPriceInWei() *
      (user.tokensBidded - user.tokensBiddedWithDiscount));
    uint256 paidWithDiscount = (getSettledPriceWithDiscountInWei() *
      user.tokensBiddedWithDiscount);

    uint256 refundInWei = user.contribution -
      (paidWithDiscount + paidWithoutDiscount);

    if (refundInWei > 0) {
      (bool success, ) = account.call{value: refundInWei}("");
      if (!success) revert TransferFailed();
      emit ClaimRefund(account, refundInWei);
    }
  }

  /**
   * @dev Internal function to mint a specified quantity of NFTs for a recipient.
   * This function mints 'qty' number of NFTs to the 'to' address.
   * @param to Recipient address.
   * @param qty Number of NFTs to mint.
   */
  function _mintTokens(address to, uint16 qty) internal {
    for (uint16 i = 0; i != qty; ++i) {
      nftContractAddress.mint(to);
    }
  }
}
