// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./CurveMaster.sol";
import "./IOracleRelay.sol";
import "./IBooster.sol";
import "./IBaseRewardPool.sol";
import "./IVaultDeployer.sol";
import "./IAMPHClaimer.sol";
import "./IUSDA.sol";

/// @title VaultController Interface
interface IVaultController {
  /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

  // @notice Emited when payInterest is called to accrue interest and distribute it
  // @param _epoch The block timestamp when the function called
  // @param _amount The increase amount of the interest factor
  // @param _curveVal The value at the curve
  event InterestEvent(uint64 _epoch, uint192 _amount, uint256 _curveVal);

  // @notice Emited when a new protocol fee is being set
  // @param _protocolFee The new fee for the protocol
  event NewProtocolFee(uint192 _protocolFee);

  // @notice Emited when a new erc20 token is being registered as acceptable collateral
  // @param _tokenAddress The addres of the erc20 token
  // @param _ltv The loan to value amount of the erc20
  // @param _oracleAddress The address of the oracle to use to fetch the price
  // @param _liquidationIncentive The liquidation penalty for the token
  // @param _cap The maximum amount that can be deposited
  event RegisteredErc20(
    address _tokenAddress, uint256 _ltv, address _oracleAddress, uint256 _liquidationIncentive, uint256 _cap
  );

  // @notice Emited when the information about an acceptable erc20 token is being update
  // @param _tokenAddress The addres of the erc20 token to update
  // @param _ltv The new loan to value amount of the erc20
  // @param _oracleAddress The new address of the oracle to use to fetch the price
  // @param _liquidationIncentive The new liquidation penalty for the token
  // @param _cap The maximum amount that can be deposited
  // @param _poolId The convex pool id of a crv lp token
  event UpdateRegisteredErc20(
    address _tokenAddress,
    uint256 _ltv,
    address _oracleAddress,
    uint256 _liquidationIncentive,
    uint256 _cap,
    uint256 _poolId
  );

  // @notice Emited when a new vault is being minted
  // @param _vaultAddress The address of the new vault
  // @param _vaultId The id of the vault
  // @param _vaultOwner The address of the owner of the vault
  event NewVault(address _vaultAddress, uint256 _vaultId, address _vaultOwner);

  // @notice Emited when the owner registers a curve master
  // @param _curveMasterAddress The address of the curve master
  event RegisterCurveMaster(address _curveMasterAddress);

  // @notice Emited when someone successfully borrows USDA
  // @param _vaultId The id of the vault that borrowed against
  // @param _vaultAddress The address of the vault that borrowed against
  // @param _borrowAmount The amounnt that was borrowed
  // @param _fee The fee assigned to the treasury
  event BorrowUSDA(uint256 _vaultId, address _vaultAddress, uint256 _borrowAmount, uint256 _fee);

  // @notice Emited when someone successfully repayed a vault's loan
  // @param _vaultId The id of the vault that was repayed
  // @param _vaultAddress The address of the vault that was repayed
  // @param _repayAmount The amount that was repayed
  event RepayUSDA(uint256 _vaultId, address _vaultAddress, uint256 _repayAmount);

  // @notice Emited when someone successfully liquidates a vault
  // @param _vaultId The id of the vault that was liquidated
  // @param _assetAddress The address of the token that was liquidated
  // @param _usdaToRepurchase The amount of USDA that was repurchased
  // @param _tokensToLiquidate The number of tokens that were taken from the vault and sent to the liquidator
  // @param _liquidationFee The number of tokens that were taken from the fee and sent to the treasury
  event Liquidate(
    uint256 _vaultId,
    address _assetAddress,
    uint256 _usdaToRepurchase,
    uint256 _tokensToLiquidate,
    uint256 _liquidationFee
  );

  // @notice Emited when governance changes the claimer contract
  //  @param _oldClaimerContract The old claimer contract
  //  @param _newClaimerContract The new claimer contract
  event ChangedClaimerContract(IAMPHClaimer _oldClaimerContract, IAMPHClaimer _newClaimerContract);

