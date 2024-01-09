// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./PriceCalculator.sol";
import "./IAave.sol";
import "./IHedge.sol";
import "./IOptionVault.sol";
import "./IWETH.sol";
import "./IFeePool.sol";
import "./PredyMath.sol";

/**
 * @title OptionLib
 */
library OptionLib {
    using PredyMath for uint128;

    struct TokenContracts {
        // collateral token
        address collateral;
        // underlying token
        address underlying;
    }

    /// @dev option information
    struct OptionInfo {
        address aggregator;
        TokenContracts tokens;
        // counter of serieses
        uint128 seriesCount;
        uint128 expiryCount;
        uint128 expiredCount;
        // expiration => seriesId => option series
        mapping(uint256 => IOptionVault.Expiration) expiries;
        //
        mapping(uint256 => IOptionVault.OptionSeries) serieses;
        // counter of vaults
        uint256 vaultCount;
        // accountId => IOptionVault.Account
        uint128 totalDepositedToLendingPool;
        mapping(uint256 => IOptionVault.Account) accounts;
        // config
        mapping(uint8 => uint128) configs;
        //
        LendingPool lendingPool;
    }

    uint8 public constant MM_RATIO = 1;
    uint8 public constant IM_RATIO = 2;
    uint8 public constant CALL_SAFE_RATIO = 3;
    uint8 public constant PUT_SAFE_RATIO = 4;
    uint8 public constant SLIPPAGE_TOLERANCE = 5;
    uint8 public constant BASE_LIQ_REWARD = 8;
    uint8 public constant REWARD_PER_SIZE_RATIO = 9;

    /// @dev minimum vault id.
    /// trader's vault id is larger than MIN_VAULT_ID
    uint128 public constant MIN_VAULT_ID = 100;

    uint256 constant MAX_UINT256 = 2**256 - 1;

    modifier existsExpiry(uint256 _expiryId, uint128 _expiryCount) {
        require(_expiryId > 0 && _expiryId < _expiryCount, "OptionLib: expiry not found");
        _;
    }

    modifier existsSeries(uint256 _seriesId, uint128 _seriesCount) {
        require(_seriesId > 0 && _seriesId < _seriesCount, "OptionLib: series not found");
        _;
    }

    /**
     * @notice initialize OptionInfo
     */
    function init(
        OptionInfo storage _optionInfo,
        address _collateral,
        address _underlying,
        address _lendingPool
    ) external {
        // initialize states
        _optionInfo.expiredCount = 0;
        _optionInfo.expiryCount = 1;
        _optionInfo.seriesCount = 1;
        _optionInfo.vaultCount = OptionLib.MIN_VAULT_ID;

        // initialize configs
        // 10%
        _optionInfo.configs[MM_RATIO] = 100;
        // 20%
        _optionInfo.configs[IM_RATIO] = 200;
        // 120%
        _optionInfo.configs[CALL_SAFE_RATIO] = 1200;
        // 120%
        _optionInfo.configs[PUT_SAFE_RATIO] = 1200;
        // 0.5%
        _optionInfo.configs[SLIPPAGE_TOLERANCE] = 50;
        // $100
        _optionInfo.configs[BASE_LIQ_REWARD] = 100 * 1e6;
        // 9%
        _optionInfo.configs[REWARD_PER_SIZE_RATIO] = 90;

        // set contract addresses
        _optionInfo.tokens.collateral = _collateral;
        _optionInfo.tokens.underlying = _underlying;
        _optionInfo.lendingPool = LendingPool(_lendingPool);
    }

    function setIV(
        OptionInfo storage _optionInfo,
        uint256 _seriesId,
        uint128 _iv
    ) external {
        _optionInfo.serieses[_seriesId].iv = uint64(_iv);
    }

    /**
     * @notice create new option series
     * the option series must have later expiry than existence serieses
     */
    function createExpiry(OptionInfo storage _optionInfo, uint64 _expiry) external returns (uint128 expiryId) {
        // check expiry is greater than or equal to last created
        uint64 lastExpiry;
        if (_optionInfo.expiryCount > 0) {
            lastExpiry = _optionInfo.expiries[_optionInfo.expiryCount - 1].expiry;
        }

        require(_expiry >= block.timestamp, "OptionLib: expiry must be greater than now");
        require(_expiry >= lastExpiry, "OptionLib: expiry must be greater than or equal to last created");
        require(_expiry % 1 hours == 0, "OptionLib: expiry must be formatted");

        // create series
        expiryId = _optionInfo.expiryCount;
        _optionInfo.expiries[expiryId].expiryId = expiryId;
        _optionInfo.expiries[expiryId].expiry = _expiry;

        _optionInfo.expiryCount += 1;
    }

    function createSeries(
        OptionInfo storage _optionInfo,
        uint128 _expiryId,
        uint64 _strike,
        bool _isPut,
        uint64 _iv
    ) external returns (uint256 seriesId) {
        require(_strike > 0 && _strike < 1e16, "OptionLib: strike must be greater than 0 and less than $100M");
        require(_iv > 0 && _iv < 1000 * 1e6, "OptionLib: iv must be greater than 0 and less than 1000%");

        seriesId = _optionInfo.seriesCount;

        // create series
        _optionInfo.serieses[seriesId] = IOptionVault.OptionSeries(_strike, _isPut, _iv, _expiryId);
        _optionInfo.expiries[_expiryId].seriesIds.push(seriesId);

        _optionInfo.seriesCount += 1;
    }

    function createAccount(OptionInfo storage _optionInfo, address owner) external returns (uint256) {
        uint256 id = _optionInfo.vaultCount;

        IOptionVault.Account storage account = _optionInfo.accounts[id];
        account.owner = owner;
        account.settledCount = _optionInfo.expiredCount;

        _optionInfo.vaultCount += 1;

        return id;
    }

    function deposit(
        OptionInfo storage _optionInfo,
        uint256 _accountId,
        uint256 _expiryId,
        uint128 _amount
    ) external existsExpiry(_expiryId, _optionInfo.expiryCount) {
        IOptionVault.Vault storage vault = _optionInfo.accounts[_accountId].vaults[_expiryId];

        require(!vault.isSettled, "Vault already settled");

        increaseCollateral(vault, _amount);
    }

    function withdraw(
        OptionInfo storage _optionInfo,
        uint256 _accountId,
        uint256 _expiryId,
        uint128 _amount,
        uint128 _spot
    ) external existsExpiry(_expiryId, _optionInfo.expiryCount) {
        IOptionVault.Vault storage vault = _optionInfo.accounts[_accountId].vaults[_expiryId];

        checkOptionSeriesIsLive(_optionInfo.expiries[_expiryId]);

        decreaseCollateral(vault, _amount);

        checkCollateral(_optionInfo, _accountId, _expiryId, _spot);
    }

    function withdrawUnrequiredCollateral(
        OptionInfo storage _optionInfo,
        uint256 _accountId,
        uint256 _expiryId,
        uint128 _spot,
        uint128 _cRatio,
        bool _isPool
    ) external existsExpiry(_expiryId, _optionInfo.expiryCount) returns (uint128) {
        IOptionVault.Vault storage vault = _optionInfo.accounts[_accountId].vaults[_expiryId];

        checkOptionSeriesIsLive(_optionInfo.expiries[_expiryId]);

        uint128 collateralValue = getCollateralValue(_optionInfo, _accountId, _expiryId, _spot);

        uint128 requiredCollateral = (1e6 *
            getRequiredMargin(
                _optionInfo,
                _accountId,
                _expiryId,
                _spot,
                _isPool ? IOptionVault.MarginLevel.Safe : IOptionVault.MarginLevel.Initial
            )) / _cRatio;

        if (collateralValue > requiredCollateral) {
            return decreaseCollateral(vault, collateralValue - requiredCollateral);
        } else {
            return 0;
        }
    }

    function write(
        OptionInfo storage _optionInfo,
        uint256 _accountId,
        uint256 _seriesId,
        uint128 _amount,
        uint128 _spot
    ) external existsSeries(_seriesId, _optionInfo.seriesCount) {
        IOptionVault.Account storage account = _optionInfo.accounts[_accountId];
        IOptionVault.OptionSeries storage series = _optionInfo.serieses[_seriesId];

        checkOptionSeriesIsLive(_optionInfo.expiries[series.expiryId]);

        account.vaults[series.expiryId].shorts[_seriesId] += _amount;

        checkCollateral(_optionInfo, _accountId, series.expiryId, _spot);
    }

    function unlock(
        OptionInfo storage _optionInfo,
        uint256 _accountId,
        uint256 _seriesId,
        uint128 _amount
    ) external existsSeries(_seriesId, _optionInfo.seriesCount) {
        IOptionVault.OptionSeries storage series = _optionInfo.serieses[_seriesId];

        _optionInfo.accounts[_accountId].vaults[series.expiryId].shorts[_seriesId] -= _amount;
    }

    function depositAndWrite(
        OptionInfo storage _optionInfo,
        uint256 _accountId,
        uint256 _seriesId,
        uint128 _amount,
        uint128 _cRatio,
        uint128 _spot,
        bool _isPool
    ) external existsSeries(_seriesId, _optionInfo.seriesCount) returns (uint256 expiryId, uint128 collateral) {
        expiryId = _optionInfo.serieses[_seriesId].expiryId;

        IOptionVault.Account storage account = _optionInfo.accounts[_accountId];
        IOptionVault.Vault storage vault = account.vaults[expiryId];

        checkOptionSeriesIsLive(_optionInfo.expiries[expiryId]);

        account.vaults[expiryId].shorts[_seriesId] += _amount;

        collateral = getCollateralForASeries(_optionInfo, expiryId, _seriesId, _spot, _amount, _cRatio, _isPool);

        increaseCollateral(vault, collateral);
    }

    function addLong(
        OptionInfo storage _optionInfo,
        uint256 _accountId,
        uint256 _expiryId,
        uint256 _seriesId,
        uint128 _amount
    ) external existsSeries(_seriesId, _optionInfo.seriesCount) returns (uint128) {
        IOptionVault.Account storage account = _optionInfo.accounts[_accountId];

        account.vaults[_expiryId].longs[_seriesId] += _amount;

        return account.vaults[_expiryId].longs[_seriesId];
    }

    function removeLong(
        OptionInfo storage _optionInfo,
        uint256 _accountId,
        uint256 _expiryId,
        uint256 _seriesId,
        uint128 _amount
    ) external existsSeries(_seriesId, _optionInfo.seriesCount) {
        IOptionVault.Account storage account = _optionInfo.accounts[_accountId];

        account.vaults[_expiryId].longs[_seriesId] -= _amount;
    }

    /**
     * @notice liquidate a vault
     * the amount that liquidator can burn is '(BASE_REWRD + MM - C) / (mm - premium - REWARD_RATIO * (St or K))'
     * where C = vault.collateral
     * , MM current maintenance margin
     * and mm is maintenance margin per size
     */
    function liquidate(
        OptionInfo storage _optionInfo,
        uint256 _accountId,
        uint256 _seriesId,
        uint128 _amount,
        uint128 _spot
    ) external existsSeries(_seriesId, _optionInfo.seriesCount) returns (uint128) {
        IOptionVault.OptionSeries memory option = _optionInfo.serieses[_seriesId];
        IOptionVault.Vault storage vault = _optionInfo.accounts[_accountId].vaults[option.expiryId];

        uint128 shortAmount = vault.shorts[_seriesId];

        require(shortAmount >= _amount, "OptionLib: amount exceeds vault size");

        uint128 collateralValue = getCollateralValue(_optionInfo, _accountId, option.expiryId, _spot);

        uint128 limit;
        {
            uint128 maintenanceMargin = getRequiredMargin(
                _optionInfo,
                _accountId,
                option.expiryId,
                _spot,
                IOptionVault.MarginLevel.Maintenance
            );
            require(collateralValue < maintenanceMargin, "OptionLib: collateral must be less than MM");

            limit = calLiquidatableAmount(
                _optionInfo,
                maintenanceMargin,
                collateralValue,
                option.isPut ? option.strike : _spot
            );
        }

        require(limit >= _amount, "OptionLib: amount exceeds liquidatable limit");

        vault.shorts[_seriesId] -= _amount;

        uint128 reward;
        {
            uint128 maintenanceMargin = getRequiredMargin(
                _optionInfo,
                _accountId,
                option.expiryId,
                _spot,
                IOptionVault.MarginLevel.Maintenance
            );

            require(collateralValue >= maintenanceMargin, "OptionLib: margin must be safe");
            reward = collateralValue - maintenanceMargin;
        }

        return decreaseCollateral(vault, reward);
    }

    /**
     * @notice calculate profit of some amount of option contracts
     */
    function claimProfit(
        OptionInfo storage _optionInfo,
        uint256 _seriesId,
        uint128 _amount,
        uint128 _price
    ) external view existsSeries(_seriesId, _optionInfo.seriesCount) returns (uint128) {
        uint128 payout = calculatePayout(
            _amount,
            _price,
            _optionInfo.serieses[_seriesId].strike,
            _optionInfo.serieses[_seriesId].isPut,
            false
        );

        return payout;
    }

    /**
     * @notice fix payout of a vault and remove the payout from vault's collaterals
     * @return settledAmount the amount that the vault owner can redeem
     */
    function settle(
        OptionInfo storage _optionInfo,
        uint256 _accountId,
        uint256 _expiryId,
        uint128 _price
    ) external existsExpiry(_expiryId, _optionInfo.expiryCount) returns (uint128 settledAmount) {
        IOptionVault.Account storage account = _optionInfo.accounts[_accountId];
        IOptionVault.Vault storage vault = account.vaults[_expiryId];

        uint128 payout = getTotalPayout(_optionInfo, _accountId, _expiryId, _price, true);

        require(!vault.isSettled, "OptionLib: vault already settled");

        require(vault.hedgePosition == 0, "OptionLib: hedge position must be neutral");

        // all collaterals in Aave must be redeemed before settlement
        require(vault.shortLiquidity == 0, "OptionLib: all collaterals must be withdrawn");

        require(account.settledCount < _expiryId, "OptionLib: vault already settled");

        for (uint256 i = account.settledCount + 1; i < _expiryId; i++) {
            uint128 skippedCollateral = account.vaults[i].collateral;
            require(skippedCollateral == 0, "OptionLib: can not skip expiry");
        }

        vault.isSettled = true;
        account.settledCount = _expiryId;

        updateExpiredCount(_optionInfo, _expiryId);

        decreaseCollateral(vault, payout);

        settledAmount = vault.collateral;
    }

    /*
     * addUnderlyingLong and addUnderlyingShort are functions to achieve delta neutral.
     * vault's net delta is calculated as vaultDelta, and the protocol wanna make (vaultDelta + vault.hedgePosition) zero.
     * hedgePosition exactly represents how many underlying asset the vault has,
     * and negative hedgePosition means short position of underlying asset.
     */

    /**
     * @notice receive underlying asset and send collateral asset to sender
     * @param _vaultDelta net delta of the vault
     * @param _underlyingAmountE8 amount of underlying asset scaled by 1e8
     */
    function addUnderlyingLong(
        OptionInfo storage _optionInfo,
        uint256 _accountId,
        uint256 _expiryId,
        uint128 _spot,
        int256 _vaultDelta,
        uint256 _underlyingAmountE8,
        uint256 _collateralAmount
    ) external existsExpiry(_expiryId, _optionInfo.expiryCount) returns (int256) {
        IOptionVault.Vault storage vault = _optionInfo.accounts[_accountId].vaults[_expiryId];
        ERC20 underlying = ERC20(_optionInfo.tokens.underlying);

        uint256 decimals = underlying.decimals();

        require(_vaultDelta + vault.hedgePosition < 0, "OptionLib: net delta must be negative");

        require(
            -(_vaultDelta + vault.hedgePosition) >= int256(_underlyingAmountE8),
            "OptionLib: underlying amount is too large"
        );

        if (-(_vaultDelta + vault.hedgePosition) < int256(_underlyingAmountE8)) {
            _underlyingAmountE8 = uint256(-(_vaultDelta + vault.hedgePosition));
        }

        require(
            (PredyMath.scale(_spot * _underlyingAmountE8, 16, 6) * (10000 + _optionInfo.configs[SLIPPAGE_TOLERANCE])) /
                10000 >=
                _collateralAmount,
            "OptionLib: collateral amount is too large"
        );

        uint256 uAmount = PredyMath.scale(_underlyingAmountE8, 8, decimals);

        int256 hedgePosition = vault.hedgePosition;

        vault.hedgePosition += int256(_underlyingAmountE8);

        underlying.transferFrom(msg.sender, address(this), uAmount);

        if (hedgePosition < -int256(_underlyingAmountE8)) {
            repayUnderlyingInternal(_optionInfo, vault, _spot, uAmount, uint256(-hedgePosition) - _underlyingAmountE8);
        } else if (hedgePosition < 0) {
            repayUnderlyingInternal(
                _optionInfo,
                vault,
                _spot,
                PredyMath.scale(uint256(-hedgePosition), 8, decimals),
                0
            );
        }

        require(vault.collateral >= uint128(_collateralAmount), "OptionLib: no enough collateral");

        decreaseCollateral(vault, uint128(_collateralAmount));

        IERC20(_optionInfo.tokens.collateral).transfer(msg.sender, _collateralAmount);

        return vault.hedgePosition;
    }

    /**
     * @notice receive collateral asset and send underlying asset to sender
     * @param _vaultDelta net delta of the vault
     * @param _underlyingAmountE8 amount of underlying asset scaled by 1e8
     */
    function addUnderlyingShort(
        OptionInfo storage _optionInfo,
        uint256 _accountId,
        uint256 _expiryId,
        uint128 _spot,
        int256 _vaultDelta,
        uint256 _underlyingAmountE8,
        uint256 _collateralAmount
    ) external existsExpiry(_expiryId, _optionInfo.expiryCount) returns (int256) {
        IOptionVault.Account storage account = _optionInfo.accounts[_accountId];
        IOptionVault.Vault storage vault = account.vaults[_expiryId];
        ERC20 underlying = ERC20(_optionInfo.tokens.underlying);

        uint256 decimals = underlying.decimals();

        require(_vaultDelta + vault.hedgePosition > 0, "OptionLib: net delta must be positive");

        require(
            (_vaultDelta + vault.hedgePosition) >= int256(_underlyingAmountE8),
            "OptionLib: underlying amount is too large"
        );

        require(
            (PredyMath.scale(_spot * _underlyingAmountE8, 16, 6) * (10000 - _optionInfo.configs[SLIPPAGE_TOLERANCE])) /
                10000 <=
                _collateralAmount,
            "OptionLib: collateral amount is too small"
        );

        uint256 uAmount = PredyMath.scale(_underlyingAmountE8, 8, decimals);

        increaseCollateral(vault, uint128(_collateralAmount));

        IERC20(_optionInfo.tokens.collateral).transferFrom(msg.sender, address(this), _collateralAmount);

        if (vault.hedgePosition <= 0) {
            borrowUnderlyingInternal(_optionInfo, vault, _spot, uAmount);
        } else if (vault.hedgePosition < int256(_underlyingAmountE8)) {
            borrowUnderlyingInternal(
                _optionInfo,
                vault,
                _spot,
                uAmount - PredyMath.scale(uint256(vault.hedgePosition), 8, decimals)
            );
        }

        vault.hedgePosition -= int256(_underlyingAmountE8);

        underlying.transfer(msg.sender, uAmount);

        return vault.hedgePosition;
    }

    /**
     * @notice redeem collateral from LendingPool
     */
    function redeemCollateralFromLendingPool(
        OptionInfo storage _optionInfo,
        uint128 _repayAmount,
        uint128 _price,
        address _caller,
        address _feePool
    ) external {
        // there are no live option serieses
        require(_optionInfo.expiryCount == _optionInfo.expiredCount + 1);
        // check total short liquidity is 0
        require(_optionInfo.totalDepositedToLendingPool == 0);

        IERC20(_optionInfo.tokens.underlying).transferFrom(_caller, address(this), _repayAmount);

        IERC20(_optionInfo.tokens.underlying).approve(address(_optionInfo.lendingPool), _repayAmount);
        uint128 repaidAmount = repayBorrow(_optionInfo, MAX_UINT256);

        // redeem underlying tokens
        uint128 withdrawnAmount = uint128(
            _optionInfo.lendingPool.withdraw(_optionInfo.tokens.collateral, MAX_UINT256, address(this))
        );

        uint128 reward = (_price * repaidAmount) / 1e20;
        reward = (reward * (10000 + _optionInfo.configs[SLIPPAGE_TOLERANCE])) / 10000;

        if (reward < withdrawnAmount) {
            uint128 rewardForFeePool = withdrawnAmount - reward;

            // send USDC to fee pool
            IFeePool feePool = IFeePool(_feePool);

            IERC20(_optionInfo.tokens.collateral).approve(address(feePool), rewardForFeePool);
            feePool.sendProfitERC20(address(this), rewardForFeePool);
        } else {
            reward = withdrawnAmount;
        }

        // send USDC and WETH to caller
        IERC20(_optionInfo.tokens.collateral).transfer(_caller, reward);
        IERC20(_optionInfo.tokens.underlying).transfer(_caller, _repayAmount - repaidAmount);
    }

    function setConfig(
        OptionInfo storage _optionInfo,
        uint8 _key,
        uint128 _value
    ) external {
        _optionInfo.configs[_key] = _value;
    }

    //////////////////////
    // Getter Functions //
    //////////////////////

    function getLiveOptionSerieses(OptionInfo storage _optionInfo)
        external
        view
        returns (IOptionVault.Expiration[] memory)
    {
        IOptionVault.Expiration[] memory expirations = new IOptionVault.Expiration[](
            _optionInfo.expiryCount - _optionInfo.expiredCount - 1
        );

        for (uint128 i = _optionInfo.expiredCount + 1; i < _optionInfo.expiryCount; i++) {
            expirations[i - _optionInfo.expiredCount - 1] = IOptionVault.Expiration(
                i,
                _optionInfo.expiries[i].expiry,
                _optionInfo.expiries[i].seriesIds
            );
        }

        return expirations;
    }

    function getOptionSeriesView(OptionInfo storage _optionInfo, uint256 _seriesId)
        external
        view
        returns (IOptionVault.OptionSeriesView memory)
    {
        IOptionVault.OptionSeries memory optionSeries = _optionInfo.serieses[_seriesId];
        IOptionVault.Expiration memory expiration = _optionInfo.expiries[optionSeries.expiryId];

        return
            IOptionVault.OptionSeriesView(
                optionSeries.expiryId,
                _seriesId,
                expiration.expiry,
                OptionLib.getMaturity(expiration.expiry),
                optionSeries.strike,
                optionSeries.isPut,
                optionSeries.iv
            );
    }

    function getCollateralValueQuote(
        OptionInfo storage _optionInfo,
        uint256 _accountId,
        uint128 price
    ) external view returns (uint128 total) {
        for (uint256 i = _optionInfo.accounts[_accountId].settledCount + 1; i < _optionInfo.seriesCount; i++) {
            total += getCollateralValue(_optionInfo, _accountId, i, price);
        }
    }

    /**
     * @notice get position size
     * @param _accountId vault id
     * @param _seriesId option series id
     * @return (short size, long size)
     */
    function getPositionSize(
        OptionInfo storage _optionInfo,
        uint256 _accountId,
        uint256 _seriesId
    ) external view returns (uint128, uint128) {
        IOptionVault.OptionSeries memory series = _optionInfo.serieses[_seriesId];
        IOptionVault.Vault storage vault = _optionInfo.accounts[_accountId].vaults[series.expiryId];

        return (vault.shorts[_seriesId], vault.longs[_seriesId]);
    }

    function getVaultOwner(OptionInfo storage _optionInfo, uint256 _accountId) external view returns (address) {
        return _optionInfo.accounts[_accountId].owner;
    }

    /**
     * @notice get the amount that can be liquidated
     */
    function getLiquidatableAmount(
        OptionInfo storage _optionInfo,
        uint256 _accountId,
        uint256 _seriesId,
        uint128 _spot
    ) external view returns (uint128) {
        IOptionVault.OptionSeries memory option = _optionInfo.serieses[_seriesId];
        IOptionVault.Account storage account = _optionInfo.accounts[_accountId];
        IOptionVault.Vault storage vault = account.vaults[option.expiryId];

        uint128 maintenanceMargin = getRequiredMargin(
            _optionInfo,
            _accountId,
            option.expiryId,
            _spot,
            IOptionVault.MarginLevel.Maintenance
        );

        uint128 collateralValue = getCollateralValue(_optionInfo, _accountId, option.expiryId, _spot);

        if (collateralValue >= maintenanceMargin) {
            return 0;
        }

        uint128 liquidatableAmount = calLiquidatableAmount(
            _optionInfo,
            maintenanceMargin,
            collateralValue,
            option.isPut ? option.strike : _spot
        );

        if (vault.shorts[_seriesId] < liquidatableAmount) {
            return vault.shorts[_seriesId];
        }

        return liquidatableAmount;
    }

    int256 internal constant SQRT_YEAR_E8 = 5615.69229926 * 10**8;

    /**
     * @notice calculate vault's net delta
     * @param _optionInfo pool info
     * @param _accountId vault id to calculate net delta
     * @param _spot spot price
     * @return tickDelta vault's net delta scaled by 1e8
     */
    function calculateVaultDelta(
        OptionInfo storage _optionInfo,
        uint256 _accountId,
        uint256 _expiryId,
        uint128 _spot
    ) external view returns (int256 tickDelta) {
        IOptionVault.Vault storage vault = _optionInfo.accounts[_accountId].vaults[_expiryId];

        // calculate serieses that is not expired
        IOptionVault.Expiration memory expiration = _optionInfo.expiries[_expiryId];

        // option serieses before maturity are included in the calculation.
        if (expiration.expiry <= block.timestamp) {
            return 0;
        }

        // uint64 maturity = getMaturity(expiration.expiry);
        int256 sqrtMaturity = PriceCalculator.getSqrtMaturity(getMaturity(expiration.expiry));

        for (uint256 j = 0; j < expiration.seriesIds.length; j++) {
            uint256 seriesId = expiration.seriesIds[j];

            int128 position = vault.longs[seriesId].toInt128() - vault.shorts[seriesId].toInt128();
            tickDelta += calculateDelta(sqrtMaturity, _optionInfo.serieses[seriesId], position, _spot);
        }
        return tickDelta;
    }

    ///////////////////////
    // Private Functions //
    ///////////////////////

    function increaseCollateral(IOptionVault.Vault storage _vault, uint128 _amount) internal {
        _vault.collateral += _amount;
    }

    function decreaseCollateral(IOptionVault.Vault storage _vault, uint128 _amount) internal returns (uint128) {
        if (_vault.collateral >= _amount) {
            _vault.collateral -= _amount;
            return _amount;
        } else {
            uint128 a = _vault.collateral;
            _vault.collateral = 0;
            return a;
        }
    }

    /**
     * @notice get USD value of collateral
     */
    function getCollateralValue(
        OptionInfo storage _optionInfo,
        uint256 _accountId,
        uint256 _expiryId,
        uint128 _spot
    ) internal view returns (uint128) {
        IOptionVault.Account storage account = _optionInfo.accounts[_accountId];
        IOptionVault.Vault storage vault = account.vaults[_expiryId];

        int256 hedgedValue = vault.shortLiquidity.toInt128() + (_spot.toInt128() * vault.hedgePosition) / 1e10;

        return uint128(uint256(hedgedValue)) + vault.collateral;
    }

    /**
     * @notice get the required margin of a vault
     */
    function getRequiredMargin(
        OptionInfo storage _optionInfo,
        uint256 _accountId,
        uint256 _expiryId,
        uint128 _spot,
        IOptionVault.MarginLevel _marginLevel
    ) public view returns (uint128 requiredMargin) {
        IOptionVault.Account storage account = _optionInfo.accounts[_accountId];
        IOptionVault.Vault storage vault = account.vaults[_expiryId];
        IOptionVault.Expiration storage expiration = _optionInfo.expiries[_expiryId];

        if (vault.isSettled) {
            return 0;
        }

        for (uint256 i = 0; i < expiration.seriesIds.length; i++) {
            uint256 seriesId = expiration.seriesIds[i];
            uint128 shortAmount = vault.shorts[seriesId];
            uint128 longAmount = vault.longs[seriesId];

            if (shortAmount == 0 && longAmount == 0) {
                continue;
            }

            IOptionVault.OptionSeriesParams memory seriesParams = getOptionSeriesParams(
                _optionInfo.serieses[seriesId],
                expiration.expiry
            );

            if (_marginLevel == IOptionVault.MarginLevel.Safe) {
                requiredMargin += calMargin(
                    _optionInfo,
                    shortAmount.toInt128() - longAmount.toInt128(),
                    _spot,
                    seriesParams,
                    _marginLevel
                );
            } else {
                requiredMargin += calMargin(_optionInfo, shortAmount.toInt128(), _spot, seriesParams, _marginLevel);
            }
        }
    }

    function getRequiredMarginForASeries(
        OptionInfo storage _optionInfo,
        uint256 _expiryId,
        uint256 _seriesId,
        uint128 _spot,
        int128 _amount,
        IOptionVault.MarginLevel _marginLevel
    ) public view returns (uint128) {
        uint64 expiry = _optionInfo.expiries[_expiryId].expiry;

        IOptionVault.OptionSeries memory series = _optionInfo.serieses[_seriesId];

        return calMargin(_optionInfo, _amount, _spot, getOptionSeriesParams(series, expiry), _marginLevel);
    }

    /**
     * @notice get the total payout of a vault
     */
    function getTotalPayout(
        OptionInfo storage _optionInfo,
        uint256 _accountId,
        uint256 _expiryId,
        uint128 _spot,
        bool _roundUp
    ) public view returns (uint128 totalPayout) {
        IOptionVault.Account storage account = _optionInfo.accounts[_accountId];
        IOptionVault.Vault storage vault = account.vaults[_expiryId];

        IOptionVault.Expiration memory expiration = _optionInfo.expiries[_expiryId];

        for (uint256 i = 0; i < expiration.seriesIds.length; i++) {
            uint256 seriesId = expiration.seriesIds[i];

            if (vault.shorts[seriesId] == 0) {
                continue;
            }

            totalPayout += calculatePayout(
                vault.shorts[seriesId],
                _spot,
                _optionInfo.serieses[seriesId].strike,
                _optionInfo.serieses[seriesId].isPut,
                _roundUp
            );
        }
    }

    /**
     * @notice calculate liquidatable amount
     * Calculate the liquidatable size so that the collateral of the size's premium + BASE_REWARD remains in vault
     */
    function calLiquidatableAmount(
        OptionInfo storage _optionInfo,
        uint128 _maintenanceMargin,
        uint128 _collateralValue,
        uint128 _spotOrStrike
    ) internal view returns (uint128 limit) {
        // maintenance margin - premium
        uint128 rewardDiffPerSize = (_spotOrStrike * _optionInfo.configs[REWARD_PER_SIZE_RATIO]) / (1000);

        return
            (1e10 * (_optionInfo.configs[BASE_LIQ_REWARD] + _maintenanceMargin - _collateralValue)) / rewardDiffPerSize;
    }

    /**
     * @notice get maturity
     */
    function getMaturity(uint64 _expiry) internal view returns (uint64 maturity) {
        maturity = _expiry > block.timestamp ? _expiry - uint64(block.timestamp) : 0;
    }

    function getOptionSeriesParams(IOptionVault.OptionSeries memory _series, uint64 _expiry)
        internal
        view
        returns (IOptionVault.OptionSeriesParams memory)
    {
        uint64 maturity = getMaturity(_expiry);

        return IOptionVault.OptionSeriesParams(_series.expiryId, maturity, _series.strike, _series.isPut, _series.iv);
    }

    function checkOptionSeriesIsLive(IOptionVault.Expiration memory _expiration) internal view {
        require(_expiration.expiry > block.timestamp, "OptionLib: option series has been expired");
    }

    function checkCollateral(
        OptionInfo storage _optionInfo,
        uint256 _accountId,
        uint256 _expiryId,
        uint128 _spot
    ) internal view {
        require(
            getCollateralValue(_optionInfo, _accountId, _expiryId, _spot) >=
                getRequiredMargin(_optionInfo, _accountId, _expiryId, _spot, IOptionVault.MarginLevel.Initial),
            "OptionLib: collateral is not enough"
        );
    }

    function getCollateralForASeries(
        OptionInfo storage _optionInfo,
        uint256 _expiryId,
        uint256 _seriesId,
        uint128 _spot,
        uint128 _amount,
        uint128 _cRatio,
        bool _isPool
    ) internal view returns (uint128 collateral) {
        uint128 requiredMargin = getRequiredMarginForASeries(
            _optionInfo,
            _expiryId,
            _seriesId,
            _spot,
            _amount.toInt128(),
            _isPool ? IOptionVault.MarginLevel.Safe : IOptionVault.MarginLevel.Initial
        );

        collateral = (1e6 * requiredMargin) / _cRatio;
    }

    /**
     * @notice calculate required margin
     * there are 3 margin levels, Maintenance Margin, Initial Margin and Safe Margin.
     * Maintenance Margin: premium + mmRatio * spot
     * Initial Margin: premium + imRatio * spot
     * Safe Margin:
     *   120% of spot for short call
     *   200% of min(strike, spot) for short put
     *   200% of min(strike, spot) for long call
     *   120% of spot for long put
     */
    function calMargin(
        OptionInfo storage _optionInfo,
        int128 _u,
        uint128 _spot,
        IOptionVault.OptionSeriesParams memory _series,
        IOptionVault.MarginLevel _marginLevel
    ) internal view returns (uint128) {
        if (_marginLevel == IOptionVault.MarginLevel.Maintenance || _marginLevel == IOptionVault.MarginLevel.Initial) {
            uint128 size = uint128(_u);
            // calculate as ATM if option is OTM

            uint256 p = PriceCalculator.calculatePrice(
                _spot,
                _series.strike,
                _series.maturity,
                _series.iv,
                _series.isPut
            );

            if (_marginLevel == IOptionVault.MarginLevel.Initial) {
                // initial margin
                if (_series.isPut) {
                    p += (_series.strike * _optionInfo.configs[IM_RATIO]) / (1000);
                } else {
                    p += (_spot * _optionInfo.configs[IM_RATIO]) / (1000);
                }
            } else {
                // maintenance margin
                if (_series.isPut) {
                    p += (_series.strike * _optionInfo.configs[MM_RATIO]) / (1000);
                } else {
                    p += (_spot * _optionInfo.configs[MM_RATIO]) / (1000);
                }
            }

            return uint128(size * p) / 1e10;
        } else if (_marginLevel == IOptionVault.MarginLevel.Safe) {
            bool collateralForShort;
            uint128 size;

            if (_u > 0) {
                size = uint128(_u);
                collateralForShort = _series.isPut;
            } else {
                size = uint128(-_u);
                collateralForShort = !_series.isPut;
            }

            if (collateralForShort) {
                return
                    (size * PredyMath.min(_series.strike, _spot) * _optionInfo.configs[PUT_SAFE_RATIO]) / (1e10 * 1000);
            } else {
                return (size * _spot * _optionInfo.configs[CALL_SAFE_RATIO]) / (1e10 * 1000);
            }
        }

        return 0;
    }

    /**
     * @notice calculate payout
     * put: amount * max(K - S, 0)
     * call: amount * max(S - K, 0)
     */
    function calculatePayout(
        uint128 _u,
        uint128 _spot,
        uint128 _strike,
        bool _isPut,
        bool _isRoundUp
    ) internal pure returns (uint128) {
        uint128 r;
        if (_isPut && _strike > _spot) {
            r = _strike - _spot;
        } else if (!_isPut && _strike < _spot) {
            r = _spot - _strike;
        } else {
            return 0;
        }
        return PredyMath.mulDiv(_u, r, 1e10, _isRoundUp);
    }

    function updateExpiredCount(OptionInfo storage _optionInfo, uint256 _expiryId) internal {
        IOptionVault.Expiration storage expiration = _optionInfo.expiries[_expiryId];

        require(expiration.expiry < block.timestamp, "expiry must have been passed");

        if (_optionInfo.expiredCount < _expiryId) {
            _optionInfo.expiredCount = uint128(_expiryId);
        }
    }

    function calculateDelta(
        int256 _maturity,
        IOptionVault.OptionSeries memory _option,
        int256 _position,
        uint128 _spot
    ) internal pure returns (int256 delta) {
        return
            (_position * PriceCalculator.calculateDelta(_spot, _option.strike, _maturity, _option.iv, _option.isPut)) /
            int256(1e8);
    }

    /**
     * @notice deposits USDC and borrows underlying asset from compound
     */
    function borrowUnderlyingInternal(
        OptionInfo storage _optionInfo,
        IOptionVault.Vault storage vault,
        uint128 _spot,
        uint256 _underlyingAmount
    ) internal {
        ERC20 underlying = ERC20(_optionInfo.tokens.underlying);

        uint256 decimals = underlying.decimals();

        uint128 depositCollateral = uint128(PredyMath.scale(_underlyingAmount * _spot * 2.0, decimals + 8, 6));

        // deposit USDC to compound
        IERC20(_optionInfo.tokens.collateral).approve(address(_optionInfo.lendingPool), depositCollateral);
        _optionInfo.lendingPool.deposit(_optionInfo.tokens.collateral, depositCollateral, address(this), 0);

        // borrow underling
        borrow(_optionInfo, _underlyingAmount);

        require(vault.collateral >= depositCollateral, "OptionLib: no enough collateral");

        depositCollateral = decreaseCollateral(vault, depositCollateral);
        vault.shortLiquidity += depositCollateral;
        _optionInfo.totalDepositedToLendingPool += depositCollateral;
    }

    /**
     * @notice repays underlying asset and withdraws USDC from compound
     * @param _optionInfo option vault object
     * @param _vault the vault repaying underlying asset
     * @param _spot spot price
     * @param _underlyingAmount amount to repay
     * @param _remainingDebt The remaining debt after the repayment, scaled by 1e8.
     */
    function repayUnderlyingInternal(
        OptionInfo storage _optionInfo,
        IOptionVault.Vault storage _vault,
        uint128 _spot,
        uint256 _underlyingAmount,
        uint256 _remainingDebt
    ) internal {
        IERC20(_optionInfo.tokens.underlying).approve(address(_optionInfo.lendingPool), _underlyingAmount);
        repayBorrow(_optionInfo, _underlyingAmount);

        // calculate unrequired collateral
        // if maturity is large, the protocol have to pay borrowing interest, and it can not redeem all shortLiquidity.
        // In this case, repay underling from outside of protocol.
        uint128 redeemCollateralAmount = _vault.shortLiquidity - (uint128(_remainingDebt) * _spot * 2) / 1e10;

        _optionInfo.lendingPool.withdraw(_optionInfo.tokens.collateral, redeemCollateralAmount, address(this));

        increaseCollateral(_vault, redeemCollateralAmount);

        _vault.shortLiquidity -= redeemCollateralAmount;
        _optionInfo.totalDepositedToLendingPool -= redeemCollateralAmount;
    }

    /**
     * @notice borrow underlying asset with Variable type debt
     */
    function borrow(OptionInfo storage _optionInfo, uint256 _amount) internal {
        _optionInfo.lendingPool.borrow(_optionInfo.tokens.underlying, _amount, 2, 0, address(this));
    }

    /**
     * @notice repay borrowing underlying asset with Variable type debt
     */
    function repayBorrow(OptionInfo storage _optionInfo, uint256 _amount) internal returns (uint128) {
        return uint128(_optionInfo.lendingPool.repay(_optionInfo.tokens.underlying, _amount, 2, address(this)));
    }
}
