// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// Structs
import "./Structs.sol";

/// Utils /////
import "./BaseChecker.sol";
import "./Ownable.sol";

//Interfaces
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IFyde.sol";
import "./IGovernanceModule.sol";
import "./IOracle.sol";
import "./IRelayer.sol";

///@title PooledDepositEscrow
///@notice The purpose of this contract is to pool assets from different users to be deposited into
/// fyde at
/// once in order to bootstrap the pool and/or save deposit taxes.
///@dev Following flow -> owner deploys Escrow with whitelisted assets/govAssets -> owner whitelists
/// users -> user deposit assets with/without governance -> escrow period is over and deposits are
/// disabled, start of freeze period -> owner decides how much of the deposited assets they want to
/// keep (setConcentrations) -> freeze period ends -> depositToFyde() requestDeposits on the relayer
/// to transfer funds into fyde (works in batches of 5 assets, has to be called multiple times due
/// to gas limitations) -> wait until fyde has processed transactions -> updateInternalAccounting
/// gets the correct TRSY price after calculated by gelato -> user claim assets, gets TRSY sTRSY and
/// refunds (can claim whenever they want)
/// REVOKE: If owner decides that something is wrong after escrow period, can revoke. Users can then
/// get 100% of deposits refunded
contract PooledDepositEscrow is Ownable, BaseChecker {
  using SafeERC20 for IERC20;

  error CannotClaimForAsset(address);
  error EscrowPeriodEnded();
  error InvalidTimePeriod();
  error InsufficientBalance(address);
  error OnlyDuringFreeze();
  error FydeDepositCompleted();
  error FydeDepositNotCompleted();
  error Revoked();
  error NotRevoked();
  error NotSupportedAsset(address);
  error InternalAccountingNotUpdated();
  error DepositsMightStillBeProcessed();
  error ConcentrationsNotSet();
  error TaxFactorNotZero();
  error PriceNotAvailable(address asset);

  ///@notice Used for precision of division
  uint256 constant SCALING_FACTOR = 1e18;

  ///@notice Max number assets accepted in one request
  uint128 public constant MAX_ASSET_TO_REQUEST = 5;

  ///@notice max gas required for deposit, should correspondent to gov deposit of 5 assets + proxy
  /// creation
  uint128 public constant GAS_TO_FORWARD = 2e6;

  ///@notice timestamp until which users can deposit
  uint128 public immutable ESCROW_PERIOD;

  ///@notice timestamp until owner can set concentrations or revoke
  uint128 public immutable FREEZE_PERIOD;

  ///@notice fyde interface
  IFyde public immutable FYDE;
  ///@notice relayer interface
  IRelayer public immutable RELAYER;
  ///@notice governance module interface
  IGovernanceModule public immutable GOVERNANCE_MODULE;
  ///@notice oracle module interface
  IOracle public immutable ORACLE;

  /// -----------------------------
  ///         Storage
  /// -----------------------------

  // bools used to ensure actions are called in correct order

  ///@notice owner has set concentration
  bool public concentrationsSet;
  ///@notice requested deposit on relayer for all assets
  bool public fydeDepositCompleted;
  ///@notice owner has abborted escrow process
  bool public revoked;
  ///@notice trsy price updated after deposits are processed
  bool public internalAccountingUpdated;
  ///@notice amount of assets deposited to fyde (since done in multiple tx)
  uint256 public assetsTransferred;
  ///@notice measure of expected TRSY when requesting depositing, rescaled to correct value
  uint256 public totalExpectedTrsy;
  ///notice assets allowed for deposit
  address[] public assets;

  ///@dev splits slot into uint128 for std and gov deposit values
  struct Slot {
    uint128 std;
    uint128 gov;
  }

  ///@notice user authorization, can use deposit
  mapping(address => bool) public isUser;

  ///@notice is asset allowed in escrow
  mapping(address => bool) public supportedAssets;
  ///@notice is asset allowed in governance
  mapping(address => bool) public keepGovAllowed;
  ///@notice total token balance in escrow
  mapping(address => Slot) public totalBalance;
  ///@notice amount of token to be deposited into fyde (chosen by escrow owner)
  mapping(address => Slot) public concentrationAmounts;
  ///@notice token amount accepted for fyde / amount deposited into escrow
  mapping(address => Slot) public finalPercentages;
  ///@notice TRSY received for each asset
  mapping(address => Slot) public TRSYBalancesPerAsset;
  ///@notice escrow deposits per user and asset;
  mapping(address => mapping(address => Slot)) public deposits;

  /// -----------------------------
  ///         Events
  /// -----------------------------

  event AssetDeposited(address indexed account, address indexed asset, uint256 amount);
  event ClaimedAndRefunded(address indexed account);
  event ConcentrationAmountsSet(uint128[] amounts, uint128[] govAmounts);
  event FydeDeposit();
  event Refunded(address indexed account, address indexed asset, uint256 refund);
  event EscrowRevoked();
  event InternalAccountingUpdated();

  ///@notice Deploys escrow and sets the assets for deposit and the timing for the scrow.
  ///@param _assets Addresses of whitelisted assets
  ///@param _keepGovAllowed is asset whitelisted for gov deposit true/false
  ///@param _fyde Address of fyde contract
  ///@param _relayer Address of relayer contract
  ///@param _governanceModule Address of governance Module contract
  ///@param _oracle Address of oracle module contract
  ///@param _escrowPeriod length of escrow period in seconds after depoyment
  ///@param _freezePeriod length of freeze period in seconds after freeze period
  constructor(
    address[] memory _assets,
    bool[] memory _keepGovAllowed,
    address _fyde,
    address _relayer,
    address _governanceModule,
    address _oracle,
    uint128 _escrowPeriod,
    uint128 _freezePeriod
  ) Ownable(msg.sender) {
    if (_assets.length != _keepGovAllowed.length) revert InconsistentLengths();

    FYDE = IFyde(_fyde);
    RELAYER = IRelayer(_relayer);
    GOVERNANCE_MODULE = IGovernanceModule(_governanceModule);
    ORACLE = IOracle(_oracle);

    ESCROW_PERIOD = uint128(block.timestamp) + _escrowPeriod;
    FREEZE_PERIOD = ESCROW_PERIOD + _freezePeriod;

    assets = _assets;

    // Activate supported assets
    for (uint256 i = 0; i < _assets.length; ++i) {
      supportedAssets[_assets[i]] = true;
      if (_keepGovAllowed[i]) keepGovAllowed[_assets[i]] = true;
    }
  }

  ///@notice Adds users to whitelist of allwoed depositors
  ///@param _user addresses to whitelist
  function addUser(address[] calldata _user) external onlyOwner {
    for (uint256 i; i < _user.length; ++i) {
      isUser[_user[i]] = true;
    }
  }

  ///@notice Removes users from whitelist
  ///@param _user addresses to remove from
  function removeUser(address[] calldata _user) external onlyOwner {
    for (uint256 i; i < _user.length; ++i) {
      isUser[_user[i]] = false;
    }
  }

  ///@notice Deposits asset into escrow
  ///@param asset Asset to deposit
  ///@param amount Amount to deposit
  ///@param keepGovRights standard or governance deposit
  function deposit(address asset, uint128 amount, bool keepGovRights) external onlyUser {
    if (amount == 0) revert ZeroParameter();
    if (uint128(block.timestamp) > ESCROW_PERIOD) revert EscrowPeriodEnded();
    if ((keepGovRights && !keepGovAllowed[asset]) || !supportedAssets[asset]) {
      revert NotSupportedAsset(asset);
    }
    IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
    if (keepGovRights) {
      deposits[msg.sender][asset].gov += amount;
      totalBalance[asset].gov += amount;
    } else {
      deposits[msg.sender][asset].std += amount;
      totalBalance[asset].std += amount;
    }

    emit AssetDeposited(msg.sender, asset, amount);
  }

  ///@notice Sets amount of tokens to accept into fyde
  ///@param amounts Amount of tokens for standard deposit
  ///@param govAmounts Amount of tokens for governance deposit
  ///@dev inputs have to be of same length and order as storage variable assets
  function setConcentrationAmounts(uint128[] calldata amounts, uint128[] calldata govAmounts)
    external
    onlyOwner
  {
    if (amounts.length != assets.length || govAmounts.length != assets.length) {
      revert InconsistentLengths();
    }
    uint128 time = uint128(block.timestamp);
    if (time < ESCROW_PERIOD || time > FREEZE_PERIOD) revert InvalidTimePeriod();
    for (uint256 i = 0; i < amounts.length; ++i) {
      address asset = assets[i];

      uint128 assetAmount = amounts[i];
      uint128 govAmount = govAmounts[i];

      if (assetAmount == 0 && govAmount == 0) continue;

      uint128 balance = totalBalance[asset].std;
      uint128 govBalance = totalBalance[asset].gov;

      if (assetAmount > balance || govAmount > govBalance) revert InsufficientBalance(asset);

      if (assetAmount != 0) {
        finalPercentages[asset].std =
          uint128(uint256(assetAmount) * SCALING_FACTOR / uint256(balance));
        concentrationAmounts[asset].std = assetAmount;
      }

      if (govAmount != 0) {
        finalPercentages[asset].gov =
          uint128(uint256(govAmount) * SCALING_FACTOR / uint256(govBalance));
        concentrationAmounts[asset].gov = govAmount;
      }
    }
    concentrationsSet = true;
    emit ConcentrationAmountsSet(amounts, govAmounts);
  }

  ///@notice Requests deposit of assets into fyde
  ///@dev due to gas limitations deposits a maximum of 5 assets with and without governance, has to
  /// be called multiple times until all assets are transferred
  function depositToFyde() external payable {
    if (uint128(block.timestamp) <= FREEZE_PERIOD) revert InvalidTimePeriod();
    if (!concentrationsSet) revert ConcentrationsNotSet();
    if (fydeDepositCompleted) revert FydeDepositCompleted();
    if (revoked) revert Revoked();
    (, uint72 taxFactor,,,,) = FYDE.protocolData();
    if (taxFactor != 0) revert TaxFactorNotZero();

    address[] memory assetsList = assets;

    uint256 assetsToTransfer = assetsList.length - assetsTransferred;
    assetsToTransfer =
      assetsToTransfer < MAX_ASSET_TO_REQUEST ? assetsToTransfer : MAX_ASSET_TO_REQUEST;

    uint256 stdRequestLength;
    uint256 govRequestLength;
    for (uint256 i = assetsTransferred; i < assetsTransferred + assetsToTransfer; ++i) {
      if (keepGovAllowed[assetsList[i]] && concentrationAmounts[assetsList[i]].gov != 0) {
        govRequestLength += 1;
      }
      if (concentrationAmounts[assetsList[i]].std != 0) stdRequestLength += 1;
    }

    UserRequest[] memory stdRequest = new UserRequest[](stdRequestLength);
    UserRequest[] memory govRequest = new UserRequest[](govRequestLength);

    uint256 sIdx;
    uint256 gIdx;
    uint256 totalUSDValue;
    for (uint256 i = assetsTransferred; i < assetsTransferred + assetsToTransfer; ++i) {
      uint256 totalAmount = 0;
      if (concentrationAmounts[assetsList[i]].std != 0) {
        // populate request array
        stdRequest[sIdx].asset = assetsList[i];
        stdRequest[sIdx].amount = concentrationAmounts[assetsList[i]].std;
        totalAmount += stdRequest[sIdx].amount;
        // track deposited value
        uint256 usdValue = FYDE.getQuote(stdRequest[sIdx].asset, stdRequest[sIdx].amount);
        if (usdValue == 0) revert PriceNotAvailable(assetsList[i]);
        totalUSDValue += usdValue;
        TRSYBalancesPerAsset[stdRequest[sIdx].asset].std = uint128(usdValue);

        sIdx += 1;
      }

      if (keepGovAllowed[assetsList[i]] && concentrationAmounts[assetsList[i]].gov != 0) {
        govRequest[gIdx].asset = assetsList[i];
        govRequest[gIdx].amount = concentrationAmounts[assetsList[i]].gov;
        totalAmount += govRequest[gIdx].amount;
        gIdx += 1;
      }

      IERC20(assetsList[i]).forceApprove(address(FYDE), totalAmount);
    }

    totalExpectedTrsy += totalUSDValue;

    uint256 ETHToForward = ORACLE.getGweiPrice() * GAS_TO_FORWARD;
    if (stdRequestLength != 0) RELAYER.requestDeposit{value: ETHToForward}(stdRequest, false, 0);
    if (govRequestLength != 0) RELAYER.requestDeposit{value: ETHToForward}(govRequest, true, 0);

    assetsTransferred += assetsToTransfer;
    if (assetsTransferred == assetsList.length) {
      fydeDepositCompleted = true;
      emit FydeDeposit();
    }
  }

  ///@notice Rescale TrsyBalance to be correct. Has to be called after bootstrapLiquidity and before
  /// claiming
  ///@dev At the time of transferring funds into fyde, we dont know the current AUM/TRSY price to
  /// get the amount of trsy we got per asset.
  /// We therefore only store the USD values which are proportional to the correct TRSY balance in
  /// TRSYBalancesPerAsset. After the deposit has been processed,
  /// This function is called to check the actual amount of TRSY minted and rescale the balances
  function updateInternalAccounting() external {
    if (!fydeDepositCompleted) revert FydeDepositNotCompleted();
    // make sure rescale is not called when processing still in progress by checking queue is empty
    if (RELAYER.getNumPendingRequest() != 0) revert DepositsMightStillBeProcessed();

    uint256 actualTrsyBalance = IERC20(address(FYDE)).balanceOf(address(this));

    // SCALING_FACTOR to ensure precision when dividing
    uint256 scalingFactor;
    if (totalExpectedTrsy != 0) {
      scalingFactor = SCALING_FACTOR * actualTrsyBalance / totalExpectedTrsy;
    }

    for (uint256 i; i < assets.length; ++i) {
      address asset = assets[i];
      uint128 rescaledTrsy =
        uint128(uint256(TRSYBalancesPerAsset[asset].std) * scalingFactor / SCALING_FACTOR);
      TRSYBalancesPerAsset[asset].std = rescaledTrsy;
      // for governance we exactly know the balance for each asset - the sTRSY.balanceOf
      if (keepGovAllowed[asset]) {
        TRSYBalancesPerAsset[asset].gov =
          uint128(GOVERNANCE_MODULE.strsyBalance(address(this), asset));
      }
    }

    internalAccountingUpdated = true;
    emit InternalAccountingUpdated();
  }

  ///@notice User claim their TRSY, sTRSY and refund
  ///@param assetsToClaim Assets for which to claim
  function claimAndRefund(address[] calldata assetsToClaim) external {
    if (revoked) revert Revoked();
    if (!fydeDepositCompleted) revert FydeDepositNotCompleted();
    if (!internalAccountingUpdated) revert InternalAccountingNotUpdated();
    uint256 totalClaimedTrsy;
    for (uint256 i; i < assetsToClaim.length; ++i) {
      address asset = assetsToClaim[i];
      uint256 standardDeposit = deposits[msg.sender][asset].std;
      uint256 govDeposit = deposits[msg.sender][asset].gov;
      uint256 totalDeposit = standardDeposit + govDeposit;
      if (totalDeposit == 0) revert CannotClaimForAsset(asset);
      // Update their orginal deposit balance
      uint256 refundAmount = totalDeposit;

      if (standardDeposit > 0) {
        deposits[msg.sender][asset].std = 0;
        uint256 standardFundsUsed =
          standardDeposit * uint256(finalPercentages[asset].std) / SCALING_FACTOR;
        uint256 claimTRSY;
        if (concentrationAmounts[asset].std != 0) {
          claimTRSY = standardFundsUsed * uint256(TRSYBalancesPerAsset[asset].std)
            / uint256(concentrationAmounts[asset].std);
        }
        totalClaimedTrsy += claimTRSY;
        refundAmount -= standardFundsUsed;
      }

      if (govDeposit > 0) {
        deposits[msg.sender][asset].gov = 0;
        uint256 govFundsUsed = govDeposit * uint256(finalPercentages[asset].gov) / SCALING_FACTOR;
        uint256 claimStakedTRSY;
        if (concentrationAmounts[asset].gov != 0) {
          claimStakedTRSY = govFundsUsed * uint256(TRSYBalancesPerAsset[asset].gov)
            / uint256(concentrationAmounts[asset].gov);
        }
        refundAmount -= govFundsUsed;
        IERC20(GOVERNANCE_MODULE.assetToStrsy(asset)).transfer(msg.sender, claimStakedTRSY);
      }
      // Refund user, make sure balance not exceeded in case of rounding error
      if (refundAmount > 0) {
        uint256 escrowBalance = IERC20(asset).balanceOf(address(this));
        refundAmount = escrowBalance > refundAmount ? refundAmount : escrowBalance;
        IERC20(asset).safeTransfer(msg.sender, refundAmount);
      }
    }

    // send all standard TRSY
    IERC20(address(FYDE)).transfer(msg.sender, totalClaimedTrsy);

    emit ClaimedAndRefunded(msg.sender);
  }

  ///@notice User claim their refund if escrow has been revoked
  function refund(address[] calldata assetsToRefund) external {
    if (!revoked) revert NotRevoked();
    for (uint256 i; i < assetsToRefund.length; ++i) {
      address asset = assetsToRefund[i];
      uint256 totalDeposit = deposits[msg.sender][asset].std + deposits[msg.sender][asset].gov;
      deposits[msg.sender][asset].std = 0;
      deposits[msg.sender][asset].gov = 0;
      IERC20(asset).safeTransfer(msg.sender, totalDeposit);
      emit Refunded(msg.sender, asset, totalDeposit);
    }
  }

  ///@notice Abort escrow period and allows user to claim their refund
  function revoke() external onlyOwner {
    uint128 time = uint128(block.timestamp);
    if (time < ESCROW_PERIOD || time > FREEZE_PERIOD) revert OnlyDuringFreeze();
    revoked = true;
    emit EscrowRevoked();
  }

  ///@notice Recovers funds in case something goes wrong
  function returnStuckFunds(address _asset, address _to, uint256 _amount) external onlyOwner {
    IERC20(_asset).safeTransfer(_to, _amount);
  }

  function get_assets() external view returns (address[] memory) {
    return assets;
  }

  ///@notice Returns estimated TRSY for user
  ///@dev Have to be call for front end purpose after updateInternalAccounting
  function getEstimatedTrsy(address _user, address _asset) public view returns (uint256, uint256) {
    Slot memory balance = totalBalance[_asset];
    Slot memory trsy = TRSYBalancesPerAsset[_asset];
    Slot memory dep = deposits[_user][_asset];

    uint256 stdExpTrsy =
      trsy.std != 0 ? uint256(trsy.std) * uint256(dep.std) / (uint256(balance.std)) : 0;
    uint256 govExpTrsy =
      trsy.gov != 0 ? uint256(trsy.gov) * uint256(dep.gov) / (uint256(balance.gov)) : 0;

    return (stdExpTrsy, govExpTrsy);
  }

  ///@dev checks whitelist to allow deposits
  modifier onlyUser() {
    if (!isUser[address(0x0)] && !isUser[msg.sender]) revert Unauthorized();
    _;
  }
}