  // @notice Emited when the owner registers the USDA contract
  // @param _usdaContractAddress The address of the USDA contract
  event RegisterUSDA(address _usdaContractAddress);

  // @notice Emited when governance changes the initial borrowing fee
  //  @param _oldBorrowingFee The old borrowing fee
  //  @param _newBorrowingFee The new borrowing fee
  event ChangedInitialBorrowingFee(uint192 _oldBorrowingFee, uint192 _newBorrowingFee);

  // @notice Emited when governance changes the liquidation fee
  //  @param _oldLiquidationFee The old liquidation fee
  //  @param _newLiquidationFee The new liquidation fee
  event ChangedLiquidationFee(uint192 _oldLiquidationFee, uint192 _newLiquidationFee);

  // @notice Emited when collaterals are migrated from old vault controller
  //  @param _oldVaultController The old vault controller migrated from
  //  @param _tokenAddresses The list of new collaterals
  event CollateralsMigratedFrom(IVaultController _oldVaultController, address[] _tokenAddresses);

  /*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

  /// @notice Thrown when token has invalid amount of decimals
  error VaultController_TooManyDecimals();

  /// @notice Thrown when _msgSender is not the pauser of the contract
  error VaultController_OnlyPauser();

  /// @notice Thrown when the fee is too large
  error VaultController_FeeTooLarge();

  /// @notice Thrown when oracle does not exist
  error VaultController_OracleNotRegistered();

  /// @notice Thrown when the token is already registered
  error VaultController_TokenAlreadyRegistered();

  /// @notice Thrown when the token is not registered
  error VaultController_TokenNotRegistered();

  /// @notice Thrown when the _ltv is incompatible
  error VaultController_LTVIncompatible();

  /// @notice Thrown when _msgSender is not the minter
  error VaultController_OnlyMinter();

  /// @notice Thrown when vault is insolvent
  error VaultController_VaultInsolvent();

  /// @notice Thrown when repay is grater than borrow
  error VaultController_RepayTooMuch();

  /// @notice Thrown when trying to liquidate 0 tokens
  error VaultController_LiquidateZeroTokens();

  /// @notice Thrown when trying to liquidate more than is possible
  error VaultController_OverLiquidation();

  /// @notice Thrown when vault is solvent
  error VaultController_VaultSolvent();

  /// @notice Thrown when vault does not exist
  error VaultController_VaultDoesNotExist();

  /// @notice Thrown when migrating collaterals to a new vault controller
  error VaultController_WrongCollateralAddress();

  /// @notice Thrown when a not valid vault is trying to modify the total deposited
  error VaultController_NotValidVault();

  /// @notice Thrown when a deposit surpass the cap
  error VaultController_CapReached();

  /// @notice Thrown when registering a crv lp token with wrong address
  error VaultController_TokenAddressDoesNotMatchLpAddress();

  /*///////////////////////////////////////////////////////////////
                            ENUMS
  //////////////////////////////////////////////////////////////*/

  enum CollateralType {
    Single,
    CurveLPStakedOnConvex
  }

  /*///////////////////////////////////////////////////////////////
                            STRUCTS
    //////////////////////////////////////////////////////////////*/

  struct VaultSummary {
    uint96 id;
    uint192 borrowingPower;
    uint192 vaultLiability;
    address[] tokenAddresses;
    uint256[] tokenBalances;
  }

  struct Interest {
    uint64 lastTime;
    uint192 factor;
  }

  struct CollateralInfo {
    uint256 tokenId;
    uint256 ltv;
    uint256 cap;
    uint256 totalDeposited;
    uint256 liquidationIncentive;
    IOracleRelay oracle;
    CollateralType collateralType;
    IBaseRewardPool crvRewardsContract;
    uint256 poolId;
    uint256 decimals;
  }

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
    //////////////////////////////////////////////////////////////*/

