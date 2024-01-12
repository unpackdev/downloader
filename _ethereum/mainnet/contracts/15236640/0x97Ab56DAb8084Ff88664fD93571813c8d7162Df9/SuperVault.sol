// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./Initializable.sol";
import "./IPool.sol";

import "./IAddressProvider.sol";
import "./IGovernanceAddressProvider.sol";
import "./IVaultsCore.sol";
import "./IGenericMiner.sol";
import "./IDexAddressProvider.sol";

/// @title A parallel protocol vault with added functionality
/// @notice You can use this for collateral rebalancing
/// @dev This contract should be cloned and initialized with a SuperVaultFactory contract
contract SuperVault is AccessControl, Initializable {
  using SafeERC20 for IERC20;
  enum Operation {
    LEVERAGE,
    REBALANCE,
    EMPTY
  }

  struct AggregatorRequest {
    uint256 parToSell;
    bytes dexTxData;
    uint256 dexIndex;
  }

  IAddressProvider private _a;
  IGovernanceAddressProvider private _ga;
  IPool private _lendingPool;
  IDexAddressProvider internal _dexAP;

  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "SV001");
    _;
  }

  ///@notice Initializes the Supervault contract
  ///@dev This replaces the constructor function as in the factory design pattern
  ///@param a The address of the protocol's AddressProvider
  ///@param ga The address of the protocol's GovernanceAddressProvider
  ///@param lendingPool The address of the lendingPool from where flashLoans are taken
  ///@param owner The owner of this SuperVault contract
  ///@param dexAP The DexAddressAprovider that provides the routers and proxy addresses for each aggregator
  function initialize(
    IAddressProvider a,
    IGovernanceAddressProvider ga,
    IPool lendingPool,
    address owner,
    IDexAddressProvider dexAP
  ) external initializer {
    require(address(a) != address(0));
    require(address(ga) != address(0));
    require(address(lendingPool) != address(0));
    require(owner != address(0));
    require(address(dexAP) != address(0));

    _a = a;
    _ga = ga;
    _lendingPool = lendingPool;
    _dexAP = dexAP;

    _grantRole(DEFAULT_ADMIN_ROLE, owner);
  }

  ///@notice Routes a call from a flashloan pool to a leverage or rebalance operation
  ///@dev This Integrates with AAVE V3 flashLoans
  ///@dev This function is called by the lendingPool during execution of the leverage function
  ///@param assets An address array with one element corresponding to the address of the leveraged or rebalanced asset
  ///@param amounts A uint array with one element corresponding to the amount of the leveraged or rebalanced asset
  ///@param premiums A uint array with one element corresponding to the flashLoan fees
  ///@param initiator The initiator of the flashloan; used to check that only flashloans taken from this contract can do vault operations
  ///@param params Bytes sent by the leverage or rebalance function that contains information on the aggregator swap
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external returns (bool) {
    IPool lendingPool_ = getLendingPool();
    require(msg.sender == address(lendingPool_), "SV002");
    require(initiator == address(this), "SV003");
    (Operation operation, bytes memory operationParams) = abi.decode(params, (Operation, bytes));
    IERC20 asset = IERC20(assets[0]);
    uint256 flashloanRepayAmount = amounts[0] + premiums[0];
    if (operation == Operation.LEVERAGE) {
      _leverageOperation(asset, flashloanRepayAmount, operationParams);
    }
    if (operation == Operation.REBALANCE) {
      _rebalanceOperation(asset, amounts[0], flashloanRepayAmount, operationParams);
    }
    if (operation == Operation.EMPTY) {
      _emptyVaultOperation(asset, amounts[0], flashloanRepayAmount, operationParams);
    }

    asset.safeIncreaseAllowance(address(lendingPool_), flashloanRepayAmount);
    return true;
  }

  ///@notice Used by executeOperation to call an aggregator to swap and deposit the swapped asset into a vault
  ///@param token The ERC20 token to leverage
  ///@param flashloanRepayAmount The amount that needs to be repaid for the flashloan
  ///@param params The bytes passed from the flashloan call
  function _leverageOperation(
    IERC20 token,
    uint256 flashloanRepayAmount,
    bytes memory params
  ) internal {
    _leverageSwap(params, token);
    require(token.balanceOf(address(this)) >= flashloanRepayAmount, "SV101");
    IVaultsCore core = getA().core();
    uint256 collateralBalance = token.balanceOf(address(this));
    token.safeIncreaseAllowance(address(core), collateralBalance);
    core.deposit(address(token), collateralBalance - flashloanRepayAmount);
  }

  ///@notice Leverage an asset using a flashloan to balance collateral
  ///@dev This uses an AAVE V3 flashLoan that will call executeOperation
  ///@param asset The address of the asset to leverage
  ///@param depositAmount The initial starting amount, e.g. 1 ETH
  ///@param borrowAmount The amount to be borrowed, e.g. 2 ETH, bringing the total to 3 ETH
  ///@param parToSell The amount of PAR we'll borrow so we can repay the leverage
  ///@param dexTxData Bytes that will be passed to executeOperation that encodes args for the aggregator Swap
  ///@param dexIndex DexAddressProvider index of the aggregator to be used for selling PAR, either OneInch or Paraswap
  function leverage(
    address asset,
    uint256 depositAmount, //
    uint256 borrowAmount, //
    uint256 parToSell, //
    bytes calldata dexTxData,
    uint256 dexIndex
  ) external onlyOwner {
    IERC20(asset).safeTransferFrom(msg.sender, address(this), depositAmount);
    bytes memory leverageParams = abi.encode(parToSell, dexTxData, dexIndex);
    bytes memory params = abi.encode(Operation.LEVERAGE, leverageParams);
    _takeFlashLoan(asset, borrowAmount, params);
    _checkAndSendMIMO();
  }

  ///@notice Used by executeOperation to flashloan an asset, call an aggregator to swap for toAsset, and then rebalance the vault
  ///@param fromCollateral The ERC20 token to rebalance from
  ///@param amount The amount of collateral to swap to for par to repay vaultdebt
  ///@param flashloanRepayAmount The amount that needs to be repaid for the flashloan
  ///@param params The bytes passed from the flashloan call
  function _rebalanceOperation(
    IERC20 fromCollateral,
    uint256 amount,
    uint256 flashloanRepayAmount,
    bytes memory params
  ) internal {
    (uint256 vaultId, address toCollateral, uint256 parAmount, bytes memory dexTxData, uint256 dexIndex) = abi.decode(
      params,
      (uint256, address, uint256, bytes, uint256)
    );
    IAddressProvider a_ = getA();
    _aggregatorSwap(dexIndex, fromCollateral, amount, dexTxData);

    uint256 depositAmount = IERC20(toCollateral).balanceOf(address(this));

    IERC20(toCollateral).safeIncreaseAllowance(address(a_.core()), depositAmount);

    a_.core().depositAndBorrow(toCollateral, depositAmount, parAmount);
    a_.core().repay(vaultId, parAmount);

    a_.core().withdraw(vaultId, flashloanRepayAmount);

    require(fromCollateral.balanceOf(address(this)) >= flashloanRepayAmount, "SV101");
  }

  ///@notice Uses a flashloan to exchange one collateral type for another, e.g. to hold less volatile collateral
  ///@notice Both collateral vaults must have been created by this contract using the depositToVault or depositAndBorrowFromVault functions
  ///@dev This uses an AAVE V3 flashLoan that will call executeOperation
  ///@param vaultId The Id of the vault to reduce the collateral of
  ///@param toCollateral Address of the collateral to rebalance to
  ///@param fromCollateral Address of the starting collateral that will be reduced
  ///@param fromCollateralAmount Amount of starting collateral to deleverage
  ///@param parAmount Amount of par that will be repaid to allow withdrawal of fromCollateral from vaultsCore
  ///@param dexTxData Bytes that will be passed to executeOperation that encodes args for the aggregator Swap
  ///@param dexIndex DexAddressProvider index representing the aggregator to be used for selling PAR, either OneInch or Paraswap
  function rebalance(
    uint256 vaultId, // vaultId to deleverage
    address toCollateral,
    address fromCollateral, // save some gas by just passing in collateral type instead of querying VaultsDataProvider for it
    uint256 fromCollateralAmount, // amount of collateral to reduce in main vault and borrow from Aave first
    uint256 parAmount,
    bytes calldata dexTxData,
    uint256 dexIndex
  ) external onlyOwner {
    bytes memory rebalanceParams = abi.encode(vaultId, toCollateral, parAmount, dexTxData, dexIndex);
    bytes memory params = abi.encode(Operation.REBALANCE, rebalanceParams);

    _takeFlashLoan(fromCollateral, fromCollateralAmount, params);
    _checkAndSendMIMO();
  }

  ///@notice Used by executeOperation to repay all debt for a vault, withdraw collateral from the vault, and send the collateral back to the user
  ///@notice There will likely be some leftover par after repaying the loan; that will also be sent back to the user
  ///@param vaultCollateral The collateral of the vault to empty
  ///@param amount The amount of collateral to swap to for par to repay vaultdebt
  ///@param flashloanRepayAmount The amount that needs to be repaid for the flashloan
  ///@param params The bytes passed from the flashloan call
  function _emptyVaultOperation(
    IERC20 vaultCollateral,
    uint256 amount,
    uint256 flashloanRepayAmount,
    bytes memory params
  ) internal {
    // Use par to repay debt
    (uint256 vaultId, bytes memory dexTxData, uint256 dexIndex) = abi.decode(params, (uint256, bytes, uint256));
    IAddressProvider a_ = getA();

    _aggregatorSwap(dexIndex, vaultCollateral, amount, dexTxData); // swap assets for par to repay back loan

    IERC20 stablex_ = IERC20(a_.stablex());
    stablex_.safeIncreaseAllowance(address(a_.core()), stablex_.balanceOf(address(this)));

    // Repay the par debt
    a_.core().repayAll(vaultId);
    uint256 vaultBalance = a_.vaultsData().vaultCollateralBalance(vaultId);
    // Withdraw all collateral
    a_.core().withdraw(vaultId, vaultBalance);

    require(vaultCollateral.balanceOf(address(this)) >= flashloanRepayAmount, "SV101");
  }

  ///@notice Uses a flashloan to repay all debts for a vault and send all collateral in the vault to the owner
  ///@notice This vault must have been created by this contract
  ///@dev This uses an AAVE V3 flashLoan that will call executeOperation
  ///@param vaultId The Id of the vault to empty
  ///@param collateralType Address of the collateral of the vault
  ///@param repayAmount Amount of collateral that needs to be swapped for par to repay outstanding vault debt 
  ///@param dexTxData Bytes that contain the low-level call to swap the vault asset for par to repay the vault loan
  ///@param dexIndex Index to use for swapping the vault collateral for par
  function emptyVault(
    uint256 vaultId,
    address collateralType,
    uint256 repayAmount, 
    bytes calldata dexTxData,
    uint256 dexIndex
  ) external onlyOwner {
    // Flashloan collateral and swap for par to repay any outstanding vault debt
    bytes memory emptyVaultParams = abi.encode(vaultId, dexTxData, dexIndex);
    bytes memory params = abi.encode(Operation.EMPTY, emptyVaultParams);
    IERC20 stablex_ = IERC20(getA().stablex()); 
    _takeFlashLoan(collateralType, repayAmount, params);

    _checkAndSendMIMO();

    // Send remaining par, mimo, and collateral back to the owner
    stablex_.safeTransfer(msg.sender, stablex_.balanceOf(address(this)));
    _checkAndSendMIMO();

    IERC20 collateral = IERC20(collateralType);
    collateral.safeTransfer(msg.sender, collateral.balanceOf(address(this)));
  }

  ///@notice Withdraw collateral from a vault
  ///@notice Vault must have been created through leverage, depositToVault, or depositAndBorrowFromVault from this contract
  ///@param vaultId The ID of the vault to withdraw from
  ///@param amount The amount of collateral to withdraw
  function withdrawFromVault(uint256 vaultId, uint256 amount) external onlyOwner {
    IAddressProvider a_ = getA();
    a_.core().withdraw(vaultId, amount);
    IERC20 asset = IERC20(a_.vaultsData().vaultCollateralType(vaultId));
    asset.safeTransfer(msg.sender, amount);
  }

  ///@notice Borrow PAR from a vault
  ///@param vaultId The ID of the vault to borrow from
  ///@param amount The amount of PAR to borrow
  function borrowFromVault(uint256 vaultId, uint256 amount) external onlyOwner {
    IAddressProvider a_ = getA();
    IERC20 stablex_ = IERC20(a_.stablex());
    a_.core().borrow(vaultId, amount);
    stablex_.safeTransfer(msg.sender, stablex_.balanceOf(address(this)));
    _checkAndSendMIMO();
  }

  ///@notice Withdraw all of one type of collateral from this contract
  ///@notice Can only be used on vaults which have been created by this contract
  ///@param asset The address of the collateral type
  function withdrawAsset(address asset) external onlyOwner {
    IERC20 token = IERC20(asset);
    token.safeTransfer(msg.sender, token.balanceOf(address(this)));
  }

  ///@notice Deposit collateral into a vault
  ///@notice Requires approval of asset for amount before calling
  ///@param asset Address of the collateral type
  ///@param amount Amount to deposit
  function depositToVault(address asset, uint256 amount) external {
    IERC20 token = IERC20(asset);
    IAddressProvider a_ = getA();
    token.safeIncreaseAllowance(address(a_.core()), amount);
    token.safeTransferFrom(msg.sender, address(this), amount);
    a_.core().deposit(asset, amount);
  }

  ///@notice Deposit collateral into a vault and borrow PAR
  ///@notice Requires approval of asset for amount before calling
  ///@param asset Address of the collateral type
  ///@param depositAmount Amount to deposit
  ///@param borrowAmount Amount of PAR to borrow after depositing
  function depositAndBorrowFromVault(
    address asset,
    uint256 depositAmount,
    uint256 borrowAmount
  ) external onlyOwner {
    IERC20 token = IERC20(asset);
    IAddressProvider a_ = getA();
    IERC20 stablex_ = IERC20(a_.stablex());
    token.safeIncreaseAllowance(address(a_.core()), depositAmount);
    token.safeTransferFrom(msg.sender, address(this), depositAmount);
    a_.core().depositAndBorrow(asset, depositAmount, borrowAmount);
    stablex_.safeTransfer(msg.sender, stablex_.balanceOf(address(this))); //par
    _checkAndSendMIMO();
  }

  ///@notice Release MIMO from a MIMO miner to the owner
  ///@param minerAddress The address of the MIMO miner
  function releaseMIMO(address minerAddress) external payable onlyOwner {
    IGenericMiner miner = IGenericMiner(minerAddress);
    miner.releaseMIMO(address(this));
    _checkAndSendMIMO();
  }

  ///@notice Wrap ETH and deposit WETH as collateral into a vault
  function depositETHToVault() external payable {
    getA().core().depositETH{ value: msg.value }();
  }

  ///@notice Wrap ETH and deposit WETH as collateral into a vault, then borrow PAR from vault
  ///@param borrowAmount The amount of PAR to borrow after depositing ETH
  function depositETHAndBorrowFromVault(uint256 borrowAmount) external payable onlyOwner {
    IAddressProvider a_ = getA();
    IERC20 stablex_ = IERC20(a_.stablex());
    a_.core().depositETHAndBorrow{ value: msg.value }(borrowAmount);
    stablex_.safeTransfer(msg.sender, stablex_.balanceOf(address(this))); //par
    _checkAndSendMIMO();
  }

  ///@notice Helper function to call an aggregator to swap PAR for a leveraged asset
  ///@dev This helper function is used to limit the number of local variables in the leverageOperation function
  ///@param params The params passed from the leverageOperation function for the aggregator call
  ///@param token The leveraged asset to swap PAR for
  function _leverageSwap(bytes memory params, IERC20 token) internal {
    (uint256 parToSell, bytes memory dexTxData, uint256 dexIndex) = abi.decode(params, (uint256, bytes, uint256));
    uint256 collateralBalance = token.balanceOf(address(this));
    IAddressProvider a_ = getA();
    token.safeIncreaseAllowance(address(a_.core()), collateralBalance);
    a_.core().depositAndBorrow(address(token), collateralBalance, parToSell);
    IERC20 par = IERC20(a_.stablex());
    _aggregatorSwap(dexIndex, par, parToSell, dexTxData);
  }

  ///@notice Helper function to approve and swap an asset using an aggregator
  ///@param dexIndex The DexAddressProvider index of aggregator to use to swap
  ///@param token The starting token to swap for another asset
  ///@param amount The amount of starting token to swap for
  ///@param dexTxData The low-level data to call the aggregator with
  function _aggregatorSwap(
    uint256 dexIndex,
    IERC20 token,
    uint256 amount,
    bytes memory dexTxData
  ) internal {
    (address proxy, address router) = _dexAP.dexMapping(dexIndex);
    require(proxy != address(0) && router != address(0), "SV201");
    token.safeIncreaseAllowance(proxy, amount);
    (bool swapSuccess, bytes memory __) = router.call(dexTxData);
    require(swapSuccess, "SV102");
  }

  ///@notice Helper function to format arguments to take a flashloan
  ///@dev The flashloan call will call the executeOperation function on this contract
  ///@param asset The address of the asset to loan
  ///@param amount The amount to borrow
  ///@param params The params that will be sent to executeOperation after the asset is borrowed
  function _takeFlashLoan(
    address asset,
    uint256 amount,
    bytes memory params
  ) internal {
    uint8 referralCode;
    address[] memory assets = new address[](1);
    uint256[] memory amounts = new uint256[](1);
    uint256[] memory modes = new uint256[](1);
    (assets[0], amounts[0]) = (asset, amount);
    getLendingPool().flashLoan(address(this), assets, amounts, modes, address(this), params, referralCode);
  }

  ///@notice Helper function to transfer all MIMO owned by this contract to the Owner
  function _checkAndSendMIMO() internal {
    IERC20 mimo = getGA().mimo();
    if (mimo.balanceOf(address(this)) > 0) {
      mimo.safeTransfer(msg.sender, mimo.balanceOf(address(this)));
    }
  }

  function getA() public view returns (IAddressProvider) {
    return _a;
  }

  function getGA() public view returns (IGovernanceAddressProvider) {
    return _ga;
  }

  function getLendingPool() public view returns (IPool) {
    return _lendingPool;
  }
}
