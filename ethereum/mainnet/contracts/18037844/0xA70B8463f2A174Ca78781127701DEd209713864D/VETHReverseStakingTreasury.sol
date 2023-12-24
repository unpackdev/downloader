// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./BackendAgent.sol";
import "./VYToken.sol";
import "./VETHP2P.sol";
import "./VETHRevenueCycleTreasury.sol";
import "./VETHYieldRateTreasury.sol";
import "./RegistrarClient.sol";
import "./AdminGovernanceAgent.sol";
import "./Governable.sol";
import "./RegistrarMigrator.sol";
import "./Registrar.sol";
import "./Router.sol";

contract VETHReverseStakingTreasury is BackendAgent, RegistrarClient, RegistrarMigrator, AdminGovernanceAgent, Governable {

  uint256 private constant MINIMUM_REVERSE_STAKE_AUTOCLOSE = 100000000; // 0.1 gwei
  uint256 private constant MULTIPLIER = 10**18;
  uint256 private constant DAY_IN_SECONDS = 86400;
  bytes private constant ROUTE_SELECTOR = abi.encode(bytes4(keccak256("route()")));
  uint256 private constant BURNACCRUEDVY_CACHE_DURATION = 6 hours;

  // We use this to get around stack too deep errors.
  struct TradeOfferVars {
    uint256 maxInput;
    uint256 ethFee;
    uint256 vyFee;
    uint256 vyOut;
  }

  struct CalcOfferRepayment {
    uint256 effectiveETHPaidOff;
    uint256 excessETH;
    uint256 excessStakedVY;
    uint256 vyToBurn;
    bool isPaidOff;
  }

  struct RestakeVars {
    uint256 newReverseStakeVY;
    uint256 newReverseStakeClaimedYieldETH;
    uint256 newReverseStakeId;
    uint256 startAt;
    uint256 vyToBurn;
    uint256 processingFeeETH;
    uint256 yieldPayout;
    uint256[] reverseStakeIds;
    uint256 vyYieldRate;
  }

  struct MigrateReverseStakeVars {
    address borrowerAddress;
    uint256 stakedVY;
    uint256 originalClaimedYieldETH;
    uint256 currentClaimedYieldETH;
    uint256 yieldRate;
    uint256 startAt;
    uint256 lastPaidAt;
    uint256 previousReverseStakeId;
    uint256 termId;
  }

  uint256 public constant ETH_FEE = 20000000000000000;
  uint256 public constant VY_FEE = 20000000000000000;
  /// @dev 1.020409; Buffer to account for fee
  uint256 public constant OFFER_PRICE_YR_RATIO = 1020409000000000000;
  /// @dev 0.98; 2% left over to account for burn rate over lifespan of offer
  uint256 public constant OFFER_NET_STAKE_RATIO = 980000000000000000;
  uint256 public constant EXPIRES_IN = 30 days;
  uint256 public constant MINIMUM_OFFER_AUTOCLOSE_IN_ETH = 500000000000000; // 0.0005 ETH
  uint256 public constant MAX_RESTAKE_REVERSE_STAKES = 20;

  VETHP2P private _vethP2P;
  VETHRevenueCycleTreasury private _vethRevenueCycleTreasury;
  VYToken private _vyToken;
  VETHYieldRateTreasury private _vethYRT;
  Router private _ethComptroller;
  address private _migration;
  uint256 private _reverseStakeTermsNonce = 0;
  uint256 private _reverseStakesNonce = 0;
  uint256 private _totalClaimedYieldETH = 0;
  uint256 private _maxReverseStakes = 20;
  uint256 private _burnAccruedVYYieldRate;
  uint256 private _burnAccruedVYTimestamp;

  // This contains the mutable reverse stake terms
  struct ReverseStakeTerm {
    uint256 dailyBurnRate;
    uint256 minimumReverseStakeETH;
    uint256 processingFeePercentage;
    uint256 restakeMinimumPayout;
  }

  // This contains reverseStake info per user
  struct ReverseStake {
    uint256 termId;
    uint256 stakedVY;
    uint256 originalClaimedYieldETH;  // No longer used; kept for record-keeping
    uint256 currentClaimedYieldETH;
    uint256 yieldRate;                // No longer used; kept for record-keeping
    uint256 startAt;
    uint256 lastPaidAt;
  }

  struct Offer {
    uint256 unfilledQuantity;
    uint256 price;
    uint256 maxClaimedYieldETH;  // ClaimedYield at the time offer is created
    uint256 maxQuantity;         // Max quantity at the time offer is created
    uint256 expiresAt;
    bool isOpen;
  }

  mapping(uint256 => ReverseStakeTerm) private _reverseStakeTerms;
  mapping(address => mapping(uint256 => ReverseStake)) private _reverseStakes;
  mapping(address => uint256) private _openReverseStakes;
  mapping(address => mapping(uint256 => Offer)) private _offers;

  event CreateReverseStakeTerm(
    uint256 termId,
    uint256 dailyBurnRate,
    uint256 minimumReverseStakeETH,
    uint256 processingFeePercentage,
    uint256 restakeMinimumPayout);
  event CreateReverseStake(
    address borrower,
    uint256 reverseStakeId,
    uint256 termId,
    uint256 stakedVY,
    uint256 originalClaimedYieldETH,
    uint256 currentClaimedYieldETH,
    uint256 yieldRate,
    uint256 startAt);

  event ReturnETHToUnstake(
    address borrower,
    uint256 reverseStakeId,
    uint256 ethAmount,
    uint256 currentClaimedYieldETH,
    uint256 stakedVY,
    uint256 stakedVYReturned,
    uint256 burnRatePaid,
    uint256 paidAt
  );
  event MigrateReverseStake(
    address borrower,
    uint256 reverseStakeId,
    uint256 termId,
    uint256 stakedVY,
    uint256 originalClaimedYieldETH,
    uint256 currentClaimedYieldETH,
    uint256 yieldRate,
    uint256 startAt,
    uint256 previousReverseStakeId
  );
  event CloseReverseStake(address borrower, uint256 reverseStakeId, uint256 stakeTransferred);
  event CreateOffer(address borrower, uint256 reverseStakeId, uint256 quantity, uint256 price, uint256 expiresAt, uint256 timestamp);
  event TradeOffer(
    address borrower,
    uint256 reverseStakeId,
    address buyer,
    uint256 sellerQuantity,
    uint256 buyerQuantity,
    uint256 unfilledQuantity,
    uint256 excessETH,
    uint256 timestamp
  );
  event CloseOffer(address borrower, uint256 reverseStakeId, uint256 timestamp);
  event Restake(
    address borrower,
    uint256 reverseStakeId,
    uint256 stakedVY,
    uint256 originalClaimedYieldETH,
    uint256 currentClaimedYieldETH,
    uint256 yieldRate,
    uint256 startAt,
    uint256 yieldPayout,
    uint256[] previousReverseStakeIds,
    uint256 burnRatePaid,
    uint256 newTermId
  );
  event BurnAccruedVY(
    address borrower,
    uint256 reverseStakeId,
    uint256 stakedVY,
    uint256 burnRatePaid,
    uint256 yieldRate
  );

  constructor(
    address registrarAddress,
    address ethComptrollerAddress_,
    address[] memory adminGovAgents,
    address[] memory backendAdminAgents,
    address[] memory backendAgents,
    address[] memory adminAgents
  ) RegistrarClient(registrarAddress)
    RegistrarMigrator(registrarAddress, uint(Registrar.Contract.VETHReverseStakingTreasury), adminAgents)
    AdminGovernanceAgent(adminGovAgents) {
    require(ethComptrollerAddress_ != address(0), "Invalid address");

    _ethComptroller = Router(payable(ethComptrollerAddress_));
    _setBackendAdminAgents(backendAdminAgents);
    _setBackendAgents(backendAgents);
  }

  modifier onlyActiveReverseStake(address borrower, uint256 reverseStakeId) {
    _checkValidReverseStake(_reverseStakes[borrower][reverseStakeId].startAt > 0);
    _checkActiveReverseStake(isReverseStakeActive(borrower, reverseStakeId));
    _;
  }

  modifier onlyActiveOffer(address borrower, uint256 reverseStakeId) {
    require(_offers[borrower][reverseStakeId].isOpen && _offers[borrower][reverseStakeId].expiresAt > block.timestamp, "Invalid offer");
    _;
  }

  modifier onlyOpenOffer(uint256 id, address borrower) {
    require(_offers[borrower][id].isOpen, "Offer must be open in order to close");
    _;
  }

  function setupInitialReverseStakeTerm(
    uint256 dailyBurnRate,
    uint256 minimumReverseStakeETH,
    uint256 processingFeePercentage,
    uint256 restakeMinimumPayout
  ) external onlyBackendAdminAgents {
    require(_reverseStakeTermsNonce == 0, "Reverse stake terms already set up");
    _createNewReverseStakeTerm(
      dailyBurnRate,
      minimumReverseStakeETH,
      processingFeePercentage,
      restakeMinimumPayout
    );
  }

  function createNewReverseStakeTerm(
    uint256 dailyBurnRate,
    uint256 minimumReverseStakeETH,
    uint256 processingFeePercentage,
    uint256 restakeMinimumPayout
  ) external onlyGovernance {
    _createNewReverseStakeTerm(
      dailyBurnRate,
      minimumReverseStakeETH,
      processingFeePercentage,
      restakeMinimumPayout
    );
  }

  /**
   * @dev Returns total claimed yield in ETH
   */
  function getTotalClaimedYield() external view returns (uint256) {
    return _totalClaimedYieldETH;
  }

  function getReverseStake(address borrower, uint256 reverseStakeId) external view returns (ReverseStake memory) {
    return _reverseStakes[borrower][reverseStakeId];
  }

  function isReverseStakeActive(address borrower, uint256 reverseStakeId) public view returns (bool) {
    return _reverseStakes[borrower][reverseStakeId].currentClaimedYieldETH > 0;
  }

  function isOfferActive(address borrower, uint256 reverseStakeId) external view returns (bool) {
    return _offers[borrower][reverseStakeId].isOpen && _offers[borrower][reverseStakeId].expiresAt > block.timestamp;
  }

  function getReverseStakeTerm(uint256 termId) external view returns (ReverseStakeTerm memory) {
    return _reverseStakeTerms[termId];
  }

  function getCurrentReverseStakeTerm() external view returns (ReverseStakeTerm memory) {
    return _reverseStakeTerms[_reverseStakeTermsNonce];
  }

  function getCurrentReverseStakeTermId() external view returns (uint256) {
    return _reverseStakeTermsNonce;
  }

  function ethToBurn(address borrower, uint256 reverseStakeId) external view returns (uint256) {
    return _ethToBurn(borrower, reverseStakeId);
  }

  function vyToBurn(address borrower, uint256 reverseStakeId) external view returns (uint256) {
    return _vyToBurn(borrower, reverseStakeId);
  }

  function getStakedVYForReverseStakeETH(uint256 ethAmount) external view returns (uint256) {
    return _getStakedVYForReverseStakeETH(ethAmount);
  }

  function getMaxReverseStakes() external view returns (uint256) {
    return _maxReverseStakes;
  }

  function getReverseStakesNonce() external view returns (uint256) {
    return _reverseStakesNonce;
  }

  function getBurnAccruedVYYieldRate() external view returns (uint256) {
    return _burnAccruedVYYieldRate;
  }

  function getBurnAccruedVYTimestamp() external view returns (uint256) {
    return _burnAccruedVYTimestamp;
  }

  function setMaxReverseStakes(uint256 maxReverseStakes_) external onlyBackendAdminAgents {
    _maxReverseStakes = maxReverseStakes_;
  }

  function getMigration() external view returns (address) {
    return _migration;
  }

  function setMigration(address destination) external onlyGovernance {
    _migration = destination;
  }

  function transferMigration(uint256 amount) external onlyAdminGovAgents {
    require(_migration != address(0), "Migration not set");
    _checkSufficientBalance(_vyToken.balanceOf(address(this)) >= amount);
    _transferVY(_migration, amount);
  }

  function createReverseStake(uint256 termId, uint256 ethAmount, uint256 vyAmount) external {
    require(_vyToken.allowance(_msgSender(), address(this)) >= vyAmount, "Insufficient allowance");
    require(_vyToken.balanceOf(_msgSender()) >= vyAmount, "Insufficient balance");
    uint256 minStake = _createReverseStakePrerequisite(termId, ethAmount, vyAmount);

    _createReverseStake(ethAmount, minStake);
  }

  function createReverseStake(uint256 termId, uint256 ethAmount, uint256 vyAmount, uint8 v, bytes32 r, bytes32 s) external {
    uint256 minStake = _createReverseStakePrerequisite(termId, ethAmount, vyAmount);

    // Call approval
    _vyToken.permit(_msgSender(), address(this), vyAmount, v, r, s);
    _createReverseStake(ethAmount, minStake);
  }

  function _createReverseStake(uint256 ethAmount, uint256 stakedVY) private {
    ReverseStakeTerm memory reverseStakeTerm = _reverseStakeTerms[_reverseStakeTermsNonce];
    require(ethAmount >= reverseStakeTerm.minimumReverseStakeETH, "Minimum reverse stake ETH not met");

    uint256 circulation = _vethRevenueCycleTreasury.getVETHCirculation();
    require(_vyToken.balanceOf(address(this)) + stakedVY <= circulation, "Total staked VY cannot exceed circulation");

    uint256 reverseStakeId = ++_reverseStakesNonce;
    uint256 ethComptrollerReceives = ethAmount * reverseStakeTerm.processingFeePercentage / MULTIPLIER;
    uint256 borrowerReceives = ethAmount - ethComptrollerReceives;
    uint256 startAt = block.timestamp;
    uint256 vyYieldRate = _vethRevenueCycleTreasury.getYieldRate();

    _reverseStakes[_msgSender()][reverseStakeId] = ReverseStake(_reverseStakeTermsNonce, stakedVY, ethAmount, ethAmount, vyYieldRate, startAt, 0);
    _openReverseStakes[_msgSender()]++;

    _totalClaimedYieldETH += ethAmount;
    _vyToken.transferFrom(_msgSender(), address(this), stakedVY);
    _vethYRT.reverseStakingTransfer(_msgSender(), borrowerReceives);
    _vethYRT.reverseStakingRoute(address(_ethComptroller), ethComptrollerReceives, ROUTE_SELECTOR);

    emit CreateReverseStake(_msgSender(), reverseStakeId, _reverseStakeTermsNonce, stakedVY, ethAmount, ethAmount, vyYieldRate, startAt);
  }

  function returnETHToUnstake(uint256 reverseStakeId) external payable onlyActiveReverseStake(_msgSender(), reverseStakeId) {
    require(msg.value > 0, "Zero ETH amount sent");
    _checkActiveOffer(_offers[_msgSender()][reverseStakeId].isOpen);

    ReverseStake storage reverseStake = _reverseStakes[_msgSender()][reverseStakeId];
    uint256 vyToBurn_ = _vyToBurn(_msgSender(), reverseStakeId);
    require(reverseStake.stakedVY >= vyToBurn_, "Not enough staked VY to burn");
    reverseStake.stakedVY -= vyToBurn_;

    uint256 excessETH = 0;
    uint256 stakedVYReturned = 0;
    uint256 ethAmount = msg.value;

    if (ethAmount > reverseStake.currentClaimedYieldETH) {
      excessETH = ethAmount - reverseStake.currentClaimedYieldETH;
      ethAmount = reverseStake.currentClaimedYieldETH;
    }

    if (reverseStake.currentClaimedYieldETH == ethAmount) {
      stakedVYReturned = reverseStake.stakedVY;
      _decrementOpenReverseStakesAndCloseOffer(_msgSender(), reverseStakeId, 0);
    } else {
      stakedVYReturned = reverseStake.stakedVY * ethAmount / reverseStake.currentClaimedYieldETH;
    }

    reverseStake.currentClaimedYieldETH -= ethAmount;
    reverseStake.stakedVY -= stakedVYReturned;
    reverseStake.lastPaidAt = block.timestamp;

    _totalClaimedYieldETH -= ethAmount;
    _transferToRevenueCycleTreasury(vyToBurn_);
    _transferVY(_msgSender(), stakedVYReturned);

    _transfer(address(_vethYRT), ethAmount);

    if (excessETH > 0) {
      _transfer(_msgSender(), excessETH);
    }

    emit ReturnETHToUnstake(
      _msgSender(),
      reverseStakeId,
      ethAmount,
      reverseStake.currentClaimedYieldETH,
      reverseStake.stakedVY,
      stakedVYReturned,
      vyToBurn_,
      reverseStake.lastPaidAt
    );
  }

  function restake(uint256[] memory reverseStakeIds) external {
    address borrower = _msgSender();
    require(reverseStakeIds.length > 0 && reverseStakeIds.length <= MAX_RESTAKE_REVERSE_STAKES, "Invalid number of reverseStakes");

    uint256 totalCurrentClaimedYieldETH;
    RestakeVars memory reverseStakeData = RestakeVars(0, 0, 0, 0, 0, 0, 0, new uint256[](reverseStakeIds.length), 0);

    // Sum all VYs to burn and principals + close reverseStakes
    for (uint i = 0; i < reverseStakeIds.length; i++) {
      uint256 reverseStakeId = reverseStakeIds[i];
      reverseStakeData.reverseStakeIds[i] = reverseStakeId;

      // Requirements
      _checkValidReverseStake(_reverseStakes[borrower][reverseStakeId].startAt > 0);
      _checkActiveReverseStake(isReverseStakeActive(borrower, reverseStakeId));
      _checkActiveOffer(_offers[borrower][reverseStakeId].isOpen);

      ReverseStake storage reverseStake = _reverseStakes[borrower][reverseStakeId];

      // Sum VY to burn
      uint256 vyToBurn_ = _vyToBurn(borrower, reverseStakeId); // Calculate VY to burn
      reverseStakeData.vyToBurn += vyToBurn_;

      // Sum principal after VY to burn
      require(reverseStake.stakedVY >= vyToBurn_, "Not enough staked VY to burn");
      uint256 newReverseStakeVY = reverseStake.stakedVY - vyToBurn_;
      reverseStakeData.newReverseStakeVY += newReverseStakeVY;

      // Close reverseStake
      totalCurrentClaimedYieldETH += reverseStake.currentClaimedYieldETH;
      reverseStake.stakedVY = 0;
      reverseStake.currentClaimedYieldETH = 0;
      if (_openReverseStakes[borrower] > 0) {
        _openReverseStakes[borrower]--;
      }
    }

    // Create new reverseStake
    reverseStakeData.vyYieldRate = _vethRevenueCycleTreasury.getYieldRate();
    reverseStakeData.newReverseStakeClaimedYieldETH = reverseStakeData.newReverseStakeVY * MULTIPLIER / reverseStakeData.vyYieldRate; // Calculate new reverseStake principal
    reverseStakeData.newReverseStakeId = ++_reverseStakesNonce;
    reverseStakeData.startAt = block.timestamp;
    _reverseStakes[borrower][reverseStakeData.newReverseStakeId] = ReverseStake(
      _reverseStakeTermsNonce,                            // termId
      reverseStakeData.newReverseStakeVY,                 // stakedVY
      reverseStakeData.newReverseStakeClaimedYieldETH,    // originalClaimedYieldETH
      reverseStakeData.newReverseStakeClaimedYieldETH,    // currentClaimedYieldETH
      reverseStakeData.vyYieldRate,                       // yieldRate
      reverseStakeData.startAt,                           // startAt
      0);                                                 // lastPaidAt
    _openReverseStakes[borrower]++;

    // Update totalClaimedYield
    require(reverseStakeData.newReverseStakeClaimedYieldETH >= totalCurrentClaimedYieldETH, "Restaked reverseStakes must increase in value");
    reverseStakeData.yieldPayout = reverseStakeData.newReverseStakeClaimedYieldETH - totalCurrentClaimedYieldETH;
    _totalClaimedYieldETH += reverseStakeData.yieldPayout;

    // Processing fee
    reverseStakeData.processingFeeETH = reverseStakeData.yieldPayout * _reverseStakeTerms[_reverseStakeTermsNonce].processingFeePercentage / MULTIPLIER;

    // Yield payout
    require(reverseStakeData.yieldPayout >= _reverseStakeTerms[_reverseStakeTermsNonce].restakeMinimumPayout, "Minimum yield payout not met");
    reverseStakeData.yieldPayout -= reverseStakeData.processingFeeETH;

    // Transfers
    _vethYRT.reverseStakingTransfer(borrower, reverseStakeData.yieldPayout);
    _vethYRT.reverseStakingRoute(address(_ethComptroller), reverseStakeData.processingFeeETH, ROUTE_SELECTOR);
    _transferToRevenueCycleTreasury(reverseStakeData.vyToBurn);

    emit Restake(
      borrower,                                           // borrower
      reverseStakeData.newReverseStakeId,                 // reverseStakeId
      reverseStakeData.newReverseStakeVY,                 // stakedVY
      reverseStakeData.newReverseStakeClaimedYieldETH,    // originalClaimedYieldETH
      reverseStakeData.newReverseStakeClaimedYieldETH,    // currentClaimedYieldETH
      reverseStakeData.vyYieldRate,                       // yieldRate
      reverseStakeData.startAt,                           // startAt
      reverseStakeData.yieldPayout,                       // yieldPayout
      reverseStakeData.reverseStakeIds,                   // previousReverseStakeIds
      reverseStakeData.vyToBurn,                          // burnRatePaid
      _reverseStakeTermsNonce                             // newTermId
    );
  }

  function burnAccruedVY(address[] memory borrowers, uint256[] memory reverseStakeIds) external onlyBackendAgents {
    require(borrowers.length == reverseStakeIds.length, "Argument array length mismatch");

    if (block.timestamp > _burnAccruedVYTimestamp + BURNACCRUEDVY_CACHE_DURATION) {
      // Update cache
      _burnAccruedVYYieldRate = _vethRevenueCycleTreasury.getYieldRate();
      _burnAccruedVYTimestamp = block.timestamp;
    }

    uint256 totalVYToBurn;
    for (uint i = 0; i < reverseStakeIds.length; i++) {
      uint256 reverseStakeId = reverseStakeIds[i];
      address borrower = borrowers[i];
      ReverseStake storage reverseStake = _reverseStakes[borrower][reverseStakeId];

      // Requirements
      _checkValidReverseStake(reverseStake.startAt > 0);
      if (!isReverseStakeActive(borrower, reverseStakeId)) {
        continue;
      }

      // Calculate burn using cached yield rate
      uint256 vyToBurn_ = _vyToBurn(borrower, reverseStakeId, _burnAccruedVYYieldRate);
      if (vyToBurn_ == 0) {
        continue;
      }

      uint256 burnRatePaid = vyToBurn_;
      if (reverseStake.stakedVY <= vyToBurn_) {
        burnRatePaid = reverseStake.stakedVY;

        // Before closing make sure reverse stake is still open
        require(reverseStake.stakedVY > 0 && reverseStake.currentClaimedYieldETH > 0, "ReverseStake is already closed");

        // Update total claimed yield as part of closing
        _totalClaimedYieldETH -= reverseStake.currentClaimedYieldETH;

        // Update reverseStake and offer (if any) upon closing
        _decrementOpenReverseStakesAndCloseOffer(borrower, reverseStakeId, reverseStake.stakedVY);
        reverseStake.stakedVY = 0;
        reverseStake.currentClaimedYieldETH = 0;
      } else {
        reverseStake.stakedVY -= vyToBurn_;
        reverseStake.lastPaidAt = block.timestamp;
      }

      totalVYToBurn += burnRatePaid;
      emit BurnAccruedVY(borrower, reverseStakeId, reverseStake.stakedVY, burnRatePaid, _burnAccruedVYYieldRate);
    }

    // Transfer totalVYToBurn outside of loop instead of transferring vyToBurn each time within the for loop.
    // This is to avoid a yield rate change affecting subsequent vyToBurn calculations within the for loop.
    _transferToRevenueCycleTreasury(totalVYToBurn);
  }

  function createOffer(uint256 reverseStakeId, uint256 quantity, uint256 price) external onlyActiveReverseStake(_msgSender(), reverseStakeId) {
    _checkValidQuantity(quantity);
    require(!_offers[_msgSender()][reverseStakeId].isOpen, "Limit one offer per reverseStake");

    ReverseStake memory reverseStake = _reverseStakes[_msgSender()][reverseStakeId];

    // OFFER_NET_STAKE_RATIO
    uint256 vyToBurn_ = _vyToBurn(_msgSender(), reverseStakeId);
    require(reverseStake.stakedVY >= vyToBurn_, "Not enough staked VY");
    uint256 maximumQuantity = (reverseStake.stakedVY - vyToBurn_) * OFFER_NET_STAKE_RATIO / MULTIPLIER;
    require(quantity <= maximumQuantity, "Quantity exceeds limit");

    // We're creating a [VY_ETH] offer:
    // min price = (current claimed yield / (remaining staked VY after burned VY * 0.98)) * 1.020409
    uint256 minPrice = reverseStake.currentClaimedYieldETH * OFFER_PRICE_YR_RATIO / maximumQuantity;
    _checkMinPrice(price >= minPrice);

    // As yieldRate gets lower, actual "price" gets higher due to inversion
    // adjustedYieldRate = yield rate / 1.020409
    uint256 adjustedYieldRate = _vethRevenueCycleTreasury.getYieldRate() * MULTIPLIER / OFFER_PRICE_YR_RATIO;
    require((MULTIPLIER * MULTIPLIER / price) <= adjustedYieldRate, "Price too low");

    // Set offer expiration
    uint256 expiresAt = block.timestamp + EXPIRES_IN;

    // Create offer
    _offers[_msgSender()][reverseStakeId] = Offer(quantity, price, reverseStake.currentClaimedYieldETH, maximumQuantity, expiresAt, true);

    emit CreateOffer(_msgSender(), reverseStakeId, quantity, price, expiresAt, block.timestamp);
  }

  /**
   * @dev This is for other members to trade on the offer the borrower created
   */
  function tradeOffer(address borrower, uint256 reverseStakeId) external payable onlyActiveOffer(borrower, reverseStakeId) {
    _checkValidQuantity(msg.value);

    Offer storage offer = _offers[borrower][reverseStakeId];
    ReverseStake storage reverseStake = _reverseStakes[borrower][reverseStakeId];

    TradeOfferVars memory info;
    info.maxInput = offer.unfilledQuantity * offer.price / MULTIPLIER;
    _checkEnoughAmountToSell(msg.value <= info.maxInput);

    info.ethFee = msg.value * ETH_FEE / MULTIPLIER;
    info.vyFee = msg.value * VY_FEE / offer.price;

    info.vyOut = msg.value * MULTIPLIER / offer.price;

    // Calculate and update reverseStake
    CalcOfferRepayment memory calc = _payReverseStakeVY(
      borrower,
      reverseStakeId,
      info.vyOut,
      offer.maxClaimedYieldETH,
      offer.maxQuantity,
      msg.value - info.ethFee
    );

    // Update offer
    if (!calc.isPaidOff) {
      if (info.vyOut > offer.unfilledQuantity) {
        info.vyOut = offer.unfilledQuantity;
      }
      offer.unfilledQuantity -= info.vyOut;

      // If remaining quantity is low enough, close it out
      // VY_ETH market - converted selling amount in VY to ETH < MINIMUM_OFFER_AUTOCLOSE_IN_ETH
      bool takerCloseout = (offer.unfilledQuantity * offer.price / MULTIPLIER) < MINIMUM_OFFER_AUTOCLOSE_IN_ETH;

      // console.log("unfilledQuantity: %s, takerCloseout: %s, amount: %s", offer.unfilledQuantity, takerCloseout, offer.unfilledQuantity * offer.price / MULTIPLIER);

      if (takerCloseout) {
        // Auto-close when selling amount in ETH < MINIMUM_OFFER_AUTOCLOSE_IN_ETH
        // No need to return VY from offer, since it was reserving
        // the VY directly from borrower's stakedVY pool.
        _closeOffer(borrower, reverseStakeId);
      }
    }

    _totalClaimedYieldETH -= calc.effectiveETHPaidOff;

    // Send out VY fee + VY to burn.
    // Note that we have 2% VY buffer in the staked VY, as
    // the offer can only be created with 98% of staked VY max.
    _transferToRevenueCycleTreasury(info.vyFee + calc.vyToBurn);

    // Send out VY to buyer
    _transferVY(_msgSender(), info.vyOut - info.vyFee);

    // Send out ETH fee
    _ethComptroller.route{ value: info.ethFee }();

    // Send out to VETHYieldRateTreasury
    _transfer(address(_vethYRT), msg.value - calc.excessETH - info.ethFee);
    if (calc.excessETH > 0) {
      // Send excess to borrower
      _transfer(borrower, calc.excessETH);
    }

    if (calc.excessStakedVY > 0) {
      // Return excess VY to borrower (if any) once reverseStake is repaid in full
      _transferVY(borrower, calc.excessStakedVY);
    }

    emit TradeOffer(borrower, reverseStakeId, _msgSender(), info.vyOut, msg.value, offer.unfilledQuantity, calc.excessETH, reverseStake.lastPaidAt);
    emit ReturnETHToUnstake(
      borrower,
      reverseStakeId,
      calc.effectiveETHPaidOff,
      reverseStake.currentClaimedYieldETH,
      reverseStake.stakedVY,
      0,
      calc.vyToBurn,
      reverseStake.lastPaidAt
    );
  }

  /**
   * @dev This is for the borrower to sell their staked VY to other users
   */
  function tradeStakedVY(uint256 reverseStakeId, uint256 offerId, address seller, uint256 amountVY) external onlyActiveReverseStake(_msgSender(), reverseStakeId) {
    _tradeStakedVYPrerequisite(reverseStakeId, amountVY);

    ReverseStake storage reverseStake = _reverseStakes[_msgSender()][reverseStakeId];
    // We are trading on a member's [ETH_VY] offer, so their price will be VY/ETH.
    VETHP2P.Offer memory offer = _vethP2P.getOffer(offerId, seller);
    require(offer.isOpen == true && offer.quantity > 0, "Offer is closed or has zero quantity");

    uint256 vyToBurn_ = _vyToBurn(_msgSender(), reverseStakeId);

    // min price formula = (current claimed yield / remaining staked VY after burned VY) * 1.020409
    // In this case it's actually max price due to inversion.
    uint256 maxPrice = reverseStake.currentClaimedYieldETH * OFFER_PRICE_YR_RATIO / (reverseStake.stakedVY - vyToBurn_);
    maxPrice = MULTIPLIER * MULTIPLIER / maxPrice;
    _checkMinPrice(offer.price <= maxPrice);

    _vyToken.approve(address(_vethP2P), amountVY);

    // Calculate (estimate) and update state first
    VETHP2P.TradeOfferCalcInfo memory calc = _vethP2P.estimateTradeOffer(offerId, seller, amountVY);
    CalcOfferRepayment memory reverseStakeCalcs = _payReverseStakeVY(
      _msgSender(),
      reverseStakeId,
      amountVY,
      reverseStake.currentClaimedYieldETH,
      reverseStake.stakedVY - vyToBurn_,
      calc.amountOut - calc.takerFee
    );

    // This needs to be updated last (but before transfers)
    // as this affects the yield rate.
    _totalClaimedYieldETH -= reverseStakeCalcs.effectiveETHPaidOff;

    // Execute actual swap
    VETHP2P.TradeOfferCalcInfo memory realCalc = _vethP2P.tradeOffer(offerId, seller, amountVY);
    require(calc.amountOut == realCalc.amountOut, "amountOut does not match");

    // Send out funds post-swap
    _transferToRevenueCycleTreasury(reverseStakeCalcs.vyToBurn);

    _transfer(address(_vethYRT), realCalc.amountOut - reverseStakeCalcs.excessETH - realCalc.takerFee);
    if (reverseStakeCalcs.excessETH > 0) {
      // Send excess to borrower
      _transfer(_msgSender(), reverseStakeCalcs.excessETH);
    }

    if (reverseStakeCalcs.excessStakedVY > 0) {
      // Return excess VY to borrower (if any) once reverseStake is repaid in full
      _transferVY(_msgSender(), reverseStakeCalcs.excessStakedVY);
    }

    emit ReturnETHToUnstake(
      _msgSender(),
      reverseStakeId,
      reverseStakeCalcs.effectiveETHPaidOff,
      reverseStake.currentClaimedYieldETH,
      reverseStake.stakedVY,
      0,
      reverseStakeCalcs.vyToBurn,
      reverseStake.lastPaidAt
    );
  }

  function closeOffer(uint256 reverseStakeId) external onlyOpenOffer(reverseStakeId, _msgSender()) {
    _closeOffer(_msgSender(), reverseStakeId);
  }

  function closeOffer(address borrower, uint256 reverseStakeId) external onlyOpenOffer(reverseStakeId, borrower) onlyBackendAgents {
    _closeOffer(borrower, reverseStakeId);
  }

  function getOffer(address borrower, uint256 reverseStakeId) external view returns (Offer memory) {
    return _offers[borrower][reverseStakeId];
  }

  function updateAddresses() external override onlyRegistrar {
    _vethP2P = VETHP2P(_registrar.getVETHP2P());
    _vethRevenueCycleTreasury = VETHRevenueCycleTreasury(_registrar.getVETHRevenueCycleTreasury());
    _vyToken = VYToken(_registrar.getVYToken());
    _vethYRT = VETHYieldRateTreasury(payable(_registrar.getVETHYieldRateTreasury()));
    _updateGovernable(_registrar);
  }

  function _migrateReverseStake(
    address borrowerAddress,
    uint256 stakedVY,
    uint256 originalClaimedYieldETH,
    uint256 currentClaimedYieldETH,
    uint256 yieldRate,
    uint256 startAt,
    uint256 lastPaidAt,
    uint256 previousReverseStakeId,
    uint256 termId
  ) private {
    require(startAt > 0, "Previous reverseStake invalid");

    uint256 reverseStakeId = ++_reverseStakesNonce;
    _reverseStakes[borrowerAddress][reverseStakeId] = ReverseStake(termId, stakedVY, originalClaimedYieldETH, currentClaimedYieldETH, yieldRate, startAt, lastPaidAt);
    _openReverseStakes[borrowerAddress]++;
    _totalClaimedYieldETH += currentClaimedYieldETH;

    emit MigrateReverseStake(borrowerAddress, reverseStakeId, termId, stakedVY, originalClaimedYieldETH, currentClaimedYieldETH, yieldRate, startAt, previousReverseStakeId);
  }

  function migrateReverseStakes(
    MigrateReverseStakeVars[] calldata reverseStakeDataArray
  ) external onlyBackendAgents onlyUnfinalized {
    for (uint i = 0; i < reverseStakeDataArray.length; i++) {
      _migrateReverseStake(
        reverseStakeDataArray[i].borrowerAddress,
        reverseStakeDataArray[i].stakedVY,
        reverseStakeDataArray[i].originalClaimedYieldETH,
        reverseStakeDataArray[i].currentClaimedYieldETH,
        reverseStakeDataArray[i].yieldRate,
        reverseStakeDataArray[i].startAt,
        reverseStakeDataArray[i].lastPaidAt,
        reverseStakeDataArray[i].previousReverseStakeId,
        reverseStakeDataArray[i].termId
      );
    }
  }

  function _createNewReverseStakeTerm(
    uint256 dailyBurnRate,
    uint256 minimumReverseStakeETH,
    uint256 processingFeePercentage,
    uint256 restakeMinimumPayout
  ) private {
    _reverseStakeTerms[++_reverseStakeTermsNonce] = ReverseStakeTerm(
      dailyBurnRate,
      minimumReverseStakeETH,
      processingFeePercentage,
      restakeMinimumPayout
    );

    emit CreateReverseStakeTerm(
      _reverseStakeTermsNonce,
      dailyBurnRate,
      minimumReverseStakeETH,
      processingFeePercentage,
      restakeMinimumPayout
    );
  }

  function _getStakedVYForReverseStakeETH(uint256 ethAmount) private view returns (uint256) {
    uint256 vyYieldRate = _vethRevenueCycleTreasury.getYieldRate();
    return vyYieldRate * ethAmount / MULTIPLIER;
  }

  // rounding down basis, meaning for 11.6 days borrower will burn VY for 11 days
  // we have to account for the case where borrower might pay at 11.6 days and another payment at 20.4 days
  // because 20.4-11.6 = 8.8 days we cannot calculate directly otherwise 11+8 = 19 days of burn rate instead of 20
  // therefore we have to look at the number of days in total minus the number of days borrower has paid
  function _daysElapsed(uint256 startAt, uint256 lastPaidAt) private view returns (uint256) {
    uint256 currentTime = block.timestamp;
    if (lastPaidAt > 0) {
      uint256 daysTotal = (currentTime - startAt) / DAY_IN_SECONDS;
      uint256 daysPaid = (lastPaidAt - startAt) / DAY_IN_SECONDS;
      return daysTotal - daysPaid;
    } else {
      return (currentTime - startAt) / DAY_IN_SECONDS;
    }
  }

  function _ethToBurn(address borrower, uint256 reverseStakeId) private view returns (uint256) {
    ReverseStake memory reverseStake = _reverseStakes[borrower][reverseStakeId];
    ReverseStakeTerm memory reverseStakeTerm = _reverseStakeTerms[reverseStake.termId];
    uint256 daysElapsed = _daysElapsed(reverseStake.startAt, reverseStake.lastPaidAt);

    return reverseStake.currentClaimedYieldETH * reverseStakeTerm.dailyBurnRate * daysElapsed / MULTIPLIER;
  }

  function _vyToBurn(address borrower, uint256 reverseStakeId) private view returns (uint256) {
    uint256 ethToBurn_ = _ethToBurn(borrower, reverseStakeId);
    uint256 vyYieldRate = _vethRevenueCycleTreasury.getYieldRate();

    return ethToBurn_ * vyYieldRate / MULTIPLIER;
  }

  function _vyToBurn(address borrower, uint256 reverseStakeId, uint256 vyYieldRate) private view returns (uint256) {
    uint256 ethToBurn_ = _ethToBurn(borrower, reverseStakeId);
    return ethToBurn_ * vyYieldRate / MULTIPLIER;
  }

  /**
   * @dev Pay off reverseStake by selling staked VY
   */
  function _payReverseStakeVY(address borrower, uint256 reverseStakeId, uint256 vyToTrade, uint256 maxClaimedYieldETH, uint256 maxVY, uint256 amountETH) private returns (CalcOfferRepayment memory) {
    ReverseStake storage reverseStake = _reverseStakes[borrower][reverseStakeId];

    CalcOfferRepayment memory calc;

    // uint256 percentagePaidOff = vyToTrade * MULTIPLIER / maxVY;
    // calc.effectiveETHPaidOff = percentagePaidOff * maxClaimedYieldETH / MULTIPLIER;
    calc.effectiveETHPaidOff = vyToTrade * maxClaimedYieldETH / maxVY;
    if (amountETH > calc.effectiveETHPaidOff) {
      calc.excessETH = amountETH - calc.effectiveETHPaidOff;
    }
    calc.vyToBurn = _vyToBurn(borrower, reverseStakeId);

    // console.log("vyToTrade: %s\npercentagePaidOff: %s\neffectiveETHPaidOff: %s", vyToTrade, percentagePaidOff, calc.effectiveETHPaidOff);
    // console.log("excessETH: %s\nvyToBurn: %s\nstake: %s", calc.excessETH, calc.vyToBurn, reverseStake.stakedVY);
    // console.log("amountETH: %s", amountETH);

    // Update reverseStake
    require(reverseStake.stakedVY >= vyToTrade + calc.vyToBurn, "Not enough staked VY");
    reverseStake.stakedVY -= vyToTrade + calc.vyToBurn;

    // Handle possible precision issues
    if (calc.effectiveETHPaidOff > reverseStake.currentClaimedYieldETH) {
      calc.effectiveETHPaidOff = reverseStake.currentClaimedYieldETH;
    }
    if (reverseStake.currentClaimedYieldETH > calc.effectiveETHPaidOff &&
      (reverseStake.currentClaimedYieldETH - calc.effectiveETHPaidOff <= MINIMUM_REVERSE_STAKE_AUTOCLOSE)) {
      calc.effectiveETHPaidOff = reverseStake.currentClaimedYieldETH;
    }

    // ReverseStake paid off?
    if (calc.effectiveETHPaidOff == reverseStake.currentClaimedYieldETH) {
      calc.isPaidOff = true;
      _decrementOpenReverseStakesAndCloseOffer(borrower, reverseStakeId, 0);

      // If there is any remaining staked VY, record that
      // so we can later return it to borrower.
      if (reverseStake.stakedVY > 0) {
        calc.excessStakedVY = reverseStake.stakedVY;
        reverseStake.stakedVY = 0;
      }
    }

    // Update rest of reverseStake
    reverseStake.currentClaimedYieldETH -= calc.effectiveETHPaidOff;
    reverseStake.lastPaidAt = block.timestamp;

    // console.log("currentClaimedYieldETH: %s, excessStakedVY: %s", reverseStake.currentClaimedYieldETH, calc.excessStakedVY);
    // console.log("stakedVY: %s", reverseStake.stakedVY);

    return calc;
  }

  function _createReverseStakePrerequisite(uint256 termId, uint256 ethAmount, uint256 vyAmount) private view returns (uint256) {
    require(termId == _reverseStakeTermsNonce, "Invalid reverse stake term specified");
    require(_openReverseStakes[_msgSender()] < _maxReverseStakes, "Maximum reverse stakes reached");
    uint256 minStake = _getStakedVYForReverseStakeETH(ethAmount);
    require(vyAmount >= minStake, "vyAmount too low based on yield rate");

    return minStake;
  }

  function _tradeStakedVYPrerequisite(uint256 reverseStakeId, uint256 amountVY) private view {
    _checkValidQuantity(amountVY);
    Offer memory offer = _offers[_msgSender()][reverseStakeId];
    _checkActiveOffer(offer.isOpen);
    ReverseStake memory reverseStake = _reverseStakes[_msgSender()][reverseStakeId];
    uint256 vyToBurn_ = _vyToBurn(_msgSender(), reverseStakeId);
    require(reverseStake.stakedVY >= vyToBurn_, "Not enough staked VY");
    uint256 remainingStake = reverseStake.stakedVY - vyToBurn_;
    _checkEnoughAmountToSell(amountVY <= remainingStake);
  }

  function _transferToRevenueCycleTreasury(uint256 amount) private {
    _transferVY(address(_vethRevenueCycleTreasury), amount);
  }

  function _decrementOpenReverseStakesAndCloseOffer(address borrower, uint256 reverseStakeId, uint256 stakeTransferred) internal {
    if (_openReverseStakes[borrower] > 0) {
      _openReverseStakes[borrower]--;
    }
    if (_offers[borrower][reverseStakeId].isOpen) {
      _closeOffer(borrower, reverseStakeId);
    }
    emit CloseReverseStake(borrower, reverseStakeId, stakeTransferred);
  }

  function _closeOffer(address borrower, uint256 reverseStakeId) internal {
    delete _offers[borrower][reverseStakeId];
    emit CloseOffer(borrower, reverseStakeId, block.timestamp);
  }

  function _transferVY(address recipient, uint256 amount) private {
    if (amount > 0) {
      _vyToken.transfer(recipient, amount);
    }
  }

  function _checkActiveOffer(bool isOpen) private pure {
    require(!isOpen, "Active offer found");
  }

  function _checkMinPrice(bool minPriceMet) private pure {
    require(minPriceMet, "Minimum price not met");
  }

  function _checkValidQuantity(uint256 amount) private pure {
    require(amount > 0, "Invalid quantity");
  }

  function _checkEnoughAmountToSell(bool isEnough) private pure {
    require(isEnough, "Not enough to sell");
  }

  function _checkSufficientBalance(bool isufficient) private pure {
    require(isufficient, "Insufficient balance");
  }

  function _checkValidReverseStake(bool isValid) private pure {
    require(isValid, "Invalid reverseStake");
  }

  function _checkActiveReverseStake(bool isActive) private pure {
    require(isActive, "ReverseStake is not active");
  }

  function _transfer(address recipient, uint256 amount) private {
    (bool sent,) = recipient.call{value: amount}("");
    require(sent, "Failed to send Ether");
  }

  receive() external payable {}
}