  /// @notice Total number of tokens registered
  function tokensRegistered() external view returns (uint256 _tokensRegistered);

  /// @notice Total number of minted vaults
  function vaultsMinted() external view returns (uint96 _vaultsMinted);

  /// @notice Returns the block timestamp when pay interest was last called
  /// @return _lastInterestTime The block timestamp when pay interest was last called
  function lastInterestTime() external view returns (uint64 _lastInterestTime);

  /// @notice Total base liability
  function totalBaseLiability() external view returns (uint192 _totalBaseLiability);

  /// @notice Returns the latest interest factor
  /// @return _interestFactor The latest interest factor
  function interestFactor() external view returns (uint192 _interestFactor);

  /// @notice The protocol's fee
  function protocolFee() external view returns (uint192 _protocolFee);

  /// @notice The max allowed to be set as borrowing fee
  function MAX_INIT_BORROWING_FEE() external view returns (uint192 _maxInitBorrowingFee);

  /// @notice The initial borrowing fee (1e18 == 100%)
  function initialBorrowingFee() external view returns (uint192 _initialBorrowingFee);

  /// @notice The fee taken from the liquidator profit (1e18 == 100%)
  function liquidationFee() external view returns (uint192 _liquidationFee);

  /// @notice Returns an array of all the vault ids a specific wallet has
  /// @param _wallet The address of the wallet to target
  /// @return _vaultIDs The ids of the vaults the wallet has
  function vaultIDs(address _wallet) external view returns (uint96[] memory _vaultIDs);

  /// @notice Returns an array of all enabled tokens
  /// @return _enabledToken The array containing the token addresses
  function enabledTokens(uint256 _index) external view returns (address _enabledToken);

  /// @notice Returns the address of the curve master
  function curveMaster() external view returns (CurveMaster _curveMaster);

  /// @notice Returns the token id given a token's address
  /// @param _tokenAddress The address of the token to target
  /// @return _tokenId The id of the token
  function tokenId(address _tokenAddress) external view returns (uint256 _tokenId);

  /// @notice Returns the oracle given a token's address
  /// @param _tokenAddress The id of the token
  /// @return _oracle The address of the token's oracle
  function tokensOracle(address _tokenAddress) external view returns (IOracleRelay _oracle);

  /// @notice Returns the ltv of a given token address
  /// @param _tokenAddress The address of the token
  /// @return _ltv The loan-to-value of a token
  function tokenLTV(address _tokenAddress) external view returns (uint256 _ltv);

  /// @notice Returns the liquidation incentive of an accepted token collateral
  /// @param _tokenAddress The address of the token
  /// @return _liquidationIncentive The liquidation incentive of the token
  function tokenLiquidationIncentive(address _tokenAddress) external view returns (uint256 _liquidationIncentive);

  /// @notice Returns the cap of a given token address
  /// @param _tokenAddress The address of the token
  /// @return _cap The cap of the token
  function tokenCap(address _tokenAddress) external view returns (uint256 _cap);

  /// @notice Returns the total deposited of a given token address
  /// @param _tokenAddress The address of the token
  /// @return _totalDeposited The total deposited of a token
  function tokenTotalDeposited(address _tokenAddress) external view returns (uint256 _totalDeposited);

  /// @notice Returns the collateral type of a token
  /// @param _tokenAddress The address of the token
  /// @return _type The collateral type of a token
  function tokenCollateralType(address _tokenAddress) external view returns (CollateralType _type);

  /// @notice Returns the address of the crvRewards contract
  /// @param _tokenAddress The address of the token
  /// @return _crvRewardsContract The address of the crvRewards contract
  function tokenCrvRewardsContract(address _tokenAddress) external view returns (IBaseRewardPool _crvRewardsContract);

