// SPDX-License-Identifier: GPL-3.0-or-later

// ░██╗░░░░░░░██╗░██╗░██╗░░░░░░██████╗░░██╗░░██╗░██╗░░░██╗░███████╗
// ░██║░░██╗░░██║░██║░██║░░░░░░██╔══██╗░╚██╗██╔╝░╚██╗░██╔╝░╚════██║
// ░╚██╗████╗██╔╝░██║░██║░░░░░░██║░░██║░░╚███╔╝░░░╚████╔╝░░░░███╔═╝
// ░░████╔═████║░░██║░██║░░░░░░██║░░██║░░██╔██╗░░░░╚██╔╝░░░██╔══╝░░
// ░░╚██╔╝░╚██╔╝░░██║░███████╗░██████╔╝░██╔╝╚██╗░░░░██║░░░░███████╗
// ░░░╚═╝░░░╚═╝░░░╚═╝░╚══════╝░╚═════╝░░╚═╝░░╚═╝░░░░╚═╝░░░░╚══════╝

// by @matyounatan

// adopted from arod.studio:
// https://github.com/Fingerprints-DAO/maschine-contracts/blob/master/contracts/DutchAuction.sol

import "./Pausable.sol";
import "./ReentrancyGuard.sol";

import "./ISanctionsList.sol";

import "./PresaleMintableMulti.sol";

import "./WildNFTA.sol";

pragma solidity ^0.8.17;

