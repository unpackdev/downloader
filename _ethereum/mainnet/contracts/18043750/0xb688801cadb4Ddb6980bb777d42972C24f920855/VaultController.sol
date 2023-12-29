// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ExponentialNoError.sol";
import "./CurveMaster.sol";

import "./IUSDA.sol";
import "./IVault.sol";
import "./IVaultController.sol";
import "./IOracleRelay.sol";
import "./IBooster.sol";
import "./IBaseRewardPool.sol";
import "./IAMPHClaimer.sol";
import "./IVaultDeployer.sol";

import "./IERC20Metadata.sol";
import "./Ownable.sol";
import "./Pausable.sol";

/// @notice Controller of all vaults in the USDA borrow/lend system
///         VaultController contains all business logic for borrowing and lending through the protocol.
///         It is also in charge of accruing interest.
contract VaultController is Pausable, IVaultController, ExponentialNoError, Ownable {
  /// @dev The max decimals allowed for a listed token
  uint8 public constant MAX_DECIMALS = 18;

  /// @dev The max allowed to be set as borrowing fee
  uint192 public constant MAX_INIT_BORROWING_FEE = 0.05e18;

  /// @dev The convex booster interface
  IBooster public immutable BOOSTER;

  /// @dev The vault deployer interface
  IVaultDeployer public immutable VAULT_DEPLOYER;

  /// @dev Mapping of vault id to vault address
  mapping(uint96 => address) public vaultIdVaultAddress;

  /// @dev Mapping of wallet address to vault IDs arrays
  mapping(address => uint96[]) public walletVaultIDs;

  /// @dev Mapping of token address to collateral info
  mapping(address => CollateralInfo) public tokenAddressCollateralInfo;

  /// @dev Mapping of all the approved BaseRewardContracts from convex
  mapping(address => bool) public baseRewardContracts;

  /// @dev Array of enabled tokens addresses
  address[] public enabledTokens;

  /// @dev The curve master contract
  CurveMaster public curveMaster;

  /// @dev The interest contract
  Interest public interest;

  /// @dev The usda interface
  IUSDA public usda;

  /// @dev The amphora claimer interface
  IAMPHClaimer public claimerContract;

  /// @dev Total number of minted vaults
  uint96 public vaultsMinted;
  /// @dev Total number of tokens registered
  uint256 public tokensRegistered;
  /// @dev Total base liability
  uint192 public totalBaseLiability;
  /// @dev The protocol's fee
  uint192 public protocolFee;
  /// @dev The initial borrowing fee (1e18 == 100%)
  uint192 public initialBorrowingFee;
  /// @dev The fee taken from the liquidator profit (1e18 == 100%)
  uint192 public liquidationFee;

  /// @notice Any function with this modifier will call the _payInterest() function before
  modifier paysInterest() {
    _payInterest();
    _;
  }

  ///@notice Any function with this modifier can be paused or unpaused by USDA._pauser() in the case of an emergency
  modifier onlyPauser() {
    if (_msgSender() != usda.pauser()) revert VaultController_OnlyPauser();
    _;
  }

  /// @notice Can initialize collaterals from an older vault controller
  /// @param _oldVaultController The old vault controller
  /// @param _tokenAddresses The addresses of the collateral we want to take information for
  /// @param _claimerContract The claimer contract
  /// @param _vaultDeployer The deployer contract
  /// @param _initialBorrowingFee The initial borrowing fee
  /// @param _booster The convex booster address
  /// @param _liquidationFee The liquidation fee
  constructor(
    IVaultController _oldVaultController,
    address[] memory _tokenAddresses,
    IAMPHClaimer _claimerContract,
    IVaultDeployer _vaultDeployer,
    uint192 _initialBorrowingFee,
    address _booster,
    uint192 _liquidationFee
  ) {
    VAULT_DEPLOYER = _vaultDeployer;
    interest = Interest(uint64(block.timestamp), 1 ether);
    protocolFee = 1e14;
    initialBorrowingFee = _initialBorrowingFee;
    liquidationFee = _liquidationFee;

    claimerContract = _claimerContract;

    BOOSTER = IBooster(_booster);

    if (address(_oldVaultController) != address(0)) _migrateCollateralsFrom(_oldVaultController, _tokenAddresses);
  }

  /// @notice Returns the latest interest factor
  /// @return _interestFactor The latest interest factor
  function interestFactor() external view override returns (uint192 _interestFactor) {
    _interestFactor = interest.factor;
  }

  /// @notice Returns the block timestamp when pay interest was last called
  /// @return _lastInterestTime The block timestamp when pay interest was last called
  function lastInterestTime() external view override returns (uint64 _lastInterestTime) {
    _lastInterestTime = interest.lastTime;
  }

  /// @notice Returns an array of all the vault ids a specific wallet has
  /// @param _wallet The address of the wallet to target
  /// @return _vaultIDs The ids of the vaults the wallet has
  function vaultIDs(address _wallet) external view override returns (uint96[] memory _vaultIDs) {
    _vaultIDs = walletVaultIDs[_wallet];
  }

  /// @notice Returns an array of all enabled tokens
  /// @return _enabledTokens The array containing the token addresses
  function getEnabledTokens() external view override returns (address[] memory _enabledTokens) {
    _enabledTokens = enabledTokens;
  }

  /// @notice Returns the token id given a token's address
  /// @param _tokenAddress The address of the token to target
  /// @return _tokenId The id of the token
  function tokenId(address _tokenAddress) external view override returns (uint256 _tokenId) {
    _tokenId = tokenAddressCollateralInfo[_tokenAddress].tokenId;
  }

  /// @notice Returns the oracle given a token's address
  /// @param _tokenAddress The id of the token
  /// @return _oracle The address of the token's oracle
  function tokensOracle(address _tokenAddress) external view override returns (IOracleRelay _oracle) {
    _oracle = tokenAddressCollateralInfo[_tokenAddress].oracle;
  }

  /// @notice Returns the ltv of a given token address
  /// @param _tokenAddress The address of the token
  /// @return _ltv The loan-to-value of a token
  function tokenLTV(address _tokenAddress) external view override returns (uint256 _ltv) {
    _ltv = tokenAddressCollateralInfo[_tokenAddress].ltv;
  }

  /// @notice Returns the liquidation incentive of an accepted token collateral
  /// @param _tokenAddress The address of the token
  /// @return _liquidationIncentive The liquidation incentive of the token
  function tokenLiquidationIncentive(address _tokenAddress)
    external
    view
    override
    returns (uint256 _liquidationIncentive)
  {
    _liquidationIncentive = tokenAddressCollateralInfo[_tokenAddress].liquidationIncentive;
  }

  /// @notice Returns the cap of a given token address
  /// @param _tokenAddress The address of the token
  /// @return _cap The cap of the token
  function tokenCap(address _tokenAddress) external view override returns (uint256 _cap) {
    _cap = tokenAddressCollateralInfo[_tokenAddress].cap;
  }

  /// @notice Returns the total deposited of a given token address
  /// @param _tokenAddress The address of the token
  /// @return _totalDeposited The total deposited of a token
  function tokenTotalDeposited(address _tokenAddress) external view override returns (uint256 _totalDeposited) {
    _totalDeposited = tokenAddressCollateralInfo[_tokenAddress].totalDeposited;
  }

  /// @notice Returns the collateral type of a token
  /// @param _tokenAddress The address of the token
  /// @return _type The collateral type of a token
  function tokenCollateralType(address _tokenAddress) external view override returns (CollateralType _type) {
    _type = tokenAddressCollateralInfo[_tokenAddress].collateralType;
  }

  /// @notice Returns the address of the crvRewards contract
  /// @param _tokenAddress The address of the token
  /// @return _crvRewardsContract The address of the crvRewards contract
  function tokenCrvRewardsContract(address _tokenAddress)
    external
    view
    override
    returns (IBaseRewardPool _crvRewardsContract)
  {
    _crvRewardsContract = tokenAddressCollateralInfo[_tokenAddress].crvRewardsContract;
  }

  /// @notice Returns the pool id of a curve LP type token
  /// @dev    If the token is not of type CurveLPStakedOnConvex then it returns 0
  /// @param _tokenAddress The address of the token
  /// @return _poolId The pool id of a curve LP type token
  function tokenPoolId(address _tokenAddress) external view override returns (uint256 _poolId) {
    _poolId = tokenAddressCollateralInfo[_tokenAddress].poolId;
  }

  /// @notice Returns the collateral info of a given token address
  /// @param _tokenAddress The address of the token
  /// @return _collateralInfo The complete collateral info of the token
  function tokenCollateralInfo(address _tokenAddress)
    external
    view
    override
    returns (CollateralInfo memory _collateralInfo)
  {
    _collateralInfo = tokenAddressCollateralInfo[_tokenAddress];
  }

  /// @notice Returns the selected collaterals info. Will iterate from `_start` (included) until `_end` (not included)
  /// @param _start The start number to loop on the array
  /// @param _end The end number to loop on the array
  /// @return _collateralsInfo The array containing all the collateral info
  function getCollateralsInfo(
    uint256 _start,
    uint256 _end
  ) external view override returns (CollateralInfo[] memory _collateralsInfo) {
    // check if `_end` is bigger than the tokens length
    uint256 _enabledTokensLength = enabledTokens.length;
    _end = _enabledTokensLength < _end ? _enabledTokensLength : _end;

    _collateralsInfo = new CollateralInfo[](_end - _start);

    for (uint256 _i = _start; _i < _end;) {
      _collateralsInfo[_i - _start] = tokenAddressCollateralInfo[enabledTokens[_i]];

      unchecked {
        ++_i;
      }
    }
  }

  /// @notice Migrates all collateral information from previous vault controller
  /// @param _oldVaultController The address of the vault controller to take the information from
  /// @param _tokenAddresses The addresses of the tokens we want to target
  function _migrateCollateralsFrom(IVaultController _oldVaultController, address[] memory _tokenAddresses) internal {
    uint256 _tokenId;
    uint256 _tokensRegistered;
    for (uint256 _i; _i < _tokenAddresses.length;) {
      _tokenId = _oldVaultController.tokenId(_tokenAddresses[_i]);
      if (_tokenId == 0) revert VaultController_WrongCollateralAddress();
      _tokensRegistered++;

      CollateralInfo memory _collateral = _oldVaultController.tokenCollateralInfo(_tokenAddresses[_i]);
      _collateral.tokenId = _tokensRegistered;
      _collateral.totalDeposited = 0;

      enabledTokens.push(_tokenAddresses[_i]);
      tokenAddressCollateralInfo[_tokenAddresses[_i]] = _collateral;

      unchecked {
        ++_i;
      }
    }
    tokensRegistered += _tokensRegistered;

    emit CollateralsMigratedFrom(_oldVaultController, _tokenAddresses);
  }

  /// @notice Creates a new vault and returns it's address
  /// @return _vaultAddress The address of the newly created vault
  function mintVault() public override whenNotPaused returns (address _vaultAddress) {
    // increment  minted vaults
    vaultsMinted += 1;
    // mint the vault itself, deploying the contract
    _vaultAddress = _createVault(vaultsMinted, _msgSender());
    // add the vault to our system
    vaultIdVaultAddress[vaultsMinted] = _vaultAddress;

    //push new vault ID onto mapping
    walletVaultIDs[_msgSender()].push(vaultsMinted);

    // emit the event
    emit NewVault(_vaultAddress, vaultsMinted, _msgSender());
  }

  /// @notice Pauses the functionality of the contract
  function pause() external override onlyPauser {
    _pause();
  }

  /// @notice Unpauses the functionality of the contract
  function unpause() external override onlyPauser {
    _unpause();
  }

  /// @notice Registers the USDA contract
  /// @param _usdaAddress The address to register as USDA
  function registerUSDA(address _usdaAddress) external override onlyOwner {
    usda = IUSDA(_usdaAddress);
    emit RegisterUSDA(_usdaAddress);
  }

  /// @notice Emited when the owner registers a curve master
  /// @param _masterCurveAddress The address of the curve master
  function registerCurveMaster(address _masterCurveAddress) external override onlyOwner {
    curveMaster = CurveMaster(_masterCurveAddress);
    emit RegisterCurveMaster(_masterCurveAddress);
  }

  /// @notice Updates the protocol fee
  /// @param _newProtocolFee The new protocol fee in terms of 1e18=100%
  function changeProtocolFee(uint192 _newProtocolFee) external override onlyOwner paysInterest {
    if (_newProtocolFee >= 1e18) revert VaultController_FeeTooLarge();
    protocolFee = _newProtocolFee;
    emit NewProtocolFee(_newProtocolFee);
  }

  /// @notice Register a new token to be used as collateral
  /// @dev Rebasing tokens are not compatible with amphora due to internal balance tracking
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
  ) external override onlyOwner {
    CollateralInfo storage _collateral = tokenAddressCollateralInfo[_tokenAddress];
    if (_collateral.tokenId != 0) revert VaultController_TokenAlreadyRegistered();
    uint8 _tokenDecimals = IERC20Metadata(_tokenAddress).decimals();
    if (_tokenDecimals > MAX_DECIMALS) revert VaultController_TooManyDecimals();
    if (_poolId != 0) {
      (address _lpToken,,, address _crvRewards,,) = BOOSTER.poolInfo(_poolId);
      if (_lpToken != _tokenAddress) revert VaultController_TokenAddressDoesNotMatchLpAddress();
      _collateral.collateralType = CollateralType.CurveLPStakedOnConvex;
      _collateral.crvRewardsContract = IBaseRewardPool(_crvRewards);
      _collateral.poolId = _poolId;
      baseRewardContracts[_crvRewards] = true;
    } else {
      _collateral.collateralType = CollateralType.Single;
      _collateral.crvRewardsContract = IBaseRewardPool(address(0));
      _collateral.poolId = 0;
    }
    // ltv must be compatible with liquidation incentive
    if (_ltv >= (EXP_SCALE - _liquidationIncentive)) revert VaultController_LTVIncompatible();
    // increment the amount of registered token
    tokensRegistered = tokensRegistered + 1;
    // set & give the token an id
    _collateral.tokenId = tokensRegistered;
    // set the token's oracle
    _collateral.oracle = IOracleRelay(_oracleAddress);
    // set the token's ltv
    _collateral.ltv = _ltv;
    // set the token's liquidation incentive
    _collateral.liquidationIncentive = _liquidationIncentive;
    // set the cap
    _collateral.cap = _cap;
    // save the decimals
    _collateral.decimals = _tokenDecimals;
    // finally, add the token to the array of enabled tokens
    enabledTokens.push(_tokenAddress);

    emit RegisteredErc20(_tokenAddress, _ltv, _oracleAddress, _liquidationIncentive, _cap);
  }

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
  ) external override onlyOwner {
    CollateralInfo storage _collateral = tokenAddressCollateralInfo[_tokenAddress];
    if (_collateral.tokenId == 0) revert VaultController_TokenNotRegistered();
    // _ltv must be compatible with liquidation incentive
    if (_ltv >= (EXP_SCALE - _liquidationIncentive)) revert VaultController_LTVIncompatible();
    if (_poolId != 0) {
      (address _lpToken,,, address _crvRewards,,) = BOOSTER.poolInfo(_poolId);
      if (_lpToken != _tokenAddress) revert VaultController_TokenAddressDoesNotMatchLpAddress();
      _collateral.collateralType = CollateralType.CurveLPStakedOnConvex;
      _collateral.crvRewardsContract = IBaseRewardPool(_crvRewards);
      _collateral.poolId = _poolId;
      baseRewardContracts[_crvRewards] = true;
    } else {
      _collateral.collateralType = CollateralType.Single;
      _collateral.crvRewardsContract = IBaseRewardPool(address(0));
      _collateral.poolId = 0;
    }
    // set the oracle of the token
    _collateral.oracle = IOracleRelay(_oracleAddress);
    // set the ltv of the token
    _collateral.ltv = _ltv;
    // set the liquidation incentive of the token
    _collateral.liquidationIncentive = _liquidationIncentive;
    // set the cap
    _collateral.cap = _cap;

    emit UpdateRegisteredErc20(_tokenAddress, _ltv, _oracleAddress, _liquidationIncentive, _cap, _poolId);
  }

  /// @notice Change the claimer contract, used to exchange a fee from curve lp rewards for AMPH tokens
  /// @param _newClaimerContract The new claimer contract
  function changeClaimerContract(IAMPHClaimer _newClaimerContract) external override onlyOwner {
    IAMPHClaimer _oldClaimerContract = claimerContract;
    claimerContract = _newClaimerContract;

    emit ChangedClaimerContract(_oldClaimerContract, _newClaimerContract);
  }

  /// @notice Change the initial borrowing fee
  /// @param _newBorrowingFee The new borrowing fee
  function changeInitialBorrowingFee(uint192 _newBorrowingFee) external override onlyOwner {
    if (_newBorrowingFee >= MAX_INIT_BORROWING_FEE) revert VaultController_FeeTooLarge();
    uint192 _oldBorrowingFee = initialBorrowingFee;
    initialBorrowingFee = _newBorrowingFee;

    emit ChangedInitialBorrowingFee(_oldBorrowingFee, _newBorrowingFee);
  }

  /// @notice Change the liquidation fee
  /// @param _newLiquidationFee The new liquidation fee
  function changeLiquidationFee(uint192 _newLiquidationFee) external override onlyOwner {
    if (_newLiquidationFee >= 1e18) revert VaultController_FeeTooLarge();
    uint192 _oldLiquidationFee = liquidationFee;
    liquidationFee = _newLiquidationFee;

    emit ChangedLiquidationFee(_oldLiquidationFee, _newLiquidationFee);
  }

  /// @notice Check a vault for over-collateralization
  /// @dev This function calls peekVaultBorrowingPower so no state change is done
  /// @param _id The id of vault we want to target
  /// @return _overCollateralized Returns true if vault over-collateralized; false if vault under-collaterlized
  function peekCheckVault(uint96 _id) public view override returns (bool _overCollateralized) {
    // grab the vault by id if part of our system. revert if not
    IVault _vault = _getVault(_id);
    // calculate the total value of the vault's liquidity
    uint256 _totalLiquidityValue = _peekVaultBorrowingPower(_vault);
    // calculate the total liability of the vault
    uint256 _usdaLiability = _truncate((_vault.baseLiability() * interest.factor));
    // if the ltv >= liability, the vault is solvent
    _overCollateralized = (_totalLiquidityValue >= _usdaLiability);
  }

  /// @notice Check a vault for over-collateralization
  /// @dev This function calls getVaultBorrowingPower to allow state changes to happen if an oracle need them
  /// @param _id The id of vault we want to target
  /// @return _overCollateralized Returns true if vault over-collateralized; false if vault under-collaterlized
  function checkVault(uint96 _id) public returns (bool _overCollateralized) {
    // grab the vault by id if part of our system. revert if not
    IVault _vault = _getVault(_id);
    // calculate the total value of the vault's liquidity
    uint256 _totalLiquidityValue = _getVaultBorrowingPower(_vault);
    // calculate the total liability of the vault
    uint256 _usdaLiability = _truncate((_vault.baseLiability() * interest.factor));
    // if the ltv >= liability, the vault is solvent
    _overCollateralized = (_totalLiquidityValue >= _usdaLiability);
  }

  /// @notice Borrows USDA from a vault. Only the vault minter may borrow from their vault
  /// @param _id The id of vault we want to target
  /// @param _amount The amount of USDA to borrow
  function borrowUSDA(uint96 _id, uint192 _amount) external override {
    _borrow(_id, _amount, _msgSender(), true);
  }

  /// @notice Borrows USDA from a vault and send the USDA to a specific address
  /// @param _id The id of vault we want to target
  /// @param _amount The amount of USDA to borrow
  /// @param _target The address to receive borrowed USDA
  function borrowUSDAto(uint96 _id, uint192 _amount, address _target) external override {
    _borrow(_id, _amount, _target, true);
  }

  /// @notice Borrows sUSD directly from reserve, liability is still in USDA, and USDA must be repaid
  /// @param _id The id of vault we want to target
  /// @param _susdAmount The amount of sUSD to borrow
  /// @param _target The address to receive borrowed sUSD
  function borrowsUSDto(uint96 _id, uint192 _susdAmount, address _target) external override {
    _borrow(_id, _susdAmount, _target, false);
  }

  /// @notice Returns the initial borrowing fee
  /// @param _amount The base amount
  /// @return _fee The fee calculated based on a base amount
  function getBorrowingFee(uint192 _amount) public view override returns (uint192 _fee) {
    // _amount * (100% + initialBorrowingFee)
    _fee = _safeu192(_truncate(uint256(_amount * (1e18 + initialBorrowingFee)))) - _amount;
  }

  /// @notice Returns the liquidation fee
  /// @param _tokensToLiquidate The collateral amount
  /// @param _assetAddress The collateral address to liquidate
  /// @return _fee The fee calculated based on amount
  function getLiquidationFee(
    uint192 _tokensToLiquidate,
    address _assetAddress
  ) public view override returns (uint192 _fee) {
    uint256 _liquidationIncentive = tokenAddressCollateralInfo[_assetAddress].liquidationIncentive;
    // _tokensToLiquidate * (100% + _liquidationIncentive)
    uint192 _liquidatorExpectedProfit =
      _safeu192(_truncate(uint256(_tokensToLiquidate * (1e18 + _liquidationIncentive)))) - _tokensToLiquidate;
    // _liquidatorExpectedProfit * (100% + liquidationFee)
    _fee =
      _safeu192(_truncate(uint256(_liquidatorExpectedProfit * (1e18 + liquidationFee)))) - _liquidatorExpectedProfit;
  }

  /// @notice Business logic to perform the USDA loan
  /// @dev Pays interest
  /// @param _id The vault's id to borrow against
  /// @param _amount The amount of USDA to borrow
  /// @param _target The address to receive borrowed USDA
  /// @param _isUSDA Boolean indicating if the borrowed asset is USDA (if FALSE is sUSD)
  function _borrow(uint96 _id, uint192 _amount, address _target, bool _isUSDA) internal paysInterest whenNotPaused {
    // grab the vault by id if part of our system. revert if not
    IVault _vault = _getVault(_id);
    // only the minter of the vault may borrow from their vault
    if (_msgSender() != _vault.minter()) revert VaultController_OnlyMinter();
    // add the fee
    uint192 _fee = getBorrowingFee(_amount);
    // the base amount is the amount of USDA they wish to borrow divided by the interest factor, accounting for the fee
    uint192 _baseAmount = _safeu192(uint256((_amount + _fee) * EXP_SCALE) / uint256(interest.factor));
    // _baseLiability should contain the vault's new liability, in terms of base units
    // true indicates that we are adding to the liability
    uint256 _baseLiability = _vault.modifyLiability(true, _baseAmount);
    // increase the total base liability by the _baseAmount
    // the same amount we added to the vault's liability
    totalBaseLiability += _baseAmount;
    // now take the vault's total base liability and multiply it by the interest factor
    uint256 _usdaLiability = _truncate(uint256(interest.factor) * _baseLiability);
    // now get the ltv of the vault, aka their borrowing power, in usda
    uint256 _totalLiquidityValue = _getVaultBorrowingPower(_vault);
    // the ltv must be above the newly calculated _usdaLiability, else revert
    if (_totalLiquidityValue < _usdaLiability) revert VaultController_VaultInsolvent();

    if (_isUSDA) {
      // now send usda to the target, equal to the amount they are owed
      usda.vaultControllerMint(_target, _amount);
    } else {
      // send sUSD to the target from reserve instead of mint
      usda.vaultControllerTransfer(_target, _amount);
    }

    // also send the fee to the treasury
    if (_fee > 0) usda.vaultControllerMint(owner(), _fee);

    // emit the event
    emit BorrowUSDA(_id, address(_vault), _amount, _fee);
  }

  /// @notice Repays a vault's USDA loan. Anyone may repay
  /// @dev Pays interest
  /// @param _id The id of vault we want to target
  /// @param _amount The amount of USDA to repay
  function repayUSDA(uint96 _id, uint192 _amount) external override {
    _repay(_id, _amount, false);
  }

  /// @notice Repays all of a vault's USDA. Anyone may repay a vault's liabilities
  /// @dev Pays interest
  /// @param _id The id of vault we want to target
  function repayAllUSDA(uint96 _id) external override {
    _repay(_id, 0, true);
  }

  /// @notice Business logic to perform the USDA repay
  /// @dev Pays interest
  /// @param _id The vault's id to repay
  /// @param _amountInUSDA The amount of USDA to borrow
  /// @param _repayAll Boolean if TRUE, repay all debt
  function _repay(uint96 _id, uint192 _amountInUSDA, bool _repayAll) internal paysInterest whenNotPaused {
    // grab the vault by id if part of our system. revert if not
    IVault _vault = _getVault(_id);
    uint192 _baseAmount;

    // if _repayAll == TRUE, repay total liability
    if (_repayAll) {
      // store the vault baseLiability in memory
      _baseAmount = _safeu192(_vault.baseLiability());
      // get the total USDA liability, equal to the interest factor * vault's base liabilty
      _amountInUSDA = _safeu192(_truncate(interest.factor * _baseAmount));
    } else {
      // the base amount is the amount of USDA entered divided by the interest factor
      _baseAmount = _safeu192((_amountInUSDA * EXP_SCALE) / interest.factor);
    }
    // decrease the total base liability by the calculated base amount
    totalBaseLiability -= _baseAmount;
    // ensure that _baseAmount is lower than the vault's base liability.
    // this may not be needed, since modifyLiability *should* revert if is not true
    if (_baseAmount > _vault.baseLiability()) revert VaultController_RepayTooMuch();
    // decrease the vault's liability by the calculated base amount
    _vault.modifyLiability(false, _baseAmount);
    // burn the amount of USDA submitted from the sender
    usda.vaultControllerBurn(_msgSender(), _amountInUSDA);

    emit RepayUSDA(_id, address(_vault), _amountInUSDA);
  }

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
  ) external view override returns (uint256 _collateralLiquidated, uint256 _usdaPaid) {
    // cannot liquidate 0
    if (_tokensToLiquidate == 0) revert VaultController_LiquidateZeroTokens();
    // check for registered asset
    if (tokenAddressCollateralInfo[_assetAddress].tokenId == 0) revert VaultController_TokenNotRegistered();

    // calculate the amount to liquidate and the 'bad fill price' using liquidationMath
    // see _liquidationMath for more detailed explaination of the math
    (uint256 _tokenAmount, uint256 _badFillPrice) = _peekLiquidationMath(_id, _assetAddress, _tokensToLiquidate);
    // set _tokensToLiquidate to this calculated amount if the function does not fail
    _collateralLiquidated = _tokenAmount != 0 ? _tokenAmount : _tokensToLiquidate;
    // the USDA to repurchase is equal to the bad fill price multiplied by the amount of tokens to liquidate
    _usdaPaid = _truncate(_badFillPrice * _collateralLiquidated);
    // extract fee
    _collateralLiquidated -= getLiquidationFee(uint192(_collateralLiquidated), _assetAddress);
  }

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
  ) external override paysInterest whenNotPaused returns (uint256 _toLiquidate) {
    // cannot liquidate 0
    if (_tokensToLiquidate == 0) revert VaultController_LiquidateZeroTokens();
    // check for registered asset
    if (tokenAddressCollateralInfo[_assetAddress].tokenId == 0) revert VaultController_TokenNotRegistered();

    // calculate the amount to liquidate and the 'bad fill price' using liquidationMath
    // see _liquidationMath for more detailed explaination of the math
    (uint256 _tokenAmount, uint256 _badFillPrice) = _liquidationMath(_id, _assetAddress, _tokensToLiquidate);
    // set _tokensToLiquidate to this calculated amount if the function does not fail
    if (_tokenAmount > 0) _tokensToLiquidate = _tokenAmount;
    // the USDA to repurchase is equal to the bad fill price multiplied by the amount of tokens to liquidate
    uint256 _usdaToRepurchase = _truncate(_badFillPrice * _tokensToLiquidate);
    // get the vault that the liquidator wishes to liquidate
    IVault _vault = _getVault(_id);

    // decrease the vault's liability
    _vault.modifyLiability(false, (_usdaToRepurchase * 1e18) / interest.factor);

    // decrease the total base liability
    totalBaseLiability -= _safeu192((_usdaToRepurchase * 1e18) / interest.factor);

    // decrease liquidator's USDA balance
    usda.vaultControllerBurn(_msgSender(), _usdaToRepurchase);

    // withdraw from convex
    if (_vault.currentPoolIds(_assetAddress) != 0) {
      _vault.controllerWithdrawAndUnwrap(_assetAddress, _tokensToLiquidate);
    }

    uint192 _liquidationFee = getLiquidationFee(uint192(_tokensToLiquidate), _assetAddress);

    // finally, deliver tokens to liquidator
    _vault.controllerTransfer(_assetAddress, _msgSender(), _tokensToLiquidate - _liquidationFee);
    // and the fee to the treasury
    _vault.controllerTransfer(_assetAddress, owner(), _liquidationFee);
    // and reduces total
    _modifyTotalDeposited(_tokensToLiquidate, _assetAddress, false);

    // this mainly prevents reentrancy
    if (_getVaultBorrowingPower(_vault) > _vaultLiability(_id)) revert VaultController_OverLiquidation();

    // emit the event
    emit Liquidate(_id, _assetAddress, _usdaToRepurchase, _tokensToLiquidate - _liquidationFee, _liquidationFee);
    // return the amount of tokens liquidated (including fee)
    _toLiquidate = _tokensToLiquidate;
  }

  /// @notice Returns the calculated amount of tokens to liquidate for a vault
  /// @dev The amount of tokens owed is a moving target and changes with each block as payInterest is called
  ///      This function can serve to give an indication of how many tokens can be liquidated
  ///      All this function does is call _liquidationMath with 2**256-1 as the amount
  /// @param _id The id of vault we want to target
  /// @param _assetAddress The address of token to calculate how many tokens to liquidate
  /// @return _tokensToLiquidate The amount of tokens liquidatable
  function tokensToLiquidate(
    uint96 _id,
    address _assetAddress
  ) external view override returns (uint256 _tokensToLiquidate) {
    (
      _tokensToLiquidate, // bad fill price
    ) = _peekLiquidationMath(_id, _assetAddress, 2 ** 256 - 1);
  }

  /// @notice Internal function with business logic for liquidation math without any state changes
  /// @param _id The vault to get info for
  /// @param _assetAddress The token to calculate how many tokens to liquidate
  /// @param _tokensToLiquidate The max amount of tokens one wishes to liquidate
  /// @return _actualTokensToLiquidate The amount of tokens underwater this vault is
  /// @return _badFillPrice The bad fill price for the token
  function _peekLiquidationMath(
    uint96 _id,
    address _assetAddress,
    uint256 _tokensToLiquidate
  ) internal view returns (uint256 _actualTokensToLiquidate, uint256 _badFillPrice) {
    //require that the vault is not solvent
    if (peekCheckVault(_id)) revert VaultController_VaultSolvent();

    CollateralInfo memory _collateral = tokenAddressCollateralInfo[_assetAddress];
    uint256 _price = _collateral.oracle.peekValue();
    uint256 _usdaToSolvency = _peekAmountToSolvency(_id);

    (_actualTokensToLiquidate, _badFillPrice) =
      _calculateTokensToLiquidate(_collateral, _id, _tokensToLiquidate, _assetAddress, _price, _usdaToSolvency);
  }

  /// @notice Internal function with business logic for liquidation math
  /// @param _id The vault to get info for
  /// @param _assetAddress The token to calculate how many tokens to liquidate
  /// @param _tokensToLiquidate The max amount of tokens one wishes to liquidate
  /// @return _actualTokensToLiquidate The amount of tokens underwater this vault is
  /// @return _badFillPrice The bad fill price for the token
  function _liquidationMath(
    uint96 _id,
    address _assetAddress,
    uint256 _tokensToLiquidate
  ) internal returns (uint256 _actualTokensToLiquidate, uint256 _badFillPrice) {
    //require that the vault is not solvent
    if (checkVault(_id)) revert VaultController_VaultSolvent();

    CollateralInfo memory _collateral = tokenAddressCollateralInfo[_assetAddress];
    uint256 _price = _collateral.oracle.currentValue();
    uint256 _usdaToSolvency = _amountToSolvency(_id);

    (_actualTokensToLiquidate, _badFillPrice) =
      _calculateTokensToLiquidate(_collateral, _id, _tokensToLiquidate, _assetAddress, _price, _usdaToSolvency);
  }

  /// @notice Calculates the amount of tokens to liquidate for a vault
  /// @param _collateral The collateral to liquidate
  /// @param _id The vault to calculate the liquidation
  /// @param _tokensToLiquidate The max amount of tokens one wishes to liquidate
  /// @param _assetAddress The token to calculate how many tokens to liquidate
  /// @param _price The price of the collateral
  /// @param _usdaToSolvency The amount of USDA needed to make the vault solvent
  /// @return _actualTokensToLiquidate The amount of tokens underwater this vault is
  /// @return _badFillPrice The bad fill price for the token
  function _calculateTokensToLiquidate(
    CollateralInfo memory _collateral,
    uint96 _id,
    uint256 _tokensToLiquidate,
    address _assetAddress,
    uint256 _price,
    uint256 _usdaToSolvency
  ) internal view returns (uint256 _actualTokensToLiquidate, uint256 _badFillPrice) {
    IVault _vault = _getVault(_id);
    uint256 _priceWithDecimals = _getPriceWithDecimals(_price, _collateral.decimals);
    // get price discounted by liquidation penalty
    // price * (100% - liquidationIncentive)
    _badFillPrice = _truncate(_priceWithDecimals * (1e18 - _collateral.liquidationIncentive));

    // the ltv discount is the amount of collateral value that one token provides
    uint256 _ltvDiscount = _truncate(_priceWithDecimals * _collateral.ltv);
    // this number is the denominator when calculating the _maxTokensToLiquidate
    // it is simply the badFillPrice - ltvDiscount
    uint256 _denominator = _badFillPrice - _ltvDiscount;

    // the maximum amount of tokens to liquidate is the amount that will bring the vault to solvency
    // divided by the denominator
    uint256 _maxTokensToLiquidate = (_usdaToSolvency * 1e18) / _denominator;
    //Cannot liquidate more than is necessary to make vault over-collateralized
    if (_tokensToLiquidate > _maxTokensToLiquidate) _tokensToLiquidate = _maxTokensToLiquidate;

    uint256 _balance = _vault.balances(_assetAddress);

    //Cannot liquidate more collateral than there is in the vault
    if (_tokensToLiquidate > _balance) _tokensToLiquidate = _balance;

    _actualTokensToLiquidate = _tokensToLiquidate;
  }

  /// @notice Internal helper function to wrap getting of vaults
  /// @dev It will revert if the vault does not exist
  /// @param _id The id of vault
  /// @return _vault The vault for that id
  function _getVault(uint96 _id) internal view returns (IVault _vault) {
    address _vaultAddress = vaultIdVaultAddress[_id];
    if (_vaultAddress == address(0)) revert VaultController_VaultDoesNotExist();
    _vault = IVault(_vaultAddress);
  }

  /// @notice Returns the amount of USDA needed to reach even solvency without state changes
  /// @dev This amount is a moving target and changes with each block as payInterest is called
  /// @param _id The id of vault we want to target
  /// @return _usdaToSolvency The amount of USDA needed to reach even solvency
  function amountToSolvency(uint96 _id) external view override returns (uint256 _usdaToSolvency) {
    if (peekCheckVault(_id)) revert VaultController_VaultSolvent();
    _usdaToSolvency = _peekAmountToSolvency(_id);
  }

  /// @notice Bussiness logic for amountToSolvency without any state changes
  /// @param _id The id of vault
  /// @return _usdaToSolvency The amount of USDA needed to reach even solvency
  function _peekAmountToSolvency(uint96 _id) internal view returns (uint256 _usdaToSolvency) {
    _usdaToSolvency = _vaultLiability(_id) - _peekVaultBorrowingPower(_getVault(_id));
  }

  /// @notice Bussiness logic for amountToSolvency
  /// @param _id The id of vault
  /// @return _usdaToSolvency The amount of USDA needed to reach even solvency
  function _amountToSolvency(uint96 _id) internal returns (uint256 _usdaToSolvency) {
    _usdaToSolvency = _vaultLiability(_id) - _getVaultBorrowingPower(_getVault(_id));
  }

  /// @notice Returns vault liability of vault
  /// @param _id The id of vault
  /// @return _liability The amount of USDA the vault owes
  function vaultLiability(uint96 _id) external view override returns (uint192 _liability) {
    _liability = _vaultLiability(_id);
  }

  /// @notice Returns the liability of a vault
  /// @dev Implementation in _vaultLiability
  /// @param _id The id of vault we want to target
  /// @return _liability The amount of USDA the vault owes
  function _vaultLiability(uint96 _id) internal view returns (uint192 _liability) {
    address _vaultAddress = vaultIdVaultAddress[_id];
    if (_vaultAddress == address(0)) revert VaultController_VaultDoesNotExist();
    IVault _vault = IVault(_vaultAddress);
    _liability = _safeu192(_truncate(_vault.baseLiability() * interest.factor));
  }

  /// @notice Returns the vault borrowing power for vault
  /// @dev Implementation in getVaultBorrowingPower
  /// @param _id The id of vault we want to target
  /// @return _borrowPower The amount of USDA the vault can borrow
  function vaultBorrowingPower(uint96 _id) external view override returns (uint192 _borrowPower) {
    uint192 _bp = _peekVaultBorrowingPower(_getVault(_id));
    _borrowPower = _bp - getBorrowingFee(_bp);
  }

  /// @notice Returns the borrowing power of a vault
  /// @param _vault The vault to get the borrowing power of
  /// @return _borrowPower The borrowing power of the vault
  //solhint-disable-next-line code-complexity
  function _getVaultBorrowingPower(IVault _vault) private returns (uint192 _borrowPower) {
    CollateralInfo memory _collateral;
    address _tokenAddress;
    uint256 _balance;
    uint192 _rawPrice;
    uint192 _tokenValue;

    // loop over each registered token, adding the individuals ltv to the total ltv of the vault
    for (uint192 _i; _i < enabledTokens.length;) {
      unchecked {
        ++_i;
      }
      _collateral = tokenAddressCollateralInfo[enabledTokens[_i - 1]];
      // if the ltv is 0, continue
      if (_collateral.ltv == 0) continue;
      // get the address of the token through the array of enabled tokens
      // note that index 0 of enabledTokens corresponds to a vaultId of 1, so we must subtract 1 from i to get the correct index
      _tokenAddress = enabledTokens[_i - 1];
      // the balance is the vault's token balance of the current collateral token in the loop
      _balance = _vault.balances(_tokenAddress);
      if (_balance == 0) continue;
      // the raw price is simply the oracle price of the token
      _rawPrice = _safeu192(_collateral.oracle.currentValue());
      if (_rawPrice == 0) continue;
      // the token value is equal to the price * balance * tokenLTV
      _tokenValue = _safeu192(
        _truncate(_truncate(_balance * _collateral.ltv * _getPriceWithDecimals(_rawPrice, _collateral.decimals)))
      );
      // increase the ltv of the vault by the token value
      _borrowPower += _tokenValue;
    }
  }

  /// @notice Returns the borrowing power of a vault without making state changes
  /// @param _vault The vault to get the borrowing power of
  /// @return _borrowPower The borrowing power of the vault
  //solhint-disable-next-line code-complexity
  function _peekVaultBorrowingPower(IVault _vault) private view returns (uint192 _borrowPower) {
    // loop over each registed token, adding the indivuduals ltv to the total ltv of the vault
    for (uint192 _i; _i < enabledTokens.length; ++_i) {
      CollateralInfo memory _collateral = tokenAddressCollateralInfo[enabledTokens[_i]];
      // if the ltv is 0, continue
      if (_collateral.ltv == 0) continue;
      // get the address of the token through the array of enabled tokens
      // note that index 0 of enabledTokens corresponds to a vaultId of 1, so we must subtract 1 from i to get the correct index
      address _tokenAddress = enabledTokens[_i];
      // the balance is the vault's token balance of the current collateral token in the loop
      uint256 _balance = _vault.balances(_tokenAddress);
      if (_balance == 0) continue;
      // the raw price is simply the oracle price of the token
      uint192 _rawPrice = _safeu192(_collateral.oracle.peekValue());
      if (_rawPrice == 0) continue;
      // the token value is equal to the price * balance * tokenLTV
      uint192 _tokenValue = _safeu192(
        _truncate(_truncate(_balance * _collateral.ltv * _getPriceWithDecimals(_rawPrice, _collateral.decimals)))
      );
      // increase the ltv of the vault by the token value
      _borrowPower += _tokenValue;
    }
  }

  /// @notice Returns the increase amount of the interest factor. Accrues interest to borrowers and distribute it to USDA holders
  /// @dev Implementation in payInterest
  /// @return _interest The increase amount of the interest factor
  function calculateInterest() external override returns (uint256 _interest) {
    _interest = _payInterest();
  }

  /// @notice Accrue interest to borrowers and distribute it to USDA holders.
  /// @dev This function is called before any function that changes the reserve ratio
  /// @return _interest The interest to distribute to USDA holders
  function _payInterest() private returns (uint256 _interest) {
    // calculate the time difference between the current block and the last time the block was called
    uint64 _timeDifference = uint64(block.timestamp) - interest.lastTime;
    // if the time difference is 0, there is no interest. this saves gas in the case that
    // if multiple users call interest paying functions in the same block
    if (_timeDifference == 0) return 0;
    // the current reserve ratio, cast to a uint256
    uint256 _ui18 = uint256(usda.reserveRatio());
    // cast the reserve ratio now to an int in order to get a curve value
    int256 _reserveRatio = int256(_ui18);
    // calculate the value at the curve. this vault controller is a USDA vault and will reference
    // the vault at address 0
    int256 _intCurveVal = curveMaster.getValueAt(address(0), _reserveRatio);
    // cast the integer curve value to a u192
    uint192 _curveVal = _safeu192(uint256(_intCurveVal));
    // calculate the amount of total outstanding loans before and after this interest accrual
    // first calculate how much the interest factor should increase by
    // this is equal to (timedifference * (curve value) / (seconds in a year)) * (interest factor)
    uint192 _e18FactorIncrease = _safeu192(
      _truncate(
        _truncate((uint256(_timeDifference) * uint256(1e18) * uint256(_curveVal)) / (365 days + 6 hours))
          * uint256(interest.factor)
      )
    );
    // get the total outstanding value before we increase the interest factor
    uint192 _valueBefore = _safeu192(_truncate(uint256(totalBaseLiability) * uint256(interest.factor)));
    // interest is a struct which contains the last timestamp and the current interest factor
    // set the value of this struct to a struct containing {(current block timestamp), (interest factor + increase)}
    // this should save ~5000 gas/call
    interest = Interest(uint64(block.timestamp), interest.factor + _e18FactorIncrease);
    // using that new value, calculate the new total outstanding value
    uint192 _valueAfter = _safeu192(_truncate(uint256(totalBaseLiability) * uint256(interest.factor)));
    // valueAfter - valueBefore is now equal to the true amount of interest accured
    // this mitigates rounding errors
    // the protocol's fee amount is equal to this value multiplied by the protocol fee percentage, 1e18=100%
    uint192 _protocolAmount = _safeu192(_truncate(uint256(_valueAfter - _valueBefore) * uint256(protocolFee)));
    // donate the true amount of interest less the amount which the protocol is taking for itself
    // this donation is what pays out interest to USDA holders
    usda.vaultControllerDonate(_valueAfter - _valueBefore - _protocolAmount);
    // send the protocol's fee to the owner of this contract.
    usda.vaultControllerMint(owner(), _protocolAmount);
    // emit the event
    emit InterestEvent(uint64(block.timestamp), _e18FactorIncrease, _curveVal);
    // return the interest factor increase
    _interest = _e18FactorIncrease;
  }

  /// @notice Deploys a new Vault
  /// @param _id The id of the vault
  /// @param _minter The address of the minter of the vault
  /// @return _vault The vault that was created
  function _createVault(uint96 _id, address _minter) internal virtual returns (address _vault) {
    _vault = address(VAULT_DEPLOYER.deployVault(_id, _minter));
  }

  /// @notice Returns the status of a range of vaults
  /// @dev Special view only function to help liquidators
  /// @param _start The id of the vault to start looping
  /// @param _stop The id of vault to stop looping
  /// @return _vaultSummaries An array of vault information
  function vaultSummaries(
    uint96 _start,
    uint96 _stop
  ) public view override returns (VaultSummary[] memory _vaultSummaries) {
    if (_stop > vaultsMinted) _stop = vaultsMinted;
    _vaultSummaries = new VaultSummary[](_stop - _start + 1);
    for (uint96 _i = _start; _i <= _stop;) {
      IVault _vault = _getVault(_i);
      uint256[] memory _tokenBalances = new uint256[](enabledTokens.length);

      for (uint256 _j; _j < enabledTokens.length;) {
        _tokenBalances[_j] = _vault.balances(enabledTokens[_j]);

        unchecked {
          ++_j;
        }
      }
      _vaultSummaries[_i - _start] =
        VaultSummary(_i, _peekVaultBorrowingPower(_vault), this.vaultLiability(_i), enabledTokens, _tokenBalances);

      unchecked {
        ++_i;
      }
    }
  }

  /// @notice Modifies the total deposited in the protocol
  function _modifyTotalDeposited(uint256 _amount, address _token, bool _increase) internal {
    CollateralInfo memory _collateral = tokenAddressCollateralInfo[_token];
    if (_collateral.tokenId == 0) revert VaultController_TokenNotRegistered();
    if (_increase && (_collateral.totalDeposited + _amount) > _collateral.cap) revert VaultController_CapReached();

    tokenAddressCollateralInfo[_token].totalDeposited =
      _increase ? _collateral.totalDeposited + _amount : _collateral.totalDeposited - _amount;
  }

  /// @notice External function used by vaults to increase or decrease the `totalDeposited`.
  /// @dev Should only be called by a valid vault
  /// @param _vaultID The id of vault which is calling (used to verify)
  /// @param _amount The amount to modify
  /// @param _token The token address which should modify the total
  /// @param _increase Boolean that indicates if should increase or decrease (TRUE -> increase, FALSE -> decrease)
  function modifyTotalDeposited(uint96 _vaultID, uint256 _amount, address _token, bool _increase) external override {
    if (_msgSender() != vaultIdVaultAddress[_vaultID]) revert VaultController_NotValidVault();
    _modifyTotalDeposited(_amount, _token, _increase);
  }

  // @notice Returns the price adjusting to the decimals of the token
  // @param _price The price to adjust
  // @param _decimals The decimals of the token
  // @return _priceWithDecimals The price with the decimals of the token
  function _getPriceWithDecimals(uint256 _price, uint256 _decimals) internal pure returns (uint256 _priceWithDecimals) {
    _priceWithDecimals = _price * 10 ** (18 - _decimals);
  }
}
