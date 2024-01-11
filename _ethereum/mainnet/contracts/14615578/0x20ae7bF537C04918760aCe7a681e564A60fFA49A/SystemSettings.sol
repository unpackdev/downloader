// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import "./BasicMaths.sol";
import "./ISystemSettings.sol";
import "./IPool.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract SystemSettings is ISystemSettings, Ownable {
    using SafeMath for uint256;
    using BasicMaths for uint256;
    using BasicMaths for bool;

    mapping(address => PoolSetting) private _poolSettings;
    mapping(address => uint256) private _debtSettings;
    mapping(uint32 => bool) public override leverages;
    uint256 public override marginRatio;
    uint256 public override protocolFee;
    uint256 public override liqProtocolFee;
    uint256 public override closingFee;
    uint256 public override liqFeeBase;
    uint256 public override liqFeeMax;
    uint256 public override liqFeeCoefficient;
    uint256 public override rebaseCoefficient;
    uint256 public override imbalanceThreshold;
    uint256 public override priceDeviationCoefficient;
    uint256 public override debtStart;
    uint256 public override debtAll;
    uint256 public override minDebtRepay;
    uint256 public override maxDebtRepay;
    uint256 public override interestRate;
    uint256 public override liquidityCoefficient;

    uint256 private _liqLsRequire;
    uint256 private _minHoldingPeriod;
    bool    private _deviation;

    uint256 private constant E4 = 1e4;
    uint256 private constant E18 = 1e18;
    uint256 private constant E38 = 1e38;

    bool private _active;
    address private _official;
    address private _suspender;
    address private _deployer02;

    constructor(address deployer02) {
        _official = msg.sender;
        _suspender = msg.sender;
        _deployer02 = deployer02;
    }

    function official() external view override returns (address) {
        return _official;
    }

    function deployer02() external view override returns (address) {
        return _deployer02;
    }

    function requireSystemActive() external view override {
        require(_active, "system is suspended");
    }

    function requireSystemSuspend() external view override {
        require(!_active, "system is active");
    }

    function resumeSystem() external override onlySuspender {
        _active = true;
        emit Resume(msg.sender);
    }

    function suspendSystem() external override onlySuspender {
        _active = false;
        emit Suspend(msg.sender);
    }

    function liqLsRequire() external view override returns (uint256) {
        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            return _liqLsRequire;
        } else {
            return poolSetting.liqLsRequire;
        }
    }

    function minHoldingPeriod() external view override returns (uint256) {
        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            return _minHoldingPeriod;
        } else {
            return poolSetting.minHoldingPeriod;
        }
    }

    function deviation() external view override returns (bool) {
        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            return _deviation;
        } else {
            return poolSetting.deviation;
        }
    }

    function checkOpenPosition(uint16 level) external view override {
        require(_active, "system is suspended");
        require(leverages[level], "Non-Exist Leverage");
    }

    function mulClosingFee(uint256 value)
        external
        view
        override
        returns (uint256)
    {
        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            return closingFee.mul(value) / E4;
        } else {
            return poolSetting.closingFee.mul(value) / E4;
        }
    }

    function mulLiquidationFee(uint256 margin, uint256 deltaBlock)
        external
        view
        override
        returns (uint256)
    {
        PoolSetting memory poolSetting = _poolSettings[msg.sender];

        uint256 liqRatio;
        if (poolSetting.owner == address(0)) {
            if (liqFeeBase == liqFeeMax) {
                return liqFeeBase.mul(margin) / E4;
            }

            liqRatio = deltaBlock.mul(liqFeeMax.sub(liqFeeBase)) / liqFeeCoefficient + liqFeeBase;
            if (liqRatio < liqFeeMax) {
                return liqRatio.mul(margin) / E4;
            } else {
                return liqFeeMax.mul(margin) / E4;
            }
        } else {
            if (poolSetting.liqFeeBase == poolSetting.liqFeeMax) {
                return poolSetting.liqFeeBase.mul(margin) / E4;
            }

            liqRatio = deltaBlock.mul(poolSetting.liqFeeMax.sub(poolSetting.liqFeeBase)) / poolSetting.liqFeeCoefficient + poolSetting.liqFeeBase;
            if (liqRatio < poolSetting.liqFeeMax) {
                return liqRatio.mul(margin) / E4;
            } else {
                return poolSetting.liqFeeMax.mul(margin) / E4;
            }
        }
    }

    function mulMarginRatio(uint256 margin)
        external
        view
        override
        returns (uint256)
    {
        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            return marginRatio.mul(margin) / E4;
        } else {
            return poolSetting.marginRatio.mul(margin) / E4;
        }
    }

    function mulProtocolFee(uint256 amount)
        external
        view
        override
        returns (uint256)
    {
        return protocolFee.mul(amount) / E4;
    }

    function mulLiqProtocolFee(uint256 amount)
        external
        view
        override
        returns (uint256)
    {
        return liqProtocolFee.mul(amount) / E4;
    }

    function meetImbalanceThreshold(
        uint256 nakedPosition,
        uint256 liquidityPool
    ) external view override returns (bool) {
        uint256 D = (nakedPosition).mul(E4) / liquidityPool;

        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            return D > imbalanceThreshold;
        } else {
            return D > poolSetting.imbalanceThreshold;
        }
    }

    function mulImbalanceThreshold(uint256 liquidityPool)
        external
        view
        override
        returns (uint256)
    {
        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            return liquidityPool.mul(imbalanceThreshold) / E4;
        } else {
            return liquidityPool.mul(poolSetting.imbalanceThreshold) / E4;
        }
    }

    function calRebaseDelta(
        uint256 rebaseSizeXBlockDelta,
        uint256 imbalanceSize
    ) external view override returns (uint256) {
        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            return rebaseSizeXBlockDelta.mul(E18).div(rebaseCoefficient).div(imbalanceSize);
        } else {
            return rebaseSizeXBlockDelta.mul(E18).div(poolSetting.rebaseCoefficient).div(imbalanceSize);
        }
    }

    function calDeviation(uint256 nakedPosition, uint256 liquidityPool)
        external
        view
        override
        returns (uint256)
    {
        uint256 D = nakedPosition.mul(E18) / liquidityPool;
        require(D < E38, "Maximum deviation is 100%");

        uint256 deviationResult;
        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            deviationResult = (D.pow() / E18).mul(
                priceDeviationCoefficient
            ) / E4;
        } else {
            deviationResult = (D.pow() / E18).mul(
                poolSetting.priceDeviationCoefficient
            ) / E4;
        }

        // Maximum deviation is 1e18
        require(deviationResult < E18, "Maximum deviation is 100%");
        return deviationResult;
    }

    function calDebtRepay(
        uint256 lsPnl,
        uint256 totalDebtWithInterest,
        uint256 totalLiquidity
    ) external view override returns (uint256 repay) {

        uint256 minRepay;
        uint256 maxRepay;
        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            minRepay = lsPnl.mul(minDebtRepay) / E4;
            maxRepay = lsPnl.mul(maxDebtRepay) / E4;
        } else {
            minRepay = lsPnl.mul(poolSetting.minDebtRepay) / E4;
            maxRepay = lsPnl.mul(poolSetting.maxDebtRepay) / E4;
        }

        repay = totalDebtWithInterest.pow().mul(lsPnl) / totalLiquidity.pow();

        if (repay < minRepay) {
            repay = minRepay;
        }

        if (repay > maxRepay) {
            repay = maxRepay;
        }

        if (repay > totalDebtWithInterest) {
            repay = totalDebtWithInterest;
        }

        return repay;
    }

    function calDebtIssue(
        uint256 tdPnl,
        uint256 lsAvgPrice,
        uint256 lsPrice
    ) external view override returns (uint256) {

        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            if (lsPrice.mul(E4) >= lsAvgPrice.mul(debtStart)) {
                return 0;
            }

            if (lsPrice.mul(E4) <= lsAvgPrice.mul(debtAll)) {
                return tdPnl;
            }
        } else {
            if (lsPrice.mul(E4) >= lsAvgPrice.mul(poolSetting.debtStart)) {
                return 0;
            }

            if (lsPrice.mul(E4) <= lsAvgPrice.mul(poolSetting.debtAll)) {
                return tdPnl;
            }
        }

        return lsAvgPrice.sub(lsPrice).pow().mul(tdPnl) / lsAvgPrice.pow();
    }

    function mulInterestFromDebt(
        uint256 amount
    ) external view override returns (uint256) {
        uint256 interestRateFromDebt = _debtSettings[msg.sender];
        if (interestRateFromDebt == 0) {
            return amount.mul(interestRate) / E4;
        } else {
            return amount.mul(interestRateFromDebt) / E4;
        }
    }

    function divInterestFromDebt(
        uint256 amount
    ) external view override returns (uint256) {
        uint256 interestRateFromDebt = _debtSettings[msg.sender];
        if (interestRateFromDebt == 0) {
            return amount.mul(E4) / interestRate;
        } else {
            return amount.mul(E4) / interestRateFromDebt;
        }
    }

    function mulLiquidityCoefficient(
        uint256 nakedPositions
    ) external view override returns (uint256) {
        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            return nakedPositions.mul(E4).div(liquidityCoefficient);
        } else {
            return nakedPositions.mul(E4).div(poolSetting.liquidityCoefficient);
        }
    }

    /*--------------------------------------------------------------------------------------------------*/

    function setProtocolFee(uint256 protocolFee_) external onlyOwner {
        require(protocolFee_ <= E4, "over range");
        protocolFee = protocolFee_;
        emit SetSystemParam(systemParam.ProtocolFee, protocolFee_);
    }

    function setLiqProtocolFee(uint256 liqProtocolFee_) external onlyOwner {
        require(liqProtocolFee_ <= E4, "over range");
        liqProtocolFee = liqProtocolFee_;
        emit SetSystemParam(systemParam.LiqProtocolFee, liqProtocolFee_);
    }

    function setMarginRatio(uint256 marginRatio_) external onlyOwner {
        require(marginRatio_ <= E4, "over range");
        marginRatio = marginRatio_;
        emit SetSystemParam(systemParam.MarginRatio, marginRatio_);
    }

    function setClosingFee(uint256 closingFee_) external onlyOwner {
        require(closingFee_ <= 1e2, "over range");
        closingFee = closingFee_;
        emit SetSystemParam(systemParam.ClosingFee, closingFee_);
    }

    function setLiqFeeBase(uint256 liqFeeBase_) external onlyOwner {
        require(liqFeeBase_ <= E4, "over range");
        require(liqFeeMax > liqFeeBase_, "liqFeeMax must > liqFeeBase");
        liqFeeBase = liqFeeBase_;
        emit SetSystemParam(systemParam.LiqFeeBase, liqFeeBase_);
    }

    function setLiqFeeMax(uint256 liqFeeMax_) external onlyOwner {
        require(liqFeeMax_ <= E4, "over range");
        require(liqFeeMax_ > liqFeeBase, "liqFeeMax must > liqFeeBase");
        liqFeeMax = liqFeeMax_;
        emit SetSystemParam(systemParam.LiqFeeMax, liqFeeMax_);
    }

    function setLiqFeeCoefficient(uint256 liqFeeCoefficient_) external onlyOwner {
        require(liqFeeCoefficient_ > 0 && liqFeeCoefficient_ <= 576000, "over range");
        liqFeeCoefficient = liqFeeCoefficient_;
        emit SetSystemParam(systemParam.LiqFeeCoefficient, liqFeeCoefficient_);
    }

    function setLiqLsRequire(uint256 liqLsRequire_) external onlyOwner {
        _liqLsRequire = liqLsRequire_;
        emit SetSystemParam(systemParam.LiqLsRequire, liqLsRequire_);
    }

    function addLeverage(uint32 leverage_) external onlyOwner {
        leverages[leverage_] = true;
        emit AddLeverage(leverage_);
    }

    function deleteLeverage(uint32 leverage_) external onlyOwner {
        leverages[leverage_] = false;
        emit DeleteLeverage(leverage_);
    }

    function setRebaseCoefficient(uint256 rebaseCoefficient_)
        external
        onlyOwner
    {
        require(rebaseCoefficient_ > 0 && rebaseCoefficient_ <= 5760000, "over range");
        rebaseCoefficient = rebaseCoefficient_;
        emit SetSystemParam(systemParam.RebaseCoefficient, rebaseCoefficient_);
    }

    function setImbalanceThreshold(uint256 imbalanceThreshold_)
        external
        onlyOwner
    {
        require(imbalanceThreshold_ <= 1e6, "over range");
        imbalanceThreshold = imbalanceThreshold_;
        emit SetSystemParam(
            systemParam.ImbalanceThreshold,
            imbalanceThreshold_
        );
    }

    function setPriceDeviationCoefficient(uint256 priceDeviationCoefficient_)
        external
        onlyOwner
    {
        require(priceDeviationCoefficient_ <= 1e6, "over range");
        priceDeviationCoefficient = priceDeviationCoefficient_;
        emit SetSystemParam(
            systemParam.PriceDeviationCoefficient,
            priceDeviationCoefficient_
        );
    }

    function setMinHoldingPeriod(uint256 minHoldingPeriod_)
        external
        onlyOwner
    {
        require(minHoldingPeriod_ <= 5760, "over range");
        _minHoldingPeriod = minHoldingPeriod_;
        emit SetSystemParam(
            systemParam.MinHoldingPeriod,
            minHoldingPeriod_
        );
    }

    function setDebtStart(uint256 debtStart_)
        external
        onlyOwner
    {
        require(debtStart_ <= E4, "over range");
        debtStart = debtStart_;
        emit SetSystemParam(
            systemParam.DebtStart,
            debtStart_
        );
    }

    function setDebtAll(uint256 debtAll_)
        external
        onlyOwner
    {
        require(debtAll_ <= E4, "over range");
        debtAll = debtAll_;
        emit SetSystemParam(
            systemParam.DebtAll,
            debtAll_
        );
    }

    function setMinDebtRepay(uint256 minDebtRepay_)
        external
        onlyOwner
    {
        require(minDebtRepay_ <= E4, "over range");
        minDebtRepay = minDebtRepay_;
        emit SetSystemParam(
            systemParam.MinDebtRepay,
            minDebtRepay_
        );
    }

    function setMaxDebtRepay(uint256 maxDebtRepay_)
        external
        onlyOwner
    {
        require(maxDebtRepay_ <= E4, "over range");
        maxDebtRepay = maxDebtRepay_;
        emit SetSystemParam(
            systemParam.MaxDebtRepay,
            maxDebtRepay_
        );
    }

    function setInterestRate(uint256 interestRate_)
        external
        onlyOwner
    {
        require(interestRate_ >= E4 && interestRate_ <= 2*E4, "over range");
        interestRate = interestRate_;
        emit SetSystemParam(
            systemParam.InterestRate,
            interestRate_
        );
    }

    function setLiquidityCoefficient(uint256 liquidityCoefficient_)
        external
        onlyOwner
    {
        require(liquidityCoefficient_ > 0 && liquidityCoefficient_ <= 1e6, "over range");
        liquidityCoefficient = liquidityCoefficient_;
        emit SetSystemParam(
            systemParam.LiquidityCoefficient,
            liquidityCoefficient_
        );
    }

    function setDeviation(bool deviation_) external onlyOwner {
        _deviation = deviation_;
        emit SetDeviation(_deviation);
    }

    /*--------------------------------------------------------------------------------------------------*/

    function setMarginRatioByPool(address pool, uint256 marginRatio_) external onlyPoolOwner(pool) {
        require(marginRatio_ <= E4, "over range");
        _poolSettings[pool].marginRatio = marginRatio_;
        emit SetPoolParam(pool, systemParam.MarginRatio, marginRatio_);
    }

    function setClosingFeeByPool(address pool, uint256 closingFee_) external onlyPoolOwner(pool) {
        require(closingFee_ <= E4, "over range");
        _poolSettings[pool].closingFee = closingFee_;
        emit SetPoolParam(pool, systemParam.ClosingFee, closingFee_);
    }

    function setLiqFeeBaseByPool(address pool, uint256 liqFeeBase_) external onlyPoolOwner(pool) {
        require(liqFeeBase_ <= E4, "over range");
        require(_poolSettings[pool].liqFeeMax > liqFeeBase_, "liqFeeMax must > liqFeeBase");
        _poolSettings[pool].liqFeeBase = liqFeeBase_;
        emit SetPoolParam(pool, systemParam.LiqFeeBase, liqFeeBase_);
    }

    function setLiqFeeMaxByPool(address pool, uint256 liqFeeMax_) external onlyPoolOwner(pool) {
        require(liqFeeMax_ <= E4, "over range");
        require(liqFeeMax_ > _poolSettings[pool].liqFeeBase, "liqFeeMax must > liqFeeBase");
        _poolSettings[pool].liqFeeMax = liqFeeMax_;
        emit SetPoolParam(pool, systemParam.LiqFeeMax, liqFeeMax_);
    }

    function setLiqFeeCoefficientByPool(address pool, uint256 liqFeeCoefficient_) external onlyPoolOwner(pool) {
        require(liqFeeCoefficient_ > 0 && liqFeeCoefficient_ <= 576000, "over range");
        _poolSettings[pool].liqFeeCoefficient = liqFeeCoefficient_;
        emit SetPoolParam(pool, systemParam.LiqFeeCoefficient, liqFeeCoefficient_);
    }

    function setLiqLsRequireByPool(address pool, uint256 liqLsRequire_) external onlyPoolOwner(pool) {
        _poolSettings[pool].liqLsRequire = liqLsRequire_;
        emit SetPoolParam(pool, systemParam.LiqLsRequire, liqLsRequire_);
    }

    function setRebaseCoefficientByPool(address pool, uint256 rebaseCoefficient_) external onlyPoolOwner(pool) {
        require(rebaseCoefficient_ > 0 && rebaseCoefficient_ <= 5760000, "over range");
        _poolSettings[pool].rebaseCoefficient = rebaseCoefficient_;
        emit SetPoolParam(pool, systemParam.RebaseCoefficient, rebaseCoefficient_);
    }

    function setImbalanceThresholdByPool(address pool, uint256 imbalanceThreshold_) external onlyPoolOwner(pool) {
        require(imbalanceThreshold_ <= 1e6, "over range");
        _poolSettings[pool].imbalanceThreshold = imbalanceThreshold_;
        emit SetPoolParam(pool, systemParam.ImbalanceThreshold, imbalanceThreshold_);
    }

    function setPriceDeviationCoefficientByPool(address pool, uint256 priceDeviationCoefficient_) external onlyPoolOwner(pool) {
        require(priceDeviationCoefficient_ <= 1e6, "over range");
        _poolSettings[pool].priceDeviationCoefficient = priceDeviationCoefficient_;
        emit SetPoolParam(pool, systemParam.PriceDeviationCoefficient, priceDeviationCoefficient_);
    }

    function setMinHoldingPeriodByPool(address pool, uint256 minHoldingPeriod_) external onlyPoolOwner(pool) {
        require(minHoldingPeriod_ <= 5760, "over range");
        _poolSettings[pool].minHoldingPeriod = minHoldingPeriod_;
        emit SetPoolParam(pool, systemParam.MinHoldingPeriod, minHoldingPeriod_);
    }

    function setDebtStartByPool(address pool, uint256 debtStart_) external onlyPoolOwner(pool) {
        require(debtStart_ <= E4, "over range");
        _poolSettings[pool].debtStart = debtStart_;
        emit SetPoolParam(pool, systemParam.DebtStart, debtStart_);
    }

    function setDebtAllByPool(address pool, uint256 debtAll_) external onlyPoolOwner(pool) {
        require(debtAll_ <= E4, "over range");
        _poolSettings[pool].debtAll = debtAll_;
        emit SetPoolParam(pool, systemParam.DebtAll, debtAll_);
    }

    function setMinDebtRepayByPool(address pool, uint256 minDebtRepay_) external onlyPoolOwner(pool) {
        require(minDebtRepay_ <= E4, "over range");
        _poolSettings[pool].minDebtRepay = minDebtRepay_;
        emit SetPoolParam(pool, systemParam.MinDebtRepay, minDebtRepay_);
    }

    function setMaxDebtRepayByPool(address pool, uint256 maxDebtRepay_) external onlyPoolOwner(pool) {
        require(maxDebtRepay_ <= E4, "over range");
        _poolSettings[pool].maxDebtRepay = maxDebtRepay_;
        emit SetPoolParam(pool, systemParam.MaxDebtRepay, maxDebtRepay_);
    }

    function setInterestRateByPool(address pool, uint256 interestRate_) external onlyPoolOwner(pool) {
        require(interestRate_ >= E4 && interestRate_ <= 2*E4, "over range");
        _poolSettings[pool].interestRate = interestRate_;
        _debtSettings[IPool(pool).debtToken()] = interestRate_;
        emit SetPoolParam(pool, systemParam.InterestRate, interestRate_);
    }

    function setLiquidityCoefficientByPool(address pool, uint256 liquidityCoefficient_) external onlyPoolOwner(pool) {
        require(liquidityCoefficient_ > 0 && liquidityCoefficient_ <= 1e6, "over range");
        _poolSettings[pool].liquidityCoefficient = liquidityCoefficient_;
        emit SetPoolParam(pool, systemParam.LiquidityCoefficient, liquidityCoefficient_);
    }

    function setDeviationByPool(address pool, bool deviation_) external onlyPoolOwner(pool) {
        _poolSettings[pool].deviation = deviation_;
        emit SetPoolDeviation(pool, deviation_);
    }

    function setPoolOwner(address pool, address newOwner) external onlyOwner {
        if (_poolSettings[pool].owner != address(0)) {
            _poolSettings[pool].owner = newOwner;
        } else {
            _poolSettings[pool] = PoolSetting(
                newOwner,
                marginRatio,
                closingFee,
                liqFeeBase,
                liqFeeMax,
                liqFeeCoefficient,
                _liqLsRequire,
                rebaseCoefficient,
                imbalanceThreshold,
                priceDeviationCoefficient,
                _minHoldingPeriod,
                debtStart,
                debtAll,
                minDebtRepay,
                maxDebtRepay,
                interestRate,
                liquidityCoefficient,
                _deviation
            );
            _debtSettings[IPool(pool).debtToken()] = interestRate;
        }

        emit SetPoolOwner(pool, newOwner);
    }

    function setOfficial(address official) external onlyOwner {
        _official = official;
    }

    function setSuspender(address suspender) external onlySuspender {
        _suspender = suspender;
    }

    modifier onlySuspender() {
        require(
            _suspender == msg.sender,
            "caller is not the suspender"
        );
        _;
    }

    modifier onlyPoolOwner(address pool) {
        require(
            _poolSettings[pool].owner == msg.sender,
            "caller is not the pool owner"
        );
        _;
    }
}
