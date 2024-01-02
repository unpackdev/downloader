// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

/// Import from Core /////
import "./TRSY.sol";
import "./AssetRegistry.sol";
import "./AddressRegistry.sol";
import "./ProtocolState.sol";
import "./Tax.sol";
import "./GovernanceAccess.sol";

/// Structs /////
import "./Structs.sol";

/// Utils /////
import "./Ownable.sol";
import "./PercentageMath.sol";
import "./SafeERC20.sol";

//Interfaces
import "./IERC20.sol";
import "./IOracle.sol";
import "./IRelayer.sol";

///@title Fyde contract
///@notice Fyde is the main contract of the protocol, it handles logic of deposit and withdraw in
/// the protocol
///        Deposit and withdraw occurs a mint or a burn of TRSY (ERC20 that represent shares of the
/// procotol in USD value)
///        Users can both deposit/withdraw in standard or governance pool
contract Fyde is TRSY, AddressRegistry, ProtocolState, AssetRegistry, GovernanceAccess, Tax {
  using SafeERC20 for IERC20;
  /*//////////////////////////////////////////////////////////////
                            EVENTS
  //////////////////////////////////////////////////////////////*/

  event FeesCollected(address indexed recipient, uint256 trsyFeesCollected);
  event Deposit(uint32 requestId, uint256 trsyPrice, uint256 usdDepositValue, uint256 trsyMinted);
  event Withdraw(uint32 requestId, uint256 trsyPrice, uint256 usdWithdrawValue, uint256 trsyBurned);
  event Swap(uint32 requestId, address assetOut, uint256 amountOut);
  event ManagementFeeCollected(uint256 feeToMint);

  /*//////////////////////////////////////////////////////////////
                              ERROR
  //////////////////////////////////////////////////////////////*/

  error AumNotInRange();
  error OnlyOneUpdatePerBlock();
  error SlippageExceed();
  error FydeBalanceInsufficient();
  error InsufficientTRSYBalance();
  error AssetPriceNotAvailable();
  error SwapAmountNotAvailable();
  error AssetNotSupported(address asset);
  error SwapDisabled(address asset);
  error AssetIsQuarantined(address asset);

  /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

  constructor(
    address _relayer,
    address _oracleModule,
    address _governanceModule,
    uint16 _maxAumDeviationAllowed,
    uint72 _taxFactor,
    uint72 _managementFee
  ) Ownable(msg.sender) AddressRegistry(_governanceModule, _relayer) {
    oracleModule = IOracle(_oracleModule);
    updateMaxAumDeviationAllowed(_maxAumDeviationAllowed);
    updateTaxFactor(_taxFactor);
    updateManagementFee(_managementFee);
    _updateLastFeeCollectionTime();
  }

  /*//////////////////////////////////////////////////////////////
                                AUTH
  //////////////////////////////////////////////////////////////*/

  ///@notice Collect and send TRSY fees (from tax fees) to an external address
  ///@param _recipient Address to send TRSY fees to
  ///@param _amount Amount of TRSY to send
  function collectFees(address _recipient, uint256 _amount) external onlyOwner {
    _checkZeroAddress(_recipient);
    _checkZeroValue(_amount);
    balanceOf[address(this)] -= _amount;
    balanceOf[_recipient] += _amount;
    emit FeesCollected(_recipient, _amount);
  }

  ///@notice Collect management fee by inflating TRSY and minting to Fyde
  ///        is called by the relayer when processingRequests
  function collectManagementFee() external {
    uint256 feePerSecond = uint256(protocolData.managementFee / 31_557_600);
    uint256 timePeriod = block.timestamp - protocolData.lastFeeCollectionTime;
    if (timePeriod == 0) return;
    uint256 feeToMint = feePerSecond * timePeriod * totalSupply / 1e18;
    _updateLastFeeCollectionTime();
    _mint(address(this), feeToMint);
    emit ManagementFeeCollected(feeToMint);
  }

  /*//////////////////////////////////////////////////////////////
                  RELAYER & KEEPER FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  ///@notice Update protocol AUM, called by keeper
  ///@param _aum New AUM
  ///@dev Can at most be updated by maxDeviationThreshold and only once per block
  function updateProtocolAUM(uint256 _aum) external {
    if (msg.sender != RELAYER && msg.sender != owner) revert Unauthorized();
    if (block.number == protocolData.lastAUMUpdateBlock) revert CoolDownPeriodActive();
    protocolData.lastAUMUpdateBlock = uint48(block.number);
    (, uint256 limitedAum) = _AumIsInRange(_aum);
    _updateProtocolAUM(limitedAum);
  }

  /*//////////////////////////////////////////////////////////////
                  PROCESSING DEPOSIT ACTIONS
  //////////////////////////////////////////////////////////////*/

  ///@notice Process deposit action, called by relayer
  ///@param _protocolAUM AUM given by keeper
  ///@param _req RequestData struct
  ///@return totalUsdDeposit USD value of the deposit
  function processDeposit(uint256 _protocolAUM, RequestData calldata _req)
    external
    onlyRelayer
    returns (uint256)
  {
    // Check if asset is supported
    _checkIsSupported(_req.assetIn);
    _checkIsNotQuarantined(_req.assetIn);

    // is keeper AUM in range
    (bool isInRange,) = _AumIsInRange(_protocolAUM);
    if (!isInRange) revert AumNotInRange();

    (
      ProcessParam[] memory processParam,
      uint256 sharesToMint,
      uint256 taxInTRSY,
      uint256 totalUsdDeposit
    ) = getProcessParamDeposit(_req, _protocolAUM);

    // Slippage checker
    if (_req.slippageChecker > sharesToMint) revert SlippageExceed();

    // Transfer assets to Fyde
    for (uint256 i; i < _req.assetIn.length; i++) {
      IERC20(_req.assetIn[i]).safeTransferFrom(_req.requestor, address(this), _req.amountIn[i]);
    }

    if (_req.keepGovRights) _govDeposit(_req, processParam);
    else _standardDeposit(_req, sharesToMint);

    // Mint tax and keep in contract
    if (taxInTRSY > 0) _mint(address(this), taxInTRSY);
    _updateProtocolAUM(_protocolAUM + totalUsdDeposit);

    uint256 trsyPrice = (1e18 * (_protocolAUM + totalUsdDeposit)) / totalSupply;
    emit Deposit(_req.id, trsyPrice, totalUsdDeposit, sharesToMint);
    return totalUsdDeposit;
  }

  function _standardDeposit(RequestData calldata _req, uint256 _sharesToMint) internal {
    // Accounting
    _increaseAssetTotalAmount(_req.assetIn, _req.amountIn);

    // Minting shares
    _mint(_req.requestor, _sharesToMint);
  }

  function _govDeposit(RequestData calldata _req, ProcessParam[] memory _processParam) internal {
    uint256[] memory sharesAfterTax = new uint256[](_req.assetIn.length);
    uint256[] memory amountInAfterTax = new uint256[](_req.assetIn.length);
    // Same average tax rate is applied to each asset
    uint256 taxMultiplicator;
    uint256 totalTrsy;
    for (uint256 i; i < _req.assetIn.length; i++) {
      taxMultiplicator = 1e18 * _processParam[i].sharesAfterTax / (_processParam[i].sharesBeforeTax);
      amountInAfterTax[i] = _req.amountIn[i] * taxMultiplicator / 1e18;
      sharesAfterTax[i] = _processParam[i].sharesAfterTax;
      totalTrsy += sharesAfterTax[i];
    }

    // Mint stTRSY and transfer token into proxy
    address proxy = GOVERNANCE_MODULE.govDeposit(
      _req.requestor, _req.assetIn, amountInAfterTax, sharesAfterTax, totalTrsy
    );

    for (uint256 i; i < _req.assetIn.length; i++) {
      IERC20(_req.assetIn[i]).safeTransfer(proxy, amountInAfterTax[i]);
    }

    // Accounting
    _increaseAssetTotalAmount(_req.assetIn, _req.amountIn);
    _increaseAssetProxyAmount(_req.assetIn, amountInAfterTax);

    // Mint
    _mint(address(GOVERNANCE_MODULE), totalTrsy);
  }

  /*//////////////////////////////////////////////////////////////
                  PROCESSING WITHDRAW ACTIONS
  //////////////////////////////////////////////////////////////*/

  ///@notice Process withdraw action, called by relayer
  ///@param _protocolAUM AUM given by keeper
  ///@param _req RequestData struct
  ///@return totalUsdWithdraw USD value of the withdraw
  function processWithdraw(uint256 _protocolAUM, RequestData calldata _req)
    external
    onlyRelayer
    returns (uint256)
  {
    // Check if asset is supported
    _checkIsSupported(_req.assetOut);
    _checkIsNotQuarantined(_req.assetOut);

    // is keeper AUM in range
    (bool isInRange,) = _AumIsInRange(_protocolAUM);
    if (!isInRange) revert AumNotInRange();

    uint256 totalUsdWithdraw;
    uint256 totalSharesToBurn;

    (totalUsdWithdraw, totalSharesToBurn) =
      _req.keepGovRights ? _govWithdraw(_protocolAUM, _req) : _standardWithdraw(_protocolAUM, _req);

    // Accounting
    _decreaseAssetTotalAmount(_req.assetOut, _req.amountOut);
    _updateProtocolAUM(_protocolAUM - totalUsdWithdraw);

    // Calculate for offchain purpose
    uint256 trsyPrice =
      totalSupply != 0 ? (1e18 * (_protocolAUM - totalUsdWithdraw)) / totalSupply : 0;
    emit Withdraw(_req.id, trsyPrice, totalUsdWithdraw, totalSharesToBurn);
    return totalUsdWithdraw;
  }

  function _govWithdraw(uint256 _protocolAUM, RequestData calldata _req)
    internal
    returns (uint256, uint256)
  {
    uint256 usdVal = getQuote(_req.assetOut[0], _req.amountOut[0]);

    if (usdVal == 0) revert AssetPriceNotAvailable();

    uint256 trsyToBurn = _convertToShares(usdVal, _protocolAUM);
    if (_req.slippageChecker < trsyToBurn) revert SlippageExceed();

    _burn(address(GOVERNANCE_MODULE), trsyToBurn);

    _decreaseAssetProxyAmount(_req.assetOut, _req.amountOut);

    GOVERNANCE_MODULE.govWithdraw(_req.requestor, _req.assetOut[0], _req.amountOut[0], trsyToBurn);
    IERC20(_req.assetOut[0]).safeTransfer(_req.requestor, _req.amountOut[0]);

    return (usdVal, trsyToBurn);
  }

  function _standardWithdraw(uint256 _protocolAUM, RequestData calldata _req)
    internal
    returns (uint256, uint256)
  {
    // check if requested token are available
    for (uint256 i = 0; i < _req.assetOut.length; i++) {
      if (standardAssetAccounting(_req.assetOut[i]) < _req.amountOut[i]) {
        revert FydeBalanceInsufficient();
      }
    }

    (, uint256 totalSharesToBurn,, uint256 taxInTRSY, uint256 totalUsdWithdraw) =
      getProcessParamWithdraw(_req, _protocolAUM);

    if (totalSharesToBurn > _req.slippageChecker) revert SlippageExceed();

    if (balanceOf[_req.requestor] < totalSharesToBurn) revert InsufficientTRSYBalance();

    _burn(_req.requestor, totalSharesToBurn);

    // Give tax to this contract
    if (taxInTRSY > 0) _mint(address(this), taxInTRSY);

    for (uint256 i = 0; i < _req.assetOut.length; i++) {
      // Send asset to recipient
      IERC20(_req.assetOut[i]).safeTransfer(_req.requestor, _req.amountOut[i]);
    }

    return (totalUsdWithdraw, totalSharesToBurn);
  }

  /*//////////////////////////////////////////////////////////////
                              SWAP
  //////////////////////////////////////////////////////////////*/

  function processSwap(uint256 _protocolAUM, RequestData calldata _req)
    external
    onlyRelayer
    returns (int256)
  {
    // Check if asset is supported
    _checkIsSupported(_req.assetIn);
    _checkIsSupported(_req.assetOut);
    _checkIsNotQuarantined(_req.assetIn);
    _checkIsNotQuarantined(_req.assetOut);
    _checkIfSwapAllowed(_req.assetIn);
    _checkIfSwapAllowed(_req.assetOut);

    // is keeper AUM in range
    (bool isInRange,) = _AumIsInRange(_protocolAUM);
    if (!isInRange) revert AumNotInRange();

    (uint256 amountOut, int256 deltaAUM) =
      getSwapAmountOut(_req.assetIn[0], _req.amountIn[0], _req.assetOut[0], _protocolAUM);
    if (amountOut == 0) revert SwapAmountNotAvailable();

    if (amountOut < _req.slippageChecker) revert SlippageExceed();

    // Check enough asset in protocol
    if (standardAssetAccounting(_req.assetOut[0]) < amountOut) revert FydeBalanceInsufficient();

    // Update AUM
    uint256 aum;
    // If the swapper pays net tax, we mint the corresponding TRSY to fyde. This way TRSY price
    // stays constant
    if (deltaAUM > 0) {
      aum = _protocolAUM + uint256(deltaAUM);
      _mint(address(this), _convertToShares(uint256(deltaAUM), _protocolAUM));
      // If incentives are higher tan taxes, we burn TRSY from fyde, to keep TRSY price constant
      // as backup if not enough TRSY in Fyde, we don't burn, i.e. TRSY price goes down and
      // incentives are
      // paid by pool
      // this way by frequently cashing out TRSY from fyde we can manually decide how much tax to
      // keep for ourselves
      // or leave in Fyde for incentives
    } else if (deltaAUM < 0) {
      aum = _protocolAUM - uint256(-deltaAUM);
      uint256 trsyToBurn = _convertToShares(uint256(-deltaAUM), _protocolAUM);
      trsyToBurn = balanceOf[address(this)] >= trsyToBurn ? trsyToBurn : balanceOf[address(this)];
      if (trsyToBurn != 0) _burn(address(this), trsyToBurn);
    } else {
      aum = _protocolAUM;
    }

    _updateProtocolAUM(aum);

    // Log accounting
    _increaseAssetTotalAmount(_req.assetIn[0], _req.amountIn[0]);
    _decreaseAssetTotalAmount(_req.assetOut[0], amountOut);

    // Transfer asset
    IERC20(_req.assetIn[0]).safeTransferFrom(_req.requestor, address(this), _req.amountIn[0]);
    IERC20(_req.assetOut[0]).safeTransfer(_req.requestor, amountOut);

    emit Swap(_req.id, _req.assetOut[0], amountOut);
    return deltaAUM;
  }

  /*///////////////////////////////////////////////////////////////
                              GETTERS
  //////////////////////////////////////////////////////////////*/

  ///@notice Give a quote for a speficic asset deposit
  ///@param _asset asset address to quote
  ///@param _amount amount of asset to deposit
  ///@return USD value of the specified deposit (return 18 decimals, 1USD = 1e18)
  ///@dev    If price is inconsistent or not available, returns 0 from oracle module -> needs proper
  ///        handling
  function getQuote(address _asset, uint256 _amount) public view override returns (uint256) {
    AssetInfo memory _assetInfo = assetInfo[_asset];
    uint256 price = oracleModule.getPriceInUSD(_asset, _assetInfo);
    return (_amount * price) / (10 ** _assetInfo.assetDecimals);
  }

  ///@notice Get the USD value of an asset in the protocol
  ///@param _asset asset address
  ///@return USD value of the asset
  ///@dev    If price is inconsistent or not available, returns 0 -> needs proper handling
  function getAssetAUM(address _asset) public view returns (uint256) {
    return getQuote(_asset, totalAssetAccounting[_asset]);
  }

  ///@notice Compute the USD AUM for the protocol
  ///@dev Should NOT be call within a contract (GAS EXPENSIVE), called off-chain by keeper
  function computeProtocolAUM() public view returns (uint256) {
    address asset;
    uint256 aum;
    uint256 assetAUM;
    address[] memory nAsset = assetsList;
    uint256 length = nAsset.length;
    for (uint256 i = 0; i < length; ++i) {
      asset = nAsset[i];
      if (totalAssetAccounting[asset] == 0) continue;
      assetAUM = getAssetAUM(asset);
      if (assetAUM == 0) return protocolData.aum;
      aum += assetAUM;
    }
    return aum;
  }

  /*//////////////////////////////////////////////////////////////
                        PROCESS PARAM
  //////////////////////////////////////////////////////////////*/

  ///@notice Return the process param for a deposit
  ///@param _req RequestData struct
  ///@param _protocolAUM AUM given by keeper
  ///@return processParam array of ProcessParam struct
  ///@return sharesToMint amount of shares to mint
  ///@return taxInTRSY amount of tax in TRSY
  ///@return totalUsdDeposit USD value of the depositn
  function getProcessParamDeposit(RequestData memory _req, uint256 _protocolAUM)
    public
    view
    returns (
      ProcessParam[] memory processParam,
      uint256 sharesToMint,
      uint256 taxInTRSY,
      uint256 totalUsdDeposit
    )
  {
    processParam = new ProcessParam[](_req.assetIn.length);

    // Build data struct and compute value of deposit
    for (uint256 i; i < _req.assetIn.length; i++) {
      uint256 usdVal = getQuote(_req.assetIn[i], _req.amountIn[i]);
      if (usdVal == 0) revert AssetPriceNotAvailable();

      processParam[i] = ProcessParam({
        targetConc: assetInfo[_req.assetIn[i]].targetConcentration,
        currentConc: _getAssetConcentration(_req.assetIn[i], _protocolAUM),
        usdValue: usdVal,
        sharesBeforeTax: _convertToShares(usdVal, _protocolAUM),
        taxableAmount: 0,
        taxInUSD: 0,
        sharesAfterTax: 0
      });

      totalUsdDeposit += usdVal;
    }

    for (uint256 i; i < processParam.length; i++) {
      // Get the TaxInUSD
      processParam[i] =
        _getDepositTax(processParam[i], _protocolAUM, totalUsdDeposit, protocolData.taxFactor);

      // Apply tax to the deposit
      processParam[i].sharesAfterTax =
        _convertToShares(processParam[i].usdValue - processParam[i].taxInUSD, _protocolAUM);
      sharesToMint += processParam[i].sharesAfterTax;
      taxInTRSY += processParam[i].sharesBeforeTax - processParam[i].sharesAfterTax;
    }

    return (processParam, sharesToMint, taxInTRSY, totalUsdDeposit);
  }

  ///@notice Return the process param for a withdraw
  ///@param _req RequestData struct
  ///@param _protocolAUM AUM given by keeper
  ///@return processParam array of ProcessParam struct
  ///@return totalSharesToBurn amount of shares to burn
  ///@return sharesToBurnBeforeTax amount of shares to burn before tax
  ///@return taxInTRSY amount of tax in TRSY
  ///@return totalUsdWithdraw USD value of the withdraw
  function getProcessParamWithdraw(RequestData calldata _req, uint256 _protocolAUM)
    public
    view
    returns (
      ProcessParam[] memory processParam,
      uint256 totalSharesToBurn,
      uint256 sharesToBurnBeforeTax,
      uint256 taxInTRSY,
      uint256 totalUsdWithdraw
    )
  {
    processParam = new ProcessParam[](_req.assetOut.length);

    // Build data struct and compute value of deposit
    for (uint256 i; i < _req.assetOut.length; i++) {
      uint256 usdVal = getQuote(_req.assetOut[i], _req.amountOut[i]);
      if (usdVal == 0) revert AssetPriceNotAvailable();

      processParam[i] = ProcessParam({
        targetConc: assetInfo[_req.assetOut[i]].targetConcentration,
        currentConc: _getAssetConcentration(_req.assetOut[i], _protocolAUM),
        usdValue: usdVal,
        sharesBeforeTax: 0,
        taxableAmount: 0,
        taxInUSD: 0,
        sharesAfterTax: 0
      });

      totalUsdWithdraw += usdVal;
    }

    for (uint256 i; i < processParam.length; i++) {
      // Get the TaxInUSD
      processParam[i] =
        _getWithdrawTax(processParam[i], _protocolAUM, totalUsdWithdraw, protocolData.taxFactor);
      taxInTRSY += _convertToShares(processParam[i].taxInUSD, _protocolAUM);
    }

    sharesToBurnBeforeTax = _convertToShares(totalUsdWithdraw, _protocolAUM);
    totalSharesToBurn = sharesToBurnBeforeTax + taxInTRSY;
  }

  ///@notice Return the amountOut for a swap accounting for tax and incentive
  ///@param _assetIn asset address to swap
  ///@param _amountIn amount of asset to swap
  ///@param _assetOut asset address to receive
  ///@param _protocolAUM AUM given by keeper
  function getSwapAmountOut(
    address _assetIn,
    uint256 _amountIn,
    address _assetOut,
    uint256 _protocolAUM
  ) public view returns (uint256, int256) {
    // Scope to avoid stack too deep
    {
      uint256 usdValIn = getQuote(_assetIn, _amountIn);
      uint256 assetOutPrice = getQuote(_assetOut, 10 ** assetInfo[_assetOut].assetDecimals);
      if (usdValIn == 0 || assetOutPrice == 0) return (0, int256(0));
    }

    ProcessParam memory processParamIn = ProcessParam({
      targetConc: assetInfo[_assetIn].targetConcentration,
      currentConc: _getAssetConcentration(_assetIn, _protocolAUM),
      usdValue: getQuote(_assetIn, _amountIn),
      sharesBeforeTax: 0,
      taxableAmount: 0,
      taxInUSD: 0,
      sharesAfterTax: 0
    });

    ProcessParam memory processParamOut = ProcessParam({
      targetConc: assetInfo[_assetOut].targetConcentration,
      currentConc: _getAssetConcentration(_assetOut, _protocolAUM),
      usdValue: 0,
      sharesBeforeTax: 0,
      taxableAmount: 0,
      taxInUSD: 0,
      sharesAfterTax: 0
    });

    uint256 usdAmountOut = _getSwapRate(
      processParamIn,
      processParamOut,
      _protocolAUM,
      protocolData.taxFactor,
      assetInfo[_assetIn].incentiveFactor,
      assetInfo[_assetOut].incentiveFactor
    );

    return (
      1e18 * usdAmountOut / getQuote(_assetOut, 1e18),
      int256(processParamIn.usdValue) - int256(usdAmountOut)
    );
  }

  /*//////////////////////////////////////////////////////////////
                            INTERNAL
  //////////////////////////////////////////////////////////////*/

  ///@notice Return asset concentration with keeper AUM
  ///@param _asset asset address
  ///@param _protocolAUM AUM given by keeper
  ///@return current concentration for an asset
  ///@dev    If price is inconsistent or not available, returns 0 -> needs proper handling
  function _getAssetConcentration(address _asset, uint256 _protocolAUM)
    internal
    view
    returns (uint256)
  {
    // To avoid division by 0
    if (_protocolAUM == 0 && protocolData.aum == 0) return 0;
    return (1e20 * getAssetAUM(_asset)) / _protocolAUM;
  }

  ///@notice Perform the comparison between AUM registry and one given by Keeper, return limited AUM
  /// if out of bounds
  function _AumIsInRange(uint256 _keeperAUM) internal view returns (bool, uint256) {
    uint16 maxAumDeviationAllowed = protocolData.maxAumDeviationAllowed;
    uint256 currAum = protocolData.aum;
    uint256 lowerBound = PercentageMath.percentSub(currAum, maxAumDeviationAllowed);
    uint256 upperBound = PercentageMath.percentAdd(currAum, maxAumDeviationAllowed);
    if (_keeperAUM < lowerBound) return (false, lowerBound);
    if (_keeperAUM > upperBound) return (false, upperBound);
    return (true, _keeperAUM);
  }

  function _checkIsSupported(address[] memory _assets) internal view {
    address notSupportedAsset = isAnyNotSupported(_assets);
    if (notSupportedAsset != address(0x0)) revert AssetNotSupported(notSupportedAsset);
  }

  function _checkIsNotQuarantined(address[] memory _assets) internal view {
    address quarantinedAsset = IRelayer(RELAYER).isAnyQuarantined(_assets);
    if (quarantinedAsset != address(0x0)) revert AssetIsQuarantined(quarantinedAsset);
  }

  function _checkIfSwapAllowed(address[] memory _assets) internal view {
    address notAllowedAsset = isSwapAllowed(_assets);
    if (notAllowedAsset != address(0x0)) revert SwapDisabled(notAllowedAsset);
  }

  /*//////////////////////////////////////////////////////////////
                            MODIFIERS
  //////////////////////////////////////////////////////////////*/

  modifier onlyRelayer() {
    if (msg.sender != RELAYER) revert Unauthorized();
    _;
  }
}