  /// @notice Returns the pool id of a curve LP type token
  /// @dev    If the token is not of type CurveLPStakedOnConvex then it returns 0
  /// @param _tokenAddress The address of the token
  /// @return _poolId The pool id of a curve LP type token
  function tokenPoolId(address _tokenAddress) external view returns (uint256 _poolId);

  /// @notice Returns the collateral info of a given token address
  /// @param _tokenAddress The address of the token
  /// @return _collateralInfo The complete collateral info of the token
  function tokenCollateralInfo(address _tokenAddress) external view returns (CollateralInfo memory _collateralInfo);

  /// @notice The convex booster interface
  function BOOSTER() external view returns (IBooster _booster);

  /// @notice The amphora claimer interface
  function claimerContract() external view returns (IAMPHClaimer _claimerContract);

  /// @notice The vault deployer interface
  function VAULT_DEPLOYER() external view returns (IVaultDeployer _vaultDeployer);

  /// @notice The max decimals allowed for a listed token
  function MAX_DECIMALS() external view returns (uint8 _maxDecimals);

  /// @notice Returns an array of all enabled tokens
  /// @return _enabledTokens The array containing the token addresses
  function getEnabledTokens() external view returns (address[] memory _enabledTokens);

  /// @notice Returns the selected collaterals info. Will iterate from `_start` (included) until `_end` (not included)
  /// @param _start The start number to loop on the array
  /// @param _end The end number to loop on the array
  /// @return _collateralsInfo The array containing all the collateral info
  function getCollateralsInfo(
    uint256 _start,
    uint256 _end
  ) external view returns (CollateralInfo[] memory _collateralsInfo);

  /// @notice Returns the address of a vault given it's id
  /// @param _vaultID The id of the vault to target
  /// @return _vaultAddress The address of the targetted vault
  function vaultIdVaultAddress(uint96 _vaultID) external view returns (address _vaultAddress);

  /// @notice Returns true if a base reward contract was approved by governance
  /// @param _baseRewardContract The address of the baseRewardcontract to check
  /// @return _approved True if approved by governance
  function baseRewardContracts(address _baseRewardContract) external view returns (bool _approved);

  /// @notice Mapping of token address to collateral info
  function tokenAddressCollateralInfo(address _token)
    external
    view
    returns (
      uint256 _tokenId,
      uint256 _ltv,
      uint256 _cap,
      uint256 _totalDeposited,
      uint256 _liquidationIncentive,
      IOracleRelay _oracle,
      CollateralType _collateralType,
      IBaseRewardPool _crvRewardsContract,
      uint256 _poolId,
      uint256 _decimals
    );

  /// @notice The interest contract
  function interest() external view returns (uint64 _lastTime, uint192 _factor);

  /// @notice The usda interface
  function usda() external view returns (IUSDA _usda);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Returns the amount of USDA needed to reach even solvency without state changes
  /// @dev This amount is a moving target and changes with each block as payInterest is called
  /// @param _id The id of vault we want to target
  /// @return _usdaToSolvency The amount of USDA needed to reach even solvency
  function amountToSolvency(uint96 _id) external view returns (uint256 _usdaToSolvency);

  /// @notice Returns vault liability of vault
  /// @param _id The id of vault
  /// @return _liability The amount of USDA the vault owes
  function vaultLiability(uint96 _id) external view returns (uint192 _liability);

  /// @notice Returns the vault borrowing power for vault
  /// @dev Implementation in getVaultBorrowingPower
  /// @param _id The id of vault we want to target
  /// @return _borrowPower The amount of USDA the vault can borrow
  function vaultBorrowingPower(uint96 _id) external view returns (uint192 _borrowPower);

  /// @notice Returns the calculated amount of tokens to liquidate for a vault
  /// @dev The amount of tokens owed is a moving target and changes with each block as payInterest is called
  ///      This function can serve to give an indication of how many tokens can be liquidated
  ///      All this function does is call _liquidationMath with 2**256-1 as the amount
  /// @param _id The id of vault we want to target
  /// @param _token The address of token to calculate how many tokens to liquidate
  /// @return _tokensToLiquidate The amount of tokens liquidatable
  function tokensToLiquidate(uint96 _id, address _token) external view returns (uint256 _tokensToLiquidate);

