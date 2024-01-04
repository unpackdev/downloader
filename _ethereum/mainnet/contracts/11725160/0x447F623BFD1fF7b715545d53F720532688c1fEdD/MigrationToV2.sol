pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./ILendingPool.sol";
import "./IFlashLoanReceiver.sol";
import "./IWETHLight.sol";
import "./ILendingPoolV1.sol";
import "./IATokenV1.sol";

/**
 * @title Migration contract
 * @notice Implements the actions to migrate ATokens and Debt positions from Aave V1 to Aave V2 protocol
 * @author Aave
 **/
contract MigrationToV2 is IFlashLoanReceiver {
  using SafeERC20 for IERC20;

  address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  uint256 internal constant UNLIMITED_APPROVAL = type(uint256).max;

  mapping (address => bool) internal approvalDept;
  mapping (address => bool) internal approvalMigration;


  ILendingPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
  ILendingPool public immutable override LENDING_POOL;

  address public immutable LENDING_POOL_V1_CORE;
  ILendingPoolV1 public immutable LENDING_POOL_V1;
  IWETH public immutable WETH;

  constructor(
    ILendingPoolV1 lendingPoolV1,
    address lendingPoolV1Core,
    ILendingPoolAddressesProvider lendingPoolAddressProvider,
    IWETH wethAddress
  ) public {
    LENDING_POOL_V1 = lendingPoolV1;
    LENDING_POOL_V1_CORE = lendingPoolV1Core;
    ADDRESSES_PROVIDER = lendingPoolAddressProvider;
    LENDING_POOL = ILendingPool(lendingPoolAddressProvider.getLendingPool());
    WETH = wethAddress;
  }

  /**
   * @dev Migrates aTokens and debt positions from V1 to V2
   * Before taking the flashloan for each debt position reserves, the user must:
   *   - For each ATokens in V1 approve spending to this migration contract
   *
   * It will repay each user debt position in V1, redeem ATokens in V1, deposit the underlying in V2 on behalf of the
   * user, do not repay the flashloan so debt positions are automatically open for the user in V2.
   *
   * In V1 the native ETH currency was used while in V2 WETH is used in the protocol, so the proper conversions are
   * taken into consideration.
   *
   * @param assets list of debt reserves that will be repaid in V1 and opened to V2
   * @param amounts list of amounts of the debt reserves to be repaid in V1
   * @param premiums list of premiums for each flash loan
   * @param initiator address of the user initiating the migration
   * @param params data for the migration that contains:
   *   address[] v1ATokens List of ATokens in V1 that the user wants to migrate to V2
   *   uint256[] aTokensAmounts List of amounts of the ATokens to migrate
   **/
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external override returns (bool) {
    premiums;
    require(msg.sender == address(LENDING_POOL), 'Caller is not lending pool');

    (address[] memory v1ATokens, uint256[] memory aTokensAmounts) =
      abi.decode(params, (address[], uint256[]));
    require(v1ATokens.length == aTokensAmounts.length, 'INCONSISTENT_PARAMS');

    // Repay debt in V1 for each asset flash borrowed
    for (uint256 i = 0; i < assets.length; i++) {
      address debtReserve = assets[i] == address(WETH) ? ETH : assets[i];
      _payDebt(debtReserve, amounts[i], initiator);
    }

    // Migrate ATokens
    for (uint256 i = 0; i < v1ATokens.length; i++) {
      _migrateAToken(IATokenV1(v1ATokens[i]), aTokensAmounts[i], initiator);
    }

    return true;
  }

  /**
   * @dev Migrates ATokens from V1 to V2. This method can be called directly to avoid using flashloans if there is no
   * debt to migrate.
   * The user must approve spending to this migration contract for each ATokens in V1.
   *
   * @param v1ATokens List of ATokens in V1 that the user wants to migrate to V2
   * @param aTokensAmounts List of amounts of the ATokens to migrate
   **/
  function migrateATokens(address[] calldata v1ATokens, uint256[] calldata aTokensAmounts)
    external
  {
    require(v1ATokens.length == aTokensAmounts.length, 'INCONSISTENT_PARAMS');

    for (uint256 i = 0; i < v1ATokens.length; i++) {
      _migrateAToken(IATokenV1(v1ATokens[i]), aTokensAmounts[i], msg.sender);
    }
  }

  /**
   * @dev Allow to receive ether.
   * Needed to unwrap WETH for an ETH debt in V1 and receive the underlying ETH of aETH from V1.
   **/
  receive() external payable {}

  /**
   * @dev Pays the debt in V1 and send back to the user wallet any left over from the operation.
   * @param debtReserve Address of the reserve in V1 that the user wants to pay the debt
   * @param amount of debt to be paid in V1
   * @param user Address of the user
   **/
  function _payDebt(
    address debtReserve,
    uint256 amount,
    address user
  ) internal {
    uint256 valueAmount = 0;

    if (debtReserve == ETH) {
      valueAmount = amount;
      // Unwrap WETH into ETH
      WETH.withdraw(amount);
    } else if(!approvalDept[debtReserve]) {
      IERC20(debtReserve).safeApprove(address(LENDING_POOL_V1_CORE), UNLIMITED_APPROVAL);
      approvalDept[debtReserve] = true;
    }

    LENDING_POOL_V1.repay{value: valueAmount}(debtReserve, amount, payable(user));

    _sendLeftovers(debtReserve, user);
  }

  /**
   * @dev Migrates an AToken from V1 to V2
   * @param aToken Address of the  AToken in V1 that the user wants to migrate to V2
   * @param amount Amount of the AToken to migrate
   * @param user Address of the user
   **/
  function _migrateAToken(
    IATokenV1 aToken,
    uint256 amount,
    address user
  ) internal {
    uint256 aTokenBalance = aToken.balanceOf(user);
    require(aTokenBalance > 0, 'no aToken balance to migrate');

    uint256 amountToMigrate = amount > aTokenBalance ? aTokenBalance : amount;

    // Pull user ATokensV1 and redeem underlying
    IERC20(aToken).safeTransferFrom(user, address(this), amountToMigrate);
    aToken.redeem(amountToMigrate);

    address underlying = aToken.underlyingAssetAddress();

    // If underlying is ETH wrap it into WETH
    if (underlying == ETH) {
      WETH.deposit{value: address(this).balance}();
      underlying = address(WETH);
    }

    if(!approvalMigration[underlying]) {
      IERC20(underlying).safeApprove(address(LENDING_POOL), UNLIMITED_APPROVAL);
      approvalMigration[underlying] = true;
    }
    // Deposit underlying into V2 on behalf of the user
    uint256 underlyingBalance = IERC20(underlying).balanceOf(address(this));
    LENDING_POOL.deposit(underlying, underlyingBalance, user, 0);
  }

  /**
   * @dev Send back to the user any left overs from the debt repayment in V1
   * @param asset address of the asset
   * @param user address
   */
  function _sendLeftovers(address asset, address user) internal {
    if (asset == ETH) {
      uint256 reserveBalance = address(this).balance;

      if (reserveBalance > 0) {
        WETH.deposit{value: reserveBalance}();
        IERC20(WETH).safeTransfer(user, reserveBalance);
      }
    } else {
      uint256 reserveBalance = IERC20(asset).balanceOf(address(this));

      if (reserveBalance > 0) {
        IERC20(asset).safeTransfer(user, reserveBalance);
      }
    }
  }


}