contract WildxyzDutchAuctionMulti is
  PresaleMintableMulti,
  Pausable,
  ReentrancyGuard
{
  /// @dev States for the minter
  enum State {
    Setup, // also "comingsoon"
    Live, // defer to phases for state name
    Complete, // also "soldout"
    Paused // temporary paused state
  }

  enum MintType {
    Promo,
    Mint,
    Claim,
    PublicSale,
    Presale
  }

  struct AuctionInfo {
    uint256 maxSupply;
    uint256 reserveSupply;
    uint256 startTime;
    uint256 endTime;
    uint256 startPrice;
    uint256 restingPrice;
    uint256 refundDelay;
    uint256 maxPerAddress;
    uint256 maxPerAddressPublicSale;
  }

  struct PayInfo {
    uint256 wildRoyalty;
    uint256 royaltyTotal;
    address payable wildWallet;
    address payable artistWallet;
  }

  struct Auction {
    AuctionInfo auctionInfo;
    PayInfo payInfo; 
    uint256 settledPrice;
    uint256 currentTokenId;
    WildNFTA nft;
    uint256 numRefundsProcessed;
    uint256 remainingContribution; // running balance of eth
    uint256 totalContribution; // total amount of eth that flowed into the contract
    uint256 totalPromoMintSupply; // total minted during promo and presale (promo max = reserve)
    uint256 totalAuctionSupply; // total minted during auction (auction max = max - reserve)
  }

  struct User {
    /// @notice The total amount of ETH contributed by the user.
    uint256 contribution;
    /// @notice The total number of tokens minted by the user.
    uint256 tokensMinted;
    /// @notice A flag indicating if the user has claimed a refund.
    bool refundClaimed;
  }

  struct MinterInfo {
    State state;

    uint256 maxSupply;
    uint256 reservedSupply;
    uint256 remainingSupply;
    uint256 totalSupply;

    uint256 startTime;
    uint256 endTime;

    uint256 startPrice;
    uint256 restingPrice;
    uint256 settledPrice;
    uint256 currentPrice;

    uint256 refundDelay;

    uint256 maxPerAddress;
  }

  struct UserInfo {
    uint256 contribution;
    uint256 tokensMinted;
    uint256 usableFunds;
    uint256 refundAmount;
    uint256 claimableTokens;
    bool refundClaimed;
  }

  /// @notice Rounding number for dutch price calculation
  uint256 public precisionDigits = 5;

  // public variables

  mapping(uint256 => Auction) public auctions;
  uint256[] public auctionIds;

  mapping(uint256 => mapping(address => User)) private users; // auctionId => user address => User
  mapping(uint256 =>  address[]) public usersAddresses;

  /// @notice The OFAC sanctions list contract address.
  /// @dev Used to block unsanctioned addresses from minting NFTs.
  ISanctionsList public sanctionsList;

  // events

  /** @dev Emitted when a user claims a refund.
    * @param auctionId The auction ID.
    * @param user The address of the user claiming the refund.
    * @param refundInWei The amount of the refund in Wei.
    */
  event ClaimRefund(uint256 indexed auctionId, address indexed user, uint256 refundInWei);

  /** @dev Emitted when minting nft tokens to a user
    * @param auctionId The auction ID.
    * @param to The address of the user receiving the tokens.
    * @param firstTokenId The first token ID minted.
    * @param quantity The quantity of tokens minted.
    * @param amount The total price of the minted tokens in Wei.
    * @param mintType The type of minting action.
    */
  event TokenMint(uint256 indexed auctionId, address indexed to, uint256 firstTokenId, uint256 quantity, uint256 amount, MintType mintType);

  /// @notice Emitted when given an invalid start price and end price combination
  error InvalidStartEndPrice(uint256 startPrice, uint256 restingPrice);

  error InvalidStartEndTime(uint256 startTime, uint256 endTime);

  error MaxPerAddressExceeded(uint256 auctionId);

  error NothingToClaim(uint256 auctionId);

  error AuctionNotClosed(uint256 auctionId);
  
  error AuctionNotStarted(uint256 auctionId);

  error AlreadyClaimedRefund(uint256 auctionId);

  error ClaimRefundNotReady(uint256 auctionId);

  error CannotWithdrawBeforeAuctionEnd(uint256 auctionId);

  error NoFundsToWithdraw(uint256 auctionId);

  error NotEnoughFunds(uint256 auctionId);

  error AuctionNotFound(uint256 auctionId);

  /// @notice Emitted when amount requested exceeds nft max supply
  error MaxSupplyExceeded(uint256 auctionId);

  error MaxReserveSupplyExceeded(uint256 auctionId);

  /// @notice Emitted when the value provided is not enough for the function
  error InsufficientFunds(uint256 auctionId);

  /// @notice Emitted when failing to withdraw to wallet
  error FailedToWithdraw(uint256 auctionId, string _walletName, address _wallet);

  /// @notice Emitted when given a zero amount
  error ZeroAmount();
  
  /// @notice Emitted when an OFAC sanctioned address tries to interact with a function
  error SanctionedAddress(address to);

  // modifiers

  modifier nonZeroAmount(uint256 _amount) {
    if (_amount < 1) revert ZeroAmount();
    _;
  }

  modifier validAuction(uint256 _auctionId) {
    _validAuction(_auctionId);
    _;
  }

  modifier validSupply(uint256 _auctionId, uint256 _amount) {
    if (_amount < 1) revert ZeroAmount();
    if (_amount > _getRemainingSupply(_auctionId)) revert MaxSupplyExceeded(_auctionId);
    _;
  }

  modifier validPromoSupply(uint256 _auctionId, uint256 _amount) {
    if (_amount < 1) revert ZeroAmount();
    if (auctions[_auctionId].totalPromoMintSupply + _amount > _auctionInfo(_auctionId).reserveSupply) revert MaxReserveSupplyExceeded(_auctionId);
    _;
  }

  modifier onlyAuctionClose(uint256 _auctionId) {
    if (getState(_auctionId) != State.Complete) revert AuctionNotClosed(_auctionId);
    _;
  }
  
  modifier onlyAuctionStarted(uint256 _auctionId) {
    if (block.timestamp < _auctionInfo(_auctionId).startTime) revert AuctionNotStarted(_auctionId);
    _;
  }

  modifier onlyUnsanctioned(address _to) {
      if (sanctionsList.isSanctioned(_to)) revert SanctionedAddress(_to);
      _;
  }

  // constructor

  constructor(IAdminBeaconUpgradeable _adminBeacon, ISanctionsList _sanctions) {
    setAdminBeacon(_adminBeacon);
    sanctionsList = _sanctions;
  }

  function createAuction(
    uint256 _auctionId,
    Auction calldata _auction
  ) public onlyAdmin {
    AuctionInfo memory auctionInfo = _auction.auctionInfo;

    uint256 startTime = auctionInfo.startTime;
    uint256 endTime = auctionInfo.endTime;
    uint256 startPrice = auctionInfo.startPrice;
    uint256 restingPrice = auctionInfo.restingPrice;

    if (startTime >= endTime) revert InvalidStartEndTime(startTime, endTime);
    if (startPrice <= restingPrice) revert InvalidStartEndPrice(startPrice, restingPrice);

    auctions[_auctionId] = _auction;

    // if we had minted any tokens before hand, start at a later token id
    auctions[_auctionId].currentTokenId = _nftTotalSupply(_auctionId);

    // check if auction is already in auctionIds array
    bool found = false;
    for (uint256 i = 0; i < auctionIds.length; i++) {
      if (auctionIds[i] == _auctionId) {
        found = true;
        break;
      }
    }

    if (!found) {
      auctionIds.push(_auctionId);
    }

    _clearAuctionUsers(_auctionId);
  }

  // internal functions

  function _validAuction(uint256 _auctionId) internal view {
    if (address(auctions[_auctionId].nft) == address(0)) revert AuctionNotFound(_auctionId);
  }

  function _auctionInfo(uint256 _auctionId) internal view returns (AuctionInfo memory) {
    return auctions[_auctionId].auctionInfo;
  }

  function _payInfo(uint256 _auctionId) internal view returns (PayInfo memory) {
    return auctions[_auctionId].payInfo;
  }

  function _clearAuctionUsers(uint256 _auctionId) internal {
    // loop through each user address for this auction and reset 'user' mapping
    for (uint256 i = 0; i < usersAddresses[_auctionId].length; i++) {
      address userAddress = usersAddresses[_auctionId][i];
      users[_auctionId][userAddress] = User(0, 0, false);
    }

    // clear usersAddresses array
    delete usersAddresses[_auctionId];
  }

  function _depositAuction(uint256 _auctionId, uint256 _amount) internal {
    auctions[_auctionId].totalContribution += _amount;
    auctions[_auctionId].remainingContribution += _amount;
  }

  function _withdrawAuctionTo(uint256 _auctionId, address _to, uint256 _amount, string memory reason) internal {
    // check balance of auction
    if (_amount > auctions[_auctionId].remainingContribution) revert NotEnoughFunds(_auctionId);

    auctions[_auctionId].remainingContribution -= _amount;

    (bool success, ) = _to.call{value: _amount}('');
    if (!success) revert FailedToWithdraw(_auctionId, reason, _to);
  }

  function _withdrawAuctionToWildAndArtist(uint256 _auctionId) internal virtual {
    // send a fraction of the balance to wild first
    PayInfo memory payInfo = _payInfo(_auctionId);

    uint256 wildRoyalty = payInfo.wildRoyalty;
    uint256 royaltyTotal = payInfo.royaltyTotal;
    address payable wildWallet = payInfo.wildWallet;
    address payable artistWallet = payInfo.artistWallet;

    uint256 profitContribution = auctions[_auctionId].remainingContribution;
    if (profitContribution == 0) revert NoFundsToWithdraw(_auctionId);

    if (wildRoyalty > 0) {
      uint256 amountToSend = (profitContribution * wildRoyalty) / royaltyTotal;
      _withdrawAuctionTo(_auctionId, wildWallet, amountToSend, 'wild');
    }

    // then, send the rest to payee
    _withdrawAuctionTo(_auctionId, artistWallet, auctions[_auctionId].remainingContribution, 'artist');

    auctions[_auctionId].remainingContribution = 0;
  }

  /// @dev Wraps the nft.totalSupply call. Decremented by burning.
  function _nftTotalSupply(uint256 _auctionId) internal view virtual returns (uint256) {
    return auctions[_auctionId].nft.totalSupply();
  }

  /// @dev Wraps the nft.totalMinted call. Never decrements.
  function _nftTotalMinted(uint256 _auctionId) internal view virtual returns (uint256) {
    return auctions[_auctionId].currentTokenId;
  }

  function _getRemainingSupply(uint256 _auctionId) public view returns (uint256) {
    return _auctionInfo(_auctionId).maxSupply - _auctionInfo(_auctionId).reserveSupply - auctions[_auctionId].totalAuctionSupply;
  }

  function _addTotalAuctionMinted(uint256 _auctionId, uint256 _amount) internal {
    auctions[_auctionId].totalAuctionSupply += _amount;
  }

  function _mint(uint256 _auctionId, address _receiver, uint256 _amount, uint256 _price, MintType _mintType) internal {
    Auction storage auction = auctions[_auctionId];

    if (_mintType != MintType.Promo && _mintType != MintType.Presale) {
      // if not promo minting, change to MintType.PublicSale if minting after auction ends
      _mintType = block.timestamp >= auction.auctionInfo.endTime ? MintType.PublicSale : _mintType;
    }

    uint256 mintedTokenId = auction.currentTokenId;
    auction.currentTokenId += _amount;

    // mint tokens to user
    auction.nft.mint(_receiver, _amount);

    emit TokenMint(_auctionId, _receiver, mintedTokenId, _amount, _price, _mintType);
  }

  // function _refundAmount(address _address) internal view returns (uint256) {
  //   User memory user = users[_address];
  //   return user.contribution - (settledPrice * user.tokensMinted);
  // }

  function _usableFunds(uint256 _auctionId, address _address) internal view returns (uint256) {
    User memory user = users[_auctionId][_address];
    return user.contribution - (_getCurrentPrice(_auctionId) * user.tokensMinted);
  }

  /**
   * @dev Internal function for processing refunds.
   * The function calculates the refund as the user's total contribution minus the amount spent on minting.
   * It then sends the refund (if any) to the user's account.
   * Note: If the function reverts with 'UserAlreadyClaimed', it means the user has already claimed their refund.
   * @param _address Address of the user claiming the refund.
   */
  function _claimRefund(uint256 _auctionId, address _address) internal {
    User storage user = users[_auctionId][_address];
    Auction storage auction = auctions[_auctionId];

    if (user.refundClaimed) revert AlreadyClaimedRefund(_auctionId);

    user.refundClaimed = true;
    auction.numRefundsProcessed++;

    uint256 refundAmount = _usableFunds(_auctionId, _address);
    if (refundAmount > 0) {
      _withdrawAuctionTo(_auctionId, _address, refundAmount, 'refund');

      emit ClaimRefund(_auctionId, _address, refundAmount);
    }
  }

  function _checkAllRefundsProcessed(uint256 _auctionId) internal view returns (bool) {
    Auction memory auction = auctions[_auctionId];
    return usersAddresses[_auctionId].length == auction.numRefundsProcessed;
  }

  function _getCurrentPrice(uint256 _auctionId) internal view returns (uint256) {

    Auction memory auction = auctions[_auctionId];
    AuctionInfo memory auctionInfo = auction.auctionInfo;

    if (_getRemainingSupply(_auctionId) == 0) return auction.settledPrice;

    if (block.timestamp <= auctionInfo.startTime) return auctionInfo.startPrice;

    if (block.timestamp >= auctionInfo.endTime) {
      if (_getRemainingSupply(_auctionId) > 0) {
        // not sold out yet, return resting price
        return auctionInfo.restingPrice;
      } else {
        // sold out, return settled price
        return auction.settledPrice;
      }
    }

    // Declare variables to derive in the subsequent unchecked scope.
    uint256 duration;
    uint256 elapsed;
    uint256 remaining;

    // Skip underflow checks as startTime <= block.timestamp < endTime.
    unchecked {
      // Derive the duration for the order and place it on the stack.
      duration = auctionInfo.endTime - auctionInfo.startTime;

      // Derive time elapsed since the order started & place on stack.
      elapsed = block.timestamp - auctionInfo.startTime;

      // Derive time remaining until order expires and place on stack.
      remaining = duration - elapsed;
    }

    uint256 price = (auctionInfo.startPrice * remaining + auctionInfo.restingPrice * elapsed) / duration;
    uint256 divider = 10 ** (18 - precisionDigits);
    return uint256(price / divider) * divider;
  }

  function _getMaxPerAddress(uint256 _auctionId) internal view returns (uint256) {
    AuctionInfo memory auctionInfo = _auctionInfo(_auctionId);

    if (block.timestamp >= auctionInfo.endTime && _getRemainingSupply(_auctionId) > 0) {
      return auctionInfo.maxPerAddressPublicSale;
    } else {
      return auctionInfo.maxPerAddress;
    }
  }

  function _isRefundClaimable(uint256 _auctionId) internal view returns (bool) {
    AuctionInfo memory auctionInfo = _auctionInfo(_auctionId);
    return auctionInfo.endTime + auctionInfo.refundDelay < block.timestamp || _getRemainingSupply(_auctionId) == 0;
  }

  // public functions

  /** @notice Get the current minter state.
    * @dev Returns the current minter state.
    * @param _auctionId The auction ID.
    * @return state Minter state (0 = Setup, 1 = Live, 2 = Complete, 3 = Paused).
    */
  function getState(uint256 _auctionId) public view virtual returns (State) {
    if (paused()) {
      return State.Paused;
    }

    // if nft not set on auction return Setup state
    if (address(auctions[_auctionId].nft) == address(0)) {
      return State.Setup;
    }

    AuctionInfo memory auctionInfo = _auctionInfo(_auctionId);
    
    // if sold out, return Complete state
    if (_getRemainingSupply(_auctionId) == 0) {
      return State.Complete;
    }

    if (block.timestamp >= auctionInfo.startTime) {
      return State.Live;
    }
    
    return State.Setup;
  }

  function numAuctions() external view returns (uint256) {
    return auctionIds.length;
  }

  function getCurrentPrice(uint256 _auctionId) external view returns (uint256) {
    return _getCurrentPrice(_auctionId);
  }

  function getUser(uint256 _auctionId, address _user) external view returns (User memory) {
    return users[_auctionId][_user];
  }

  function getSettledPrice(uint256 _auctionId) external view returns (uint256) {
    return auctions[_auctionId].settledPrice;
  }

  function getRemainingSupply(uint256 _auctionId) public view returns (uint256) {
    return _getRemainingSupply(_auctionId);
  }

  /** @notice Return user's claimable tokens count
    * @param _user User address
    * @return claimable Claimable tokens count
    */
  function getClaimableTokens(uint256 _auctionId, address _user) public view returns (uint256 claimable) {
    User storage user = users[_auctionId][_user]; // get user's current bid total
    uint256 maxPerAddress = _getMaxPerAddress(_auctionId);

    if (user.refundClaimed || user.tokensMinted >= maxPerAddress) return 0;

    uint256 price = _getCurrentPrice(_auctionId);
    uint256 available = _getRemainingSupply(_auctionId);

    if (price == 0) return available;

    claimable = uint256(user.contribution / price) - user.tokensMinted;

    if (claimable > available) claimable = available;
    if (claimable > maxPerAddress - user.tokensMinted) claimable = maxPerAddress - user.tokensMinted;
  
  }

  /** @notice Mint to purchase NFTs
    * @param _amount Amount of tokens to purchase
    */
  function mint(uint256 _auctionId, uint256 _amount)
    external payable
    onlyUnsanctioned(msg.sender)
    nonReentrant
    whenNotPaused
    validAuction(_auctionId)
    onlyAuctionStarted(_auctionId)
  {
    if (_amount < 1) revert ZeroAmount();
    if (_amount > _getRemainingSupply(_auctionId)) revert MaxSupplyExceeded(_auctionId);

    User storage user = users[_auctionId][msg.sender];
    Auction storage auction = auctions[_auctionId];

    // if user was not set previously then add to userAddresses
    if (user.contribution == 0) {
      usersAddresses[_auctionId].push(msg.sender);
    }

    if (user.tokensMinted + _amount > _getMaxPerAddress(_auctionId)) revert MaxPerAddressExceeded(_auctionId);

    uint256 price = _getCurrentPrice(_auctionId);
    uint256 payment = _amount * price;

    if (msg.value < payment) revert InsufficientFunds(_auctionId);

    user.contribution = user.contribution + payment;
    user.tokensMinted = user.tokensMinted + _amount;

    // record eth sent in
    auctions[_auctionId].totalContribution += payment;
    auctions[_auctionId].remainingContribution += msg.value;
    // _depositAuction(_auctionId, payment);

    // record total minted during auction
    _addTotalAuctionMinted(_auctionId, _amount);

    //if (user.contribution > _config.limitInWei) revert PurchaseLimitReached(); // no purchase limit

    // settledPrice is always the minimum price of all the bids' unit price
    if (price < auction.settledPrice || auction.settledPrice == 0) {
      auction.settledPrice = price;
    }

    uint256 refundAmount = 0;
    if (msg.value > payment) {
      refundAmount = msg.value - payment;

      _withdrawAuctionTo(_auctionId, msg.sender, refundAmount, 'overpayment');
    }

    _mint(_auctionId, msg.sender, _amount, msg.value - refundAmount, MintType.Mint);
  }

  /** @notice Claim additional NFTs without additional payment
    * @param _amount Number of tokens to claim
    */
  function claimTokens(uint256 _auctionId, uint256 _amount)
    external
    onlyUnsanctioned(msg.sender)
    nonReentrant
    whenNotPaused
    validAuction(_auctionId)
    validSupply(_auctionId, _amount)
  {
    User storage user = users[_auctionId][msg.sender];
    Auction storage auction = auctions[_auctionId];

    uint256 price = _getCurrentPrice(_auctionId);
    uint256 claimable = getClaimableTokens(_auctionId, msg.sender);

    if (_amount > claimable) _amount = claimable;
    if (_amount == 0) revert NothingToClaim(_auctionId);

    user.tokensMinted = user.tokensMinted + _amount;

    _addTotalAuctionMinted(_auctionId, _amount);

    // _settledPriceInWei is always the minimum price of all the mints unit price
    if (price < auction.settledPrice) {
      auction.settledPrice = price;
    }

    _mint(_auctionId, msg.sender, _amount, price * _amount, MintType.Claim);
  }

  /**
   * @notice Allows a participant to claim their refund after the auction ends.
   * Refund is calculated based on the difference between their contribution and the final settled price.
   * This function can only be called after the refund delay time has passed post-auction end.
   * Note: If the function reverts with 'ClaimRefundNotReady', it means the refund delay time has not passed yet.
   */
  function claimRefund(uint256 _auctionId)
    external
    onlyUnsanctioned(msg.sender)
    nonReentrant
    whenNotPaused
    validAuction(_auctionId)
  {
    if (!_isRefundClaimable(_auctionId)) revert ClaimRefundNotReady(_auctionId);

    _claimRefund(_auctionId, msg.sender);
  }

  function getMinterInfo(uint256 _auctionId) public view returns (MinterInfo memory) {
    Auction memory auction = auctions[_auctionId];
    AuctionInfo memory auctionInfo = auction.auctionInfo;

    return MinterInfo(
      getState(_auctionId),
      auctionInfo.maxSupply,
      auctionInfo.reserveSupply,
      _getRemainingSupply(_auctionId),
      _nftTotalMinted(_auctionId),
      auctionInfo.startTime,
      auctionInfo.endTime,
      auctionInfo.startPrice,
      auctionInfo.restingPrice,
      auction.settledPrice,
      _getCurrentPrice(_auctionId),
      auctionInfo.refundDelay,
      _getMaxPerAddress(_auctionId)
    );
  }

  function getUserInfo(uint256 _auctionId, address _user) public view returns (UserInfo memory) {
    User memory user = users[_auctionId][_user];

    return UserInfo(
      user.contribution,
      user.tokensMinted,
      _usableFunds(_auctionId, _user),
      _usableFunds(_auctionId, _user),
      getClaimableTokens(_auctionId, _user),
      user.refundClaimed
    );
  }

  function getUserMinterInfo(uint256 _auctionId, address _user) public view returns (UserInfo memory userInfo, MinterInfo memory minterInfo) {
    userInfo = getUserInfo(_auctionId, _user);
    minterInfo = getMinterInfo(_auctionId);
  }

  /**
   * @notice Admin-enforced claim of refunds for a list of user addresses.
   * This function is identical to `claimRefund` but allows an admin to force
   * users to claim their refund. Can only be called after the refund delay time has passed post-auction end.
   * Note: If the function reverts with 'ClaimRefundNotReady', it means the refund delay time has not passed yet.
   * @param _addresses An array of addresses for which refunds will be claimed.
   */
  function refundUsers(uint256 _auctionId, address[] memory _addresses) external nonReentrant whenNotPaused onlyAdmin validAuction(_auctionId) {
    if (!_isRefundClaimable(_auctionId)) revert ClaimRefundNotReady(_auctionId);

    for (uint256 i = 0; i < _addresses.length; i++) {
      _claimRefund(_auctionId, _addresses[i]);
    }
  }

  function refundAllUsers(uint256 _auctionId) external nonReentrant whenNotPaused onlyAdmin validAuction(_auctionId) {
    if (!_isRefundClaimable(_auctionId)) revert ClaimRefundNotReady(_auctionId);

    for (uint256 i = 0; i < usersAddresses[_auctionId].length; i++) {
      address userAddress = usersAddresses[_auctionId][i];

      if (!users[_auctionId][userAddress].refundClaimed) {
        _claimRefund(_auctionId, userAddress);
      }
    }
  }

  function withdraw(uint256 _auctionId) public virtual nonReentrant onlyAdmin validAuction(_auctionId) onlyAuctionClose(_auctionId) {
    if (!_checkAllRefundsProcessed(_auctionId)) revert ClaimRefundNotReady(_auctionId);

    _withdrawAuctionToWildAndArtist(_auctionId);
  }

  function unsafeWithdraw(uint256 _auctionId, uint256 _amount)
    public virtual
    nonReentrant
    onlyAdmin
    validAuction(_auctionId)
    onlyAuctionClose(_auctionId)
    nonZeroAmount(_amount)
  {
    address payable wildWallet = _payInfo(_auctionId).wildWallet;

    _withdrawAuctionTo(_auctionId, wildWallet, _amount, 'wild');
  }

  function unsafeWithdrawAllTo(address _to) public virtual nonReentrant onlyAdmin {
    for (uint256 i = 0; i < auctionIds.length; i++) {
      uint256 auctionId = auctionIds[i];

      // set remaining to 0
      auctions[auctionId].remainingContribution = 0;
    }

    (bool success, ) = _to.call{value: address(this).balance}('');
    if (!success) revert FailedToWithdraw(0, 'wild', _to);
  }

  // only admin

  function promoMint(uint256 _auctionId, address _receiver, uint256 _amount)
    external
    nonReentrant
    onlyAdmin
    validAuction(_auctionId)
    validPromoSupply(_auctionId, _amount)
  {
    _mint(_auctionId, _receiver, _amount, 0, MintType.Promo);

    auctions[_auctionId].totalPromoMintSupply += _amount;
  }

  function setSanctionsList(ISanctionsList _sanctionsList) external onlyAdmin {
    sanctionsList = _sanctionsList;
  }

  function setWildRoyalty(uint256 _auctionId, uint256 _wildRoyalty) external onlyAdmin validAuction(_auctionId) {
    auctions[_auctionId].payInfo.wildRoyalty = _wildRoyalty;
  }

  function setWildWallet(uint256 _auctionId, address payable _wildWallet) external onlyAdmin validAuction(_auctionId) {
    auctions[_auctionId].payInfo.wildWallet = _wildWallet;
  }

  function setArtistWallet(uint256 _auctionId, address payable _artistWallet) external onlyAdmin validAuction(_auctionId) {
    auctions[_auctionId].payInfo.artistWallet = _artistWallet;
  }

  function setStartTime(uint256 _auctionId, uint256 _startTime) external onlyAdmin validAuction(_auctionId) {
    AuctionInfo storage auctionInfo = auctions[_auctionId].auctionInfo;

    if (_startTime >= auctionInfo.endTime) revert InvalidStartEndTime(_startTime, auctionInfo.endTime);
    auctionInfo.startTime = _startTime;
  }

  function setEndTime(uint256 _auctionId, uint256 _endTime) external onlyAdmin validAuction(_auctionId) {
    AuctionInfo storage auctionInfo = auctions[_auctionId].auctionInfo;

    if (_endTime <= auctionInfo.startTime) revert InvalidStartEndTime(auctionInfo.startTime, _endTime);
    auctionInfo.endTime = _endTime;
  }

  function setStartPrice(uint256 _auctionId, uint256 _startPrice) external onlyAdmin validAuction(_auctionId) {
    AuctionInfo storage auctionInfo = auctions[_auctionId].auctionInfo;

    if (_startPrice <= auctionInfo.restingPrice) revert InvalidStartEndPrice(_startPrice, auctionInfo.restingPrice);
    auctionInfo.startPrice = _startPrice;
  }

  function setRestingPrice(uint256 _auctionId, uint256 _restingPrice) external onlyAdmin validAuction(_auctionId) {
    AuctionInfo storage auctionInfo = auctions[_auctionId].auctionInfo;

    if (_restingPrice >= auctionInfo.startPrice) revert InvalidStartEndPrice(auctionInfo.startPrice, _restingPrice);
    auctionInfo.restingPrice = _restingPrice;
  }

  function setRefundDelayTime(uint256 _auctionId, uint256 _refundDelayTime) external onlyAdmin validAuction(_auctionId) {
    auctions[_auctionId].auctionInfo.refundDelay = _refundDelayTime;
  }

  function setMaxPerAddress(uint256 _auctionId, uint256 _maxPerAddress) external onlyAdmin validAuction(_auctionId) {
    auctions[_auctionId].auctionInfo.maxPerAddress = _maxPerAddress;
  }

  function setMaxPerAddressPublicSale(uint256 _auctionId, uint256 _maxPerAddress) external onlyAdmin validAuction(_auctionId) {
    auctions[_auctionId].auctionInfo.maxPerAddressPublicSale = _maxPerAddress;
  }

  function setNFT(uint256 _auctionId, WildNFTA _nft) external onlyAdmin validAuction(_auctionId) {
    auctions[_auctionId].nft = _nft;
  }

  function setCurrentTokenId(uint256 _auctionId, uint256 _currentTokenId) external onlyAdmin validAuction(_auctionId) {
    auctions[_auctionId].currentTokenId = _currentTokenId;
  }

  function setPrecisionDigits(uint256 _precisionDigits) external onlyAdmin {
    precisionDigits = _precisionDigits;
  }

  function setReserveSupply(uint256 _auctionId, uint256 _reserveSupply) external onlyAdmin validAuction(_auctionId) {
    auctions[_auctionId].auctionInfo.reserveSupply = _reserveSupply;
  }

  // function pause() external onlyAdmin {
  //   _pause();
  // }

  // function unpause() external onlyAdmin {
  //   _unpause();
  // }

  // presalemintable

  function presaleMint(uint256 _id, address _receiver, uint256 _amount)
    external payable virtual override
    onlySecondaryMinter
    validAuction(_id)
    validPromoSupply(_id, _amount)
  {
    _mint(_id, _receiver, _amount, msg.value, MintType.Presale);

    _depositAuction(_id, msg.value);

    auctions[_id].totalPromoMintSupply += _amount;
  }

  // per auction deposit

  function deposit(uint256 _auctionId) external payable virtual validAuction(_auctionId) {
    _depositAuction(_auctionId, msg.value);
  }

  // generic deposit

  receive() external payable {}
}