  /// @notice Check a vault for over-collateralization
  /// @dev This function calls peekVaultBorrowingPower so no state change is done
  /// @param _id The id of vault we want to target
  /// @return _overCollateralized Returns true if vault over-collateralized; false if vault under-collaterlized
  function peekCheckVault(uint96 _id) external view returns (bool _overCollateralized);

  /// @notice Check a vault for over-collateralization
  /// @dev This function calls getVaultBorrowingPower to allow state changes to happen if an oracle need them
  /// @param _id The id of vault we want to target
  /// @return _overCollateralized Returns true if vault over-collateralized; false if vault under-collaterlized
  function checkVault(uint96 _id) external returns (bool _overCollateralized);

  /// @notice Returns the status of a range of vaults
  /// @dev Special view only function to help liquidators
  /// @param _start The id of the vault to start looping
  /// @param _stop The id of vault to stop looping
  /// @return _vaultSummaries An array of vault information
  function vaultSummaries(uint96 _start, uint96 _stop) external view returns (VaultSummary[] memory _vaultSummaries);

  /// @notice Returns the initial borrowing fee
  /// @param _amount The base amount
  /// @return _fee The fee calculated based on a base amount
  function getBorrowingFee(uint192 _amount) external view returns (uint192 _fee);

  /// @notice Returns the liquidation fee
  /// @param _tokensToLiquidate The collateral amount
  /// @param _assetAddress The collateral address to liquidate
  /// @return _fee The fee calculated based on amount
  function getLiquidationFee(uint192 _tokensToLiquidate, address _assetAddress) external view returns (uint192 _fee);

  /// @notice Returns the increase amount of the interest factor. Accrues interest to borrowers and distribute it to USDA holders
  /// @dev Implementation in payInterest
  /// @return _interest The increase amount of the interest factor
  function calculateInterest() external returns (uint256 _interest);

  /// @notice Creates a new vault and returns it's address
  /// @return _vaultAddress The address of the newly created vault
  function mintVault() external returns (address _vaultAddress);

  /// @notice Simulates the liquidation of an underwater vault
  /// @param _id The id of vault we want to target
  /// @param _assetAddress The address of the token the liquidator wishes to liquidate
  /// @param _tokensToLiquidate The number of tokens to liquidate
  /// @return _collateralLiquidated The number of collateral tokens the liquidator will receive
  /// @return _usdaPaid The amount of USDA the liquidator will have to pay
  function simulateLiquidateVault(
    uint96 _id,
    address _assetAddress,
    uint256 _tokensToLiquidate
  ) external view returns (uint256 _collateralLiquidated, uint256 _usdaPaid);

  /// @notice Liquidates an underwater vault
  /// @dev Pays interest before liquidation. Vaults may be liquidated up to the point where they are exactly solvent
  /// @param _id The id of vault we want to target
  /// @param _assetAddress The address of the token the liquidator wishes to liquidate
  /// @param _tokensToLiquidate The number of tokens to liquidate
  /// @return _toLiquidate The number of tokens that got liquidated
  function liquidateVault(
    uint96 _id,
    address _assetAddress,
    uint256 _tokensToLiquidate
  ) external returns (uint256 _toLiquidate);

  /// @notice Borrows USDA from a vault. Only the vault minter may borrow from their vault
  /// @param _id The id of vault we want to target
  /// @param _amount The amount of USDA to borrow
  function borrowUSDA(uint96 _id, uint192 _amount) external;

  /// @notice Borrows USDA from a vault and send the USDA to a specific address
  /// @param _id The id of vault we want to target
  /// @param _amount The amount of USDA to borrow
  /// @param _target The address to receive borrowed USDA
  function borrowUSDAto(uint96 _id, uint192 _amount, address _target) external;

