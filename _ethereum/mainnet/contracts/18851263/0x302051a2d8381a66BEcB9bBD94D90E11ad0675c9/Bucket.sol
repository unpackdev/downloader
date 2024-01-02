// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./WadRayMath.sol";

import "./TokenTransfersLibrary.sol";
import "./TokenApproveLibrary.sol";

import "./BucketStorage.sol";
import "./Constants.sol";
import "./Constants.sol";
import "./IBucket.sol";

/* solhint-disable max-states-count */
contract Bucket is IBucketV2, BucketStorage {
    using WadRayMath for uint256;

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Modifier that checks if the caller has a specific role.
     * @param _role The role identifier to check.
     */
    modifier onlyRole(bytes32 _role) {
        _require(IAccessControl(registry).hasRole(_role, msg.sender), Errors.FORBIDDEN.selector);
        _;
    }

    /**
     * @inheritdoc IBucket
     */
    function initialize(ConstructorParams calldata _params, address _registry) public override initializer {
        _require(
            IERC165Upgradeable(_registry).supportsInterface(type(IAccessControl).interfaceId) &&
                IERC165Upgradeable(address(_params.pToken)).supportsInterface(type(IPToken).interfaceId) &&
                IERC165Upgradeable(address(_params.dns)).supportsInterface(type(IPrimexDNS).interfaceId) &&
                IERC165Upgradeable(address(_params.debtToken)).supportsInterface(type(IDebtToken).interfaceId) &&
                IERC165Upgradeable(address(_params.positionManager)).supportsInterface(
                    type(IPositionManager).interfaceId
                ) &&
                IERC165Upgradeable(address(_params.priceOracle)).supportsInterface(type(IPriceOracle).interfaceId) &&
                IERC165Upgradeable(address(_params.reserve)).supportsInterface(type(IReserve).interfaceId) &&
                IERC165Upgradeable(address(_params.interestRateStrategy)).supportsInterface(
                    type(IInterestRateStrategy).interfaceId
                ) &&
                IERC165Upgradeable(address(_params.whiteBlackList)).supportsInterface(
                    type(IWhiteBlackList).interfaceId
                ),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        _require(
            _params.borrowedAsset.decimals() <= MAX_ASSET_DECIMALS,
            Errors.ASSET_DECIMALS_EXCEEDS_MAX_VALUE.selector
        );
        _require(_params.withdrawalFeeRate <= WadRayMath.WAD / 10, Errors.WITHDRAW_RATE_IS_MORE_10_PERCENT.selector);
        _require(
            _params.feeBuffer > WadRayMath.WAD && _params.feeBuffer < WadRayMath.WAD + WadRayMath.WAD / 100,
            Errors.INVALID_FEE_BUFFER.selector
        );
        _require(_params.reserveRate < WadRayMath.WAD, Errors.RESERVE_RATE_SHOULD_BE_LESS_THAN_1.selector);
        _require(_params.maxTotalDeposit > 0, Errors.MAX_TOTAL_DEPOSIT_IS_ZERO.selector);

        if (_params.liquidityMiningAmount == 0) {
            LMparams.isBucketLaunched = true;
            emit BucketLaunched();
        } else {
            _require(
                _params.liquidityMiningDeadline > block.timestamp &&
                    IERC165Upgradeable(address(_params.liquidityMiningRewardDistributor)).supportsInterface(
                        type(ILiquidityMiningRewardDistributor).interfaceId
                    ) &&
                    _params.maxAmountPerUser > 0,
                Errors.INCORRECT_LIQUIDITY_MINING_PARAMS.selector
            );
            LMparams.maxStabilizationEndTimestamp = _params.liquidityMiningDeadline + _params.stabilizationDuration;
            LMparams.maxDuration = LMparams.maxStabilizationEndTimestamp - block.timestamp;
            LMparams.liquidityMiningRewardDistributor = _params.liquidityMiningRewardDistributor;
            LMparams.accumulatingAmount = _params.liquidityMiningAmount;
            LMparams.deadlineTimestamp = _params.liquidityMiningDeadline;
            LMparams.stabilizationDuration = _params.stabilizationDuration;
            LMparams.maxAmountPerUser = _params.maxAmountPerUser;
            estimatedBar = _params.estimatedBar;
            estimatedLar = _params.estimatedLar;
            isReinvestToAaveEnabled = _params.isReinvestToAaveEnabled;
        }
        maxTotalDeposit = _params.maxTotalDeposit;
        _params.interestRateStrategy.setBarCalculationParams(_params.barCalcParams);
        name = _params.name;
        pToken = _params.pToken;
        dns = _params.dns;
        positionManager = _params.positionManager;
        priceOracle = _params.priceOracle;
        debtToken = _params.debtToken;
        reserve = _params.reserve;
        whiteBlackList = _params.whiteBlackList;
        borrowedAsset = _params.borrowedAsset;
        feeBuffer = _params.feeBuffer;
        withdrawalFeeRate = _params.withdrawalFeeRate;
        reserveRate = _params.reserveRate;

        for (uint256 i; i < _params.assets.length; i++) {
            _addAsset(_params.assets[i]);
        }
        registry = _registry;
        interestRateStrategy = _params.interestRateStrategy;
        liquidityIndex = 1e27;
        variableBorrowIndex = 1e27;
        __ReentrancyGuard_init();
        __ERC165_init();
    }

    /**
     * @inheritdoc IBucket
     */
    function addAsset(address _newAsset) external override {
        _onlyRole(MEDIUM_TIMELOCK_ADMIN);
        _addAsset(_newAsset);
    }

    /**
     * @inheritdoc IBucket
     */
    function removeAsset(address _assetToDelete) external override {
        _onlyRole(SMALL_TIMELOCK_ADMIN);
        Asset storage assetToDelete = allowedAssets[_assetToDelete];
        _require(assetToDelete.isSupported, Errors.ASSET_IS_NOT_SUPPORTED.selector);

        address assetToMove = assets[assets.length - 1];
        assets[assetToDelete.index] = assetToMove;
        assets.pop();

        allowedAssets[assetToMove].index = assetToDelete.index;
        delete allowedAssets[_assetToDelete];

        emit RemoveAsset(_assetToDelete);
    }

    function setBarCalculationParams(bytes calldata _params) external override {
        _onlyRole(BIG_TIMELOCK_ADMIN);
        interestRateStrategy.setBarCalculationParams(_params);
        emit BarCalculationParamsChanged(_params);
    }

    /**
     * @inheritdoc IBucket
     */
    function setReserveRate(uint256 _reserveRate) external override {
        _onlyRole(BIG_TIMELOCK_ADMIN);
        _require(_reserveRate < WadRayMath.WAD, Errors.RESERVE_RATE_SHOULD_BE_LESS_THAN_1.selector);
        reserveRate = _reserveRate;
        emit ReserveRateChanged(_reserveRate);
    }

    /**
     * @inheritdoc IBucket
     */
    function setFeeBuffer(uint256 _feeBuffer) external override {
        _onlyRole(MEDIUM_TIMELOCK_ADMIN);
        _require(
            _feeBuffer > WadRayMath.WAD && _feeBuffer < WadRayMath.WAD + WadRayMath.WAD / 100,
            Errors.INVALID_FEE_BUFFER.selector
        );
        feeBuffer = _feeBuffer;
        emit FeeBufferChanged(_feeBuffer);
    }

    /**
     * @inheritdoc IBucket
     */
    function setWithdrawalFee(uint256 _withdrawalFeeRate) external override {
        _onlyRole(BIG_TIMELOCK_ADMIN);
        _require(_withdrawalFeeRate <= WadRayMath.WAD / 10, Errors.WITHDRAW_RATE_IS_MORE_10_PERCENT.selector);
        withdrawalFeeRate = _withdrawalFeeRate;
        emit WithdrawalFeeChanged(_withdrawalFeeRate);
    }

    /**
     * @inheritdoc IBucket
     */
    function setInterestRateStrategy(address _interestRateStrategy) external override {
        _onlyRole(BIG_TIMELOCK_ADMIN);
        _require(
            IERC165Upgradeable(_interestRateStrategy).supportsInterface(type(IInterestRateStrategy).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        interestRateStrategy = IInterestRateStrategy(_interestRateStrategy);
        emit InterestRateStrategyChanged(_interestRateStrategy);
    }

    /**
     * @inheritdoc IBucket
     */
    function setMaxTotalDeposit(uint256 _maxTotalDeposit) external override {
        _onlyRole(MEDIUM_TIMELOCK_ADMIN);
        _require(_maxTotalDeposit > 0, Errors.MAX_TOTAL_DEPOSIT_IS_ZERO.selector);
        maxTotalDeposit = _maxTotalDeposit;
        emit MaxTotalDepositChanged(_maxTotalDeposit);
    }

    /**
     * @inheritdoc IBucket
     */
    function deposit(address _pTokenReceiver, uint256 _amount) external override {
        deposit(_pTokenReceiver, _amount, true);
    }

    /**
     * @inheritdoc IBucketV2
     */
    function deposit(
        address _pTokenReceiver,
        uint256 _amount,
        bool _takeDepositFromWallet
    ) public override nonReentrant {
        _notBlackListed();
        _require(pToken.totalSupply() + _amount < maxTotalDeposit, Errors.DEPOSIT_EXCEEDS_MAX_TOTAL_DEPOSIT.selector);
        if (_takeDepositFromWallet) {
            TokenTransfersLibrary.doTransferIn(address(borrowedAsset), msg.sender, _amount);
        } else {
            positionManager.traderBalanceVault().withdrawFrom(
                msg.sender,
                address(this),
                address(borrowedAsset),
                _amount,
                false
            );
        }
        if (LMparams.isBucketLaunched) {
            _deposit(_pTokenReceiver, _amount);
        } else {
            _require(_pTokenReceiver == msg.sender, Errors.CALLER_IS_NOT_P_TOKEN_RECEIVER.selector);
            _depositLM(_pTokenReceiver, _amount);
        }
        emit Deposit(msg.sender, _pTokenReceiver, _amount);
    }

    /**
     * @inheritdoc IBucket
     */
    function withdrawAfterDelisting(uint256 _amount) external override {
        _onlyRole(BIG_TIMELOCK_ADMIN);
        _require(isWithdrawAfterDelistingAvailable(), Errors.WITHDRAWAL_NOT_ALLOWED.selector);
        TokenTransfersLibrary.doTransferOut(address(borrowedAsset), dns.treasury(), _amount);
    }

    /**
     * @inheritdoc IBucket
     */
    function receiveDeposit(
        address _pTokenReceiver,
        uint256 _amount,
        uint256 _duration,
        string calldata _bucketFrom
    ) external override nonReentrant {
        _require(pToken.totalSupply() + _amount < maxTotalDeposit, Errors.DEPOSIT_EXCEEDS_MAX_TOTAL_DEPOSIT.selector);
        _require(dns.getBucketAddress(_bucketFrom) == msg.sender, Errors.FORBIDDEN.selector);
        if (LMparams.isBucketLaunched) {
            if (_duration > 0) pToken.lockDeposit(_pTokenReceiver, _deposit(_pTokenReceiver, _amount), _duration);
        } else {
            _depositLM(_pTokenReceiver, _amount);
        }
        emit Deposit(msg.sender, _pTokenReceiver, _amount);
    }

    /**
     * @inheritdoc IBucket
     */
    function depositFromBucket(
        string calldata _bucketTo,
        ISwapManager _swapManager,
        PrimexPricingLibrary.Route[] calldata routes,
        uint256 _amountOutMin
    ) external override nonReentrant {
        _notBlackListed();
        // don't need check that _bucketTo isn't this bucket name
        // tx will be reverted by ReentrancyGuard
        _require(
            !LMparams.isBucketLaunched && block.timestamp > LMparams.deadlineTimestamp,
            Errors.DEADLINE_IS_NOT_PASSED.selector
        );
        if (isReinvestToAaveEnabled && aaveDeposit > 0) {
            _withdrawBucketLiquidityFromAave();
        }
        IBucket receiverBucket = IBucket(dns.getBucketAddress(_bucketTo));

        LMparams.liquidityMiningRewardDistributor.reinvest(
            name,
            _bucketTo,
            msg.sender,
            receiverBucket.getLiquidityMiningParams().isBucketLaunched,
            LMparams.deadlineTimestamp
        );

        uint256 allUserBalance = pToken.burn(msg.sender, type(uint256).max, liquidityIndex);
        emit Withdraw(msg.sender, address(receiverBucket), allUserBalance);
        IERC20Metadata bucketToAsset = receiverBucket.borrowedAsset();
        if (bucketToAsset != borrowedAsset) {
            // Need this check that _swapManager is legit.
            // Without it, user can specify any address of _swapManager to withdraw their funds with an extra reward
            _require(
                IAccessControl(registry).hasRole(VAULT_ACCESS_ROLE, address(_swapManager)),
                Errors.FORBIDDEN.selector
            );
            TokenApproveLibrary.doApprove(address(borrowedAsset), address(_swapManager), allUserBalance);
            allUserBalance = _swapManager.swap(
                ISwapManager.SwapParams({
                    tokenA: address(borrowedAsset),
                    tokenB: address(bucketToAsset),
                    amountTokenA: allUserBalance,
                    amountOutMin: _amountOutMin,
                    routes: routes,
                    receiver: address(receiverBucket),
                    deadline: block.timestamp,
                    isSwapFromWallet: true,
                    isSwapToWallet: true,
                    isSwapFeeInPmx: false,
                    payFeeFromWallet: false
                }),
                0,
                false
            );
        } else {
            TokenTransfersLibrary.doTransferOut(address(borrowedAsset), address(receiverBucket), allUserBalance);
        }

        receiverBucket.receiveDeposit(msg.sender, allUserBalance, LMparams.stabilizationDuration, name);
    }

    /**
     * @inheritdoc IBucket
     */
    function returnLiquidityFromAaveToBucket() external override {
        _onlyRole(SMALL_TIMELOCK_ADMIN);
        _withdrawBucketLiquidityFromAave();
    }

    /**
     * @inheritdoc IBucket
     */
    function withdraw(address _borrowAssetReceiver, uint256 _amount) external override nonReentrant {
        _notBlackListed();
        if (!LMparams.isBucketLaunched) {
            LMparams.liquidityMiningRewardDistributor.removePoints(name, msg.sender, _amount);
        } else if (block.timestamp < LMparams.stabilizationEndTimestamp) {
            _require(
                _amount <=
                    pToken.balanceOf(msg.sender) -
                        LMparams.liquidityMiningRewardDistributor.getLenderAmountInMining(name, msg.sender),
                Errors.MINING_AMOUNT_WITHDRAW_IS_LOCKED_ON_STABILIZATION_PERIOD.selector
            );
        }

        if (LMparams.isBucketLaunched) _updateIndexes();
        uint256 amountToWithdraw = pToken.burn(msg.sender, _amount, liquidityIndex);
        uint256 amountToLender = (WadRayMath.WAD - withdrawalFeeRate).wmul(amountToWithdraw);
        uint256 amountToTreasury = amountToWithdraw - amountToLender;
        if (!LMparams.isBucketLaunched && isReinvestToAaveEnabled && aaveDeposit > 0) {
            // if liquidity mining failed, take all tokens from aave during first withdraw from bucket
            if (block.timestamp > LMparams.deadlineTimestamp) {
                _withdrawBucketLiquidityFromAave();
            } else {
                // if liquidity mining is in progress, withdraw needed amount from aave
                address aavePool = dns.aavePool();
                IPool(aavePool).withdraw(address(borrowedAsset), amountToWithdraw, address(this));
                emit WithdrawFromAave(aavePool, amountToWithdraw);
                aaveDeposit -= amountToWithdraw;
            }
        }

        _require(
            amountToWithdraw <= borrowedAsset.balanceOf(address(this)),
            Errors.NOT_ENOUGH_LIQUIDITY_IN_THE_BUCKET.selector
        );

        TokenTransfersLibrary.doTransferOut(address(borrowedAsset), dns.treasury(), amountToTreasury);
        emit TopUpTreasury(msg.sender, amountToTreasury);

        TokenTransfersLibrary.doTransferOut(address(borrowedAsset), _borrowAssetReceiver, amountToLender);
        if (LMparams.isBucketLaunched) _updateRates();

        emit Withdraw(msg.sender, _borrowAssetReceiver, amountToWithdraw);
    }

    /**
     * @inheritdoc IBucket
     */
    function increaseDebt(address _trader, uint256 _amount, address _to) external override {
        _onlyRole(PM_ROLE);
        _require(LMparams.isBucketLaunched, Errors.BUCKET_IS_NOT_LAUNCHED.selector);
        TokenTransfersLibrary.doTransferOut(address(borrowedAsset), _to, _amount);
        _updateIndexes();
        debtToken.mint(_trader, _amount, variableBorrowIndex);
        _updateRates();
    }

    /**
     * @inheritdoc IBucket
     */
    function decreaseTraderDebt(
        address _trader,
        uint256 _debtToBurn,
        address _receiverOfAmountToReturn,
        uint256 _amountToReturn,
        uint256 _permanentLossAmount
    ) external override {
        _onlyRole(PM_ROLE);
        // don't need require on isBucketLaunched,
        // because if we can't openPosition in this bucket then we can't closePosition in this bucket
        if (_amountToReturn > 0) {
            TokenTransfersLibrary.doTransferOut(address(borrowedAsset), _receiverOfAmountToReturn, _amountToReturn);
        }
        _updateIndexes();
        debtToken.burn(_trader, _debtToBurn, variableBorrowIndex);
        _updateRates();
        if (_permanentLossAmount > 0) {
            permanentLossScaled += _permanentLossAmount.rdiv(liquidityIndex);
        }
    }

    /**
     * @inheritdoc IBucket
     */
    function batchDecreaseTradersDebt(
        address[] calldata _traders,
        uint256[] calldata _debtsToBurn,
        address _receiverOfAmountToReturn,
        uint256 _amountToReturn,
        uint256 _permanentLossAmount,
        uint256 _length
    ) external override {
        _onlyRole(BATCH_MANAGER_ROLE);
        // don't need require on isBucketLaunched,
        // because if we can't openPosition in this bucket then we can't closePosition in this bucket
        if (_amountToReturn > 0) {
            TokenTransfersLibrary.doTransferOut(address(borrowedAsset), _receiverOfAmountToReturn, _amountToReturn);
        }
        _updateIndexes();
        debtToken.batchBurn(_traders, _debtsToBurn, variableBorrowIndex, _length);
        _updateRates();
        if (_permanentLossAmount > 0) {
            permanentLossScaled += _permanentLossAmount.rdiv(liquidityIndex);
        }
    }

    /**
     * @inheritdoc IBucket
     */
    function getLiquidityMiningParams() external view override returns (LiquidityMiningParams memory) {
        return LMparams;
    }

    /**
     * @inheritdoc IBucket
     */
    function isDeprecated() external view override returns (bool) {
        (, IPrimexDNSStorage.Status status, , ) = dns.buckets(name);
        return status == IPrimexDNSStorage.Status.Deprecated;
    }

    /**
     * @inheritdoc IBucket
     */
    function isActive() external view override returns (bool) {
        (, IPrimexDNSStorage.Status status, , ) = dns.buckets(name);
        return status == IPrimexDNSStorage.Status.Active;
    }

    /**
     * @inheritdoc IBucket
     */
    function isDelisted() external view override returns (bool) {
        (, IPrimexDNSStorage.Status status, uint256 delistingDeadline, ) = dns.buckets(name);
        return status == IPrimexDNSStorage.Status.Deprecated && delistingDeadline < block.timestamp;
    }

    /**
     * @inheritdoc IBucket
     */
    function isBucketStable() external view override returns (bool) {
        return LMparams.isBucketLaunched && block.timestamp > LMparams.stabilizationEndTimestamp;
    }

    /**
     * @inheritdoc IBucket
     */
    function maxAssetLeverage(address _asset) external view override returns (uint256) {
        _require(allowedAssets[_asset].isSupported, Errors.ASSET_IS_NOT_SUPPORTED.selector);
        uint256 maintenanceBuffer = positionManager.maintenanceBuffer();
        //  The formula is:
        //  (WAD + maintenanceBuffer) feeBuffer /
        //  ((WAD + maintenanceBuffer) feeBuffer) -
        //  (WAD - securityBuffer) (WAD - pairPriceDropBA) (WAD - oracleTolerableLimitAB) (WAD - oracleTolerableLimitBA)
        return
            (WadRayMath.WAD + maintenanceBuffer).wmul(feeBuffer).wdiv(
                (WadRayMath.WAD + maintenanceBuffer).wmul(feeBuffer) -
                    (WadRayMath.WAD - positionManager.securityBuffer())
                        .wmul(WadRayMath.WAD - priceOracle.getPairPriceDrop(_asset, address(borrowedAsset)))
                        .wmul(WadRayMath.WAD - positionManager.getOracleTolerableLimit(address(borrowedAsset), _asset))
                        .wmul(WadRayMath.WAD - positionManager.getOracleTolerableLimit(_asset, address(borrowedAsset)))
            );
    }

    /**
     * @inheritdoc IBucket
     */
    function getNormalizedVariableDebt() external view override returns (uint256) {
        return _calculateCompoundedInterest(bar, lastUpdatedBlockTimestamp).rmul(variableBorrowIndex);
    }

    /**
     * @inheritdoc IBucket
     */
    function getAllowedAssets() external view override returns (address[] memory) {
        return assets;
    }

    /**
     * @inheritdoc IBucket
     */
    function paybackPermanentLoss(uint256 amount) public override nonReentrant {
        _notBlackListed();
        uint256 amountScaled = amount.rdiv(getNormalizedIncome());
        _require(amountScaled > 0, Errors.AMOUNT_SCALED_SHOULD_BE_GREATER_THAN_ZERO.selector);
        if (amountScaled > permanentLossScaled) {
            amountScaled = permanentLossScaled;
            amount = permanentLoss();
        }
        unchecked {
            permanentLossScaled -= amountScaled;
        }
        pToken.burn(msg.sender, amount, getNormalizedIncome());
    }

    /**
     * @inheritdoc IBucket
     */
    function isWithdrawAfterDelistingAvailable() public view override returns (bool) {
        (, IPrimexDNSStorage.Status status, , uint256 adminDeadline) = dns.buckets(name);
        return status == IPrimexDNSStorage.Status.Deprecated && adminDeadline < block.timestamp;
    }

    /**
     * @inheritdoc IBucket
     */
    function permanentLoss() public view override returns (uint256) {
        return permanentLossScaled.rmul(getNormalizedIncome());
    }

    /**
     * @inheritdoc IBucket
     */
    function getNormalizedIncome() public view override returns (uint256) {
        return _calculateLinearInterest(lar, lastUpdatedBlockTimestamp).rmul(liquidityIndex);
    }

    /**
     * @inheritdoc IBucket
     */
    function availableLiquidity() public view override returns (uint256) {
        return borrowedAsset.balanceOf(address(this)) + aaveDeposit;
    }

    /// @notice Interface checker
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IBucketV2).interfaceId ||
            _interfaceId == type(IBucket).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /**
     * @dev Internal function to deposit funds into the bucket.
     * @param _pTokenReceiver The address to receive the pTokens.
     * @param _amount The amount of funds to deposit.
     * @return _mintedAmount The amount of pTokens minted during deposit
     */
    function _deposit(address _pTokenReceiver, uint256 _amount) internal returns (uint256 _mintedAmount) {
        // launched phase
        // here it's also checked that the bucket is active
        _require(dns.getBucketAddress(name) == address(this), Errors.BUCKET_OUTSIDE_PRIMEX_PROTOCOL.selector);
        _updateIndexes();
        _mintedAmount = pToken.mint(_pTokenReceiver, _amount, liquidityIndex);
        _updateRates();
    }

    /**
     * @notice Internal function for depositing during liquidity mining period.
     * @param _pTokenReceiver The address of the receiver of the pToken.
     * @param _amount The amount of tokens to be deposited.
     */
    function _depositLM(address _pTokenReceiver, uint256 _amount) internal {
        // liquidity mining phase
        _require(block.timestamp <= LMparams.deadlineTimestamp, Errors.DEADLINE_IS_PASSED.selector);

        uint256 _availableLiquidityBeforeTransfer = availableLiquidity() - _amount;

        // we don't need update rates and indexes because
        // they're zero and 1 ray accordingly while no one borrow
        pToken.mint(_pTokenReceiver, _amount, liquidityIndex);

        if (_availableLiquidityBeforeTransfer >= LMparams.accumulatingAmount) {
            _launchBucket();
            return;
        }
        uint256 tokensLeft = LMparams.accumulatingAmount - _availableLiquidityBeforeTransfer;
        uint256 miningAmount;
        if (tokensLeft > _amount) {
            miningAmount = _amount;
            if (isReinvestToAaveEnabled) {
                uint256 bucketBalance = borrowedAsset.balanceOf(address(this));
                aaveDeposit += bucketBalance;
                address aavePool = dns.aavePool();
                TokenApproveLibrary.doApprove(address(borrowedAsset), aavePool, bucketBalance);
                IPool(aavePool).supply(address(borrowedAsset), bucketBalance, address(this), 0);
                emit DepositToAave(aavePool, bucketBalance);
            }
        } else {
            miningAmount = tokensLeft;
            _launchBucket();
        }

        _require(
            LMparams.liquidityMiningRewardDistributor.getLenderAmountInMining(name, _pTokenReceiver) + miningAmount <=
                LMparams.maxAmountPerUser,
            Errors.DEPOSIT_IS_MORE_AMOUNT_PER_USER.selector
        );

        // save lender activity for future reward distribution
        LMparams.liquidityMiningRewardDistributor.addPoints(
            name,
            _pTokenReceiver,
            miningAmount,
            LMparams.maxStabilizationEndTimestamp,
            LMparams.maxDuration,
            block.timestamp
        );
    }

    /**
     * @dev Updates the liquidityIndex and variableBorrowIndex
     */
    function _updateIndexes() internal {
        uint256 newLiquidityIndex = _calculateLinearInterest(lar, lastUpdatedBlockTimestamp).rmul(liquidityIndex);
        _require(newLiquidityIndex <= type(uint128).max, Errors.LIQUIDITY_INDEX_OVERFLOW.selector);
        liquidityIndex = uint128(newLiquidityIndex);

        uint256 newVariableBorrowIndex = _calculateCompoundedInterest(bar, lastUpdatedBlockTimestamp).rmul(
            variableBorrowIndex
        );
        _require(newVariableBorrowIndex <= type(uint128).max, Errors.BORROW_INDEX_OVERFLOW.selector);
        uint256 previousVariableBorrowIndex = variableBorrowIndex;
        variableBorrowIndex = uint128(newVariableBorrowIndex);

        lastUpdatedBlockTimestamp = block.timestamp;
        _mintToReserve(debtToken.scaledTotalSupply(), previousVariableBorrowIndex, variableBorrowIndex);
    }

    /**
     * @dev Mints portion of the interest that goes to the Primex Reserve
     */
    function _mintToReserve(
        uint256 _scaledVariableDebt,
        uint256 _previousVariableBorrowIndex,
        uint256 _newVariableBorrowIndex
    ) internal {
        if (reserveRate == 0) {
            return;
        }
        // debt accrued is the current debt minus the debt at the last update
        // percentage multiplied
        pToken.mintToReserve(
            address(reserve),
            (_scaledVariableDebt.rmul(_newVariableBorrowIndex) - _scaledVariableDebt.rmul(_previousVariableBorrowIndex))
                .wmul(reserveRate),
            liquidityIndex
        );
    }

    /**
     * @notice Internal function to set the isBucketLaunched flag to true.
     * Set the stabilizationPeriodEnd timestamp.
     * If investment is enabled withdraw all liquidity from Aave.
     */

    function _launchBucket() internal {
        LMparams.isBucketLaunched = true;
        LMparams.stabilizationEndTimestamp = block.timestamp + LMparams.stabilizationDuration;
        if (isReinvestToAaveEnabled) {
            _withdrawBucketLiquidityFromAave();
        }
        emit BucketLaunched();
    }

    /**
     * @notice Internal function to withdraw all liquidity from Aave
     */
    function _withdrawBucketLiquidityFromAave() internal {
        address aavePool = dns.aavePool();
        uint256 aaveBalance = IAToken(IPool(aavePool).getReserveData(address(borrowedAsset)).aTokenAddress).balanceOf(
            address(this)
        );
        isReinvestToAaveEnabled = false;
        if (aaveBalance == 0) return;

        IPool(aavePool).withdraw(address(borrowedAsset), type(uint256).max, address(this));
        emit WithdrawFromAave(aavePool, aaveBalance);

        // if there is earned interest, withdraw it to treasury
        if (aaveBalance > aaveDeposit) {
            uint256 interest = aaveBalance - aaveDeposit;
            TokenTransfersLibrary.doTransferOut(address(borrowedAsset), dns.treasury(), interest);
            emit TopUpTreasury(aavePool, interest);
        }
        aaveDeposit = 0;
    }

    /**
     * @dev Updates bucket's BAR and LAR.
     */
    function _updateRates() internal {
        uint256 totalDemand = debtToken.totalSupply();
        uint256 totalDeposit = availableLiquidity() + totalDemand;
        if (totalDeposit == 0) {
            bar = 0;
            lar = 0;
        } else {
            (bar, lar) = interestRateStrategy.calculateInterestRates(totalDemand.rdiv(totalDeposit), reserveRate);
        }
        emit RatesIndexesUpdated(bar, lar, variableBorrowIndex, liquidityIndex, block.timestamp);
    }

    /**
     * @dev Internal function to add a new asset to the allowed assets list.
     * @param _newAsset The address of the new asset to be added.
     */
    function _addAsset(address _newAsset) internal {
        _require(_newAsset != address(0), Errors.CAN_NOT_ADD_WITH_ZERO_ADDRESS.selector);
        _require(!allowedAssets[_newAsset].isSupported, Errors.ASSET_ALREADY_SUPPORTED.selector);
        _require(
            IERC20Metadata(_newAsset).decimals() <= MAX_ASSET_DECIMALS,
            Errors.ASSET_DECIMALS_EXCEEDS_MAX_VALUE.selector
        );
        _require(
            priceOracle.pairPriceDrops(_newAsset, address(borrowedAsset)) > 0,
            Errors.PAIR_PRICE_DROP_IS_NOT_CORRECT.selector
        );
        // Check that both the new asset and the borrowed asset have oracle price feeds available
        priceOracle.getPriceFeedsPair(_newAsset, address(borrowedAsset));
        assets.push(_newAsset);
        allowedAssets[_newAsset] = Asset(assets.length - 1, true);
        emit AddAsset(_newAsset);
    }

    /**
     * @dev Calculates the accumulated interest per blocks delta
     * @param _rate The interest rate (in ray)
     * @param _lastUpdatedBlockTimestamp The block timestamp of the last update of interest rate
     * @return The interest rate accumulated during the secondsDelta (in ray)
     */
    function _calculateLinearInterest(
        uint256 _rate,
        uint256 _lastUpdatedBlockTimestamp
    ) internal view returns (uint256) {
        uint256 secondsDelta = block.timestamp - _lastUpdatedBlockTimestamp;
        return (_rate * secondsDelta) / SECONDS_PER_YEAR + WadRayMath.RAY;
    }

    /**
     * @dev Calculates borrow interest using compounded interest formula
     * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
     * (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
     * @param _bar Borrowing annual rate (originally APR) (in ray)
     * @param _blockTimestamp The block timestamp of the last update of borrow rate
     * @return The borrow interest rate compounded during the secondsDelta (in ray)
     */
    function _calculateCompoundedInterest(uint256 _bar, uint256 _blockTimestamp) internal view returns (uint256) {
        uint256 exp = block.timestamp - _blockTimestamp;

        if (exp == 0) {
            return WadRayMath.RAY;
        }

        uint256 expMinusOne = exp - 1;
        uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;
        // multiply first to mitigate rounding related issues
        uint256 basePowerTwo = _bar.rmul(_bar) / (SECONDS_PER_YEAR * SECONDS_PER_YEAR);
        uint256 basePowerThree = _bar.rmul(_bar).rmul(_bar) / (SECONDS_PER_YEAR * SECONDS_PER_YEAR * SECONDS_PER_YEAR);

        uint256 secondTerm = (exp * expMinusOne * basePowerTwo) / 2;
        uint256 thirdTerm = (exp * expMinusOne * expMinusTwo * basePowerThree) / 6;

        return WadRayMath.RAY + (_bar * exp) / SECONDS_PER_YEAR + secondTerm + thirdTerm;
    }

    /**
     * @dev Function that checks if the caller has a specific role.
     * @param _role The role identifier to check.
     */
    function _onlyRole(bytes32 _role) internal view {
        _require(IAccessControl(registry).hasRole(_role, msg.sender), Errors.FORBIDDEN.selector);
    }

    /**
     * @dev Function that checks if the sender is not blacklisted.
     */
    function _notBlackListed() internal view {
        _require(!whiteBlackList.isBlackListed(msg.sender), Errors.SENDER_IS_BLACKLISTED.selector);
    }
}
/* solhint-enable max-states-count */
