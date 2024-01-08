// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./AdministrateeInterface.sol";
import "./StoreInterface.sol";
import "./FinderInterface.sol";
import "./Constants.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./FixedPoint.sol";
import "./FeePayerPartyLib.sol";
import "./Testable.sol";
import "./Lockable.sol";

/**
 * @title FeePayer contract.
 * @notice Provides fee payment functionality for the PerpetualParty contracts.
 * contract is abstract as each derived contract that inherits `FeePayer` must implement `pfc()`.
 */
abstract contract FeePayerParty is AdministrateeInterface, Testable, Lockable {
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Unsigned;
  using FeePayerPartyLib for FixedPoint.Unsigned;
  using FeePayerPartyLib for FeePayerData;
  using SafeERC20 for IERC20;

  struct FeePayerData {
    // The collateral currency used to back the positions in this contract.
    IERC20 collateralCurrency;
    // Finder contract used to look up addresses for UMA system contracts.
    FinderInterface finder;
    // Tracks the last block time when the fees were paid.
    uint256 lastPaymentTime;
    // Tracks the cumulative fees that have been paid by the contract for use by derived contracts.
    // The multiplier starts at 1, and is updated by computing cumulativeFeeMultiplier * (1 - effectiveFee).
    // Put another way, the cumulativeFeeMultiplier is (1 - effectiveFee1) * (1 - effectiveFee2) ...
    // For example:
    // The cumulativeFeeMultiplier should start at 1.
    // If a 1% fee is charged, the multiplier should update to .99.
    // If another 1% fee is charged, the multiplier should be 0.99^2 (0.9801).
    FixedPoint.Unsigned cumulativeFeeMultiplier;
  }

  //----------------------------------------
  // Storage
  //----------------------------------------

  FeePayerData public feePayerData;

  //----------------------------------------
  // Events
  //----------------------------------------

  event RegularFeesPaid(uint256 indexed regularFee, uint256 indexed lateFee);
  event FinalFeesPaid(uint256 indexed amount);

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  // modifier that calls payRegularFees().
  modifier fees {
    // Note: the regular fee is applied on every fee-accruing transaction, where the total change is simply the
    // regular fee applied linearly since the last update. This implies that the compounding rate depends on the
    // frequency of update transactions that have this modifier, and it never reaches the ideal of continuous
    // compounding. This approximate-compounding pattern is common in the Ethereum ecosystem because of the
    // complexity of compounding data on-chain.
    payRegularFees();
    _;
  }
  modifier onlyThisContract {
    require(msg.sender == address(this), 'Caller is not this contract');
    _;
  }

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Constructs FeePayerParty contract. Called by child contracts
   * @param _collateralAddress ERC20 token that is used as the underlying collateral for the synthetic.
   * @param _finderAddress UMA protocol Finder used to discover other protocol contracts.
   * @param _timerAddress Contract that stores the current time in a testing environment.
   * Must be set to 0x0 for production environments that use live time.
   */
  constructor(
    address _collateralAddress,
    address _finderAddress,
    address _timerAddress
  ) public Testable(_timerAddress) {
    feePayerData.collateralCurrency = IERC20(_collateralAddress);
    feePayerData.finder = FinderInterface(_finderAddress);
    feePayerData.lastPaymentTime = getCurrentTime();
    feePayerData.cumulativeFeeMultiplier = FixedPoint.fromUnscaledUint(1);
  }

  //----------------------------------------
  // External functions
  //----------------------------------------

  /**
   * @notice Pays UMA Oracle final fees of `amount` in `collateralCurrency` to the Store contract. Final fee is a flat fee
   * @param payer The address that pays the fees
   * @param amount Amount of fees to be paid
   */
  function payFinalFees(address payer, FixedPoint.Unsigned memory amount)
    external
    onlyThisContract
  {
    _payFinalFees(payer, amount);
  }

  /**
   * @notice Gets the collateral currency of the derivative
   * @return Collateral currency
   */
  function collateralCurrency()
    public
    view
    virtual
    nonReentrantView()
    returns (IERC20)
  {
    return feePayerData.collateralCurrency;
  }

  /**
   * @notice Pays UMA DVM regular fees (as a % of the collateral pool) to the Store contract.
   * @dev These must be paid periodically for the life of the contract. If the contract has not paid its regular fee
   * in a week or more then a late penalty is applied which is sent to the caller. If the amount of
   * fees owed are greater than the pfc, then this will pay as much as possible from the available collateral.
   * An event is only fired if the fees charged are greater than 0.
   * @return totalPaid Amount of collateral that the contract paid (sum of the amount paid to the Store and caller).
   * This returns 0 and exit early if there is no pfc, fees were already paid during the current block, or the fee rate is 0.
   */
  function payRegularFees()
    public
    nonReentrant()
    returns (FixedPoint.Unsigned memory totalPaid)
  {
    StoreInterface store = _getStore();
    uint256 time = getCurrentTime();
    FixedPoint.Unsigned memory collateralPool = _pfc();
    totalPaid = feePayerData.payRegularFees(store, time, collateralPool);
    return totalPaid;
  }

  /**
   * @notice Gets the current profit from corruption for this contract in terms of the collateral currency.
   * @dev This is equivalent to the collateral pool available from which to pay fees. Therefore, derived contracts are
   * expected to implement this so that pay-fee methods can correctly compute the owed fees as a % of PfC.
   * @return pfc value for equal to the current profit from corruption denominated in collateral currency.
   */
  function pfc()
    public
    view
    override
    nonReentrantView()
    returns (FixedPoint.Unsigned memory)
  {
    return _pfc();
  }

  //----------------------------------------
  // Internal functions
  //----------------------------------------

  // Pays UMA Oracle final fees of `amount` in `collateralCurrency` to the Store contract. Final fee is a flat fee
  // charged for each price request. If payer is the contract, adjusts internal bookkeeping variables. If payer is not
  // the contract, pulls in `amount` of collateral currency.
  function _payFinalFees(address payer, FixedPoint.Unsigned memory amount)
    internal
  {
    StoreInterface store = _getStore();
    feePayerData.payFinalFees(store, payer, amount);
  }

  function _pfc() internal view virtual returns (FixedPoint.Unsigned memory);

  // Get Store Contract to which fees will be paid
  function _getStore() internal view returns (StoreInterface) {
    return
      StoreInterface(
        feePayerData.finder.getImplementationAddress(OracleInterfaces.Store)
      );
  }

  // Calculate final fees to be paid
  function _computeFinalFees()
    internal
    view
    returns (FixedPoint.Unsigned memory finalFees)
  {
    StoreInterface store = _getStore();
    return store.computeFinalFee(address(feePayerData.collateralCurrency));
  }
}