  /// @notice Borrows sUSD directly from reserve, liability is still in USDA, and USDA must be repaid
  /// @param _id The id of vault we want to target
  /// @param _susdAmount The amount of sUSD to borrow
  /// @param _target The address to receive borrowed sUSD
  function borrowsUSDto(uint96 _id, uint192 _susdAmount, address _target) external;

  /// @notice Repays a vault's USDA loan. Anyone may repay
  /// @dev Pays interest
  /// @param _id The id of vault we want to target
  /// @param _amount The amount of USDA to repay
  function repayUSDA(uint96 _id, uint192 _amount) external;

  /// @notice Repays all of a vault's USDA. Anyone may repay a vault's liabilities
  /// @dev Pays interest
  /// @param _id The id of vault we want to target
  function repayAllUSDA(uint96 _id) external;

  /// @notice External function used by vaults to increase or decrease the `totalDeposited`.
  /// @dev Should only be called by a valid vault
  /// @param _vaultID The id of vault which is calling (used to verify)
  /// @param _amount The amount to modify
  /// @param _token The token address which should modify the total
  /// @param _increase Boolean that indicates if should increase or decrease (TRUE -> increase, FALSE -> decrease)
  function modifyTotalDeposited(uint96 _vaultID, uint256 _amount, address _token, bool _increase) external;

  /// @notice Pauses the functionality of the contract
  function pause() external;

  /// @notice Unpauses the functionality of the contract
  function unpause() external;

  /// @notice Emited when the owner registers a curve master
  /// @param _masterCurveAddress The address of the curve master
  function registerCurveMaster(address _masterCurveAddress) external;

  /// @notice Updates the protocol fee
  /// @param _newProtocolFee The new protocol fee in terms of 1e18=100%
  function changeProtocolFee(uint192 _newProtocolFee) external;

  /// @notice Register a new token to be used as collateral
  /// @param _tokenAddress The address of the token to register
  /// @param _ltv The ltv of the token, 1e18=100%
  /// @param _oracleAddress The address of oracle to fetch the price of the token
  /// @param _liquidationIncentive The liquidation penalty for the token, 1e18=100%
  /// @param _cap The maximum amount to be deposited
  function registerErc20(
    address _tokenAddress,
    uint256 _ltv,
    address _oracleAddress,
    uint256 _liquidationIncentive,
    uint256 _cap,
    uint256 _poolId
  ) external;

  /// @notice Registers the USDA contract
  /// @param _usdaAddress The address to register as USDA
  function registerUSDA(address _usdaAddress) external;

  /// @notice Updates an existing collateral with new collateral parameters
  /// @param _tokenAddress The address of the token to modify
  /// @param _ltv The new loan-to-value of the token, 1e18=100%
  /// @param _oracleAddress The address of oracle to modify for the price of the token
  /// @param _liquidationIncentive The new liquidation penalty for the token, 1e18=100%
  /// @param _cap The maximum amount to be deposited
  /// @param _poolId The convex pool id of a crv lp token
  function updateRegisteredErc20(
    address _tokenAddress,
    uint256 _ltv,
    address _oracleAddress,
    uint256 _liquidationIncentive,
    uint256 _cap,
    uint256 _poolId
  ) external;

  /// @notice Change the claimer contract, used to exchange a fee from curve lp rewards for AMPH tokens
  /// @param _newClaimerContract The new claimer contract
  function changeClaimerContract(IAMPHClaimer _newClaimerContract) external;

  /// @notice Change the initial borrowing fee
  /// @param _newBorrowingFee The new borrowing fee
  function changeInitialBorrowingFee(uint192 _newBorrowingFee) external;

  /// @notice Change the liquidation fee
  /// @param _newLiquidationFee The new liquidation fee
  function changeLiquidationFee(uint192 _newLiquidationFee) external;
}
