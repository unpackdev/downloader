// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import "./Ownable.sol";

import "./ISystemSetting.sol";

contract SystemSetting is Ownable, ISystemSetting {
    uint256 private _maxInitialLiquidityFunding;   // decimals 6
    uint256 private _constantMarginRatio;
    mapping (uint32 => bool) private _leverages;
    uint256 private _minInitialMargin;             // decimals 6
    uint256 private _minAddDeposit;                // decimals 6
    uint256 private _minHoldingPeriod;
    uint256 private _marginRatio;
    uint256 private _positionClosingFee;
    uint256 private _liquidationFee;
    uint256 private _rebaseInterval;
    uint256 private _rebaseRate;
    uint256 private _imbalanceThreshold;
    uint256 private _minFundTokenRequired;         // decimals 6

    uint256 private constant POSITION_CLOSING_FEE_MIN = 1 * 1e15; // 1e15 / 1e18 = 0.1%
    uint256 private constant POSITION_CLOSING_FEE_MAX = 5 * 1e15; // 5e15 / 1e18 = 0.5%

    uint256 private constant LIQUIDATION_FEE_MIN = 1 * 1e16; // 1e16 / 1e18 = 1%
    uint256 private constant LIQUIDATION_FEE_MAX = 5 * 1e16; // 5e16 / 1e18 = 5%

    uint256 private constant REBASE_RATE_MIN = 20;
    uint256 private constant REBASE_RATE_MAX = 2000;

    bool private _active;

    function requireSystemActive() external override view {
        require(_active, "system is suspended");
    }

    function resumeSystem() external override onlyOwner {
        _active = true;
        emit Resume(msg.sender);
    }

    function suspendSystem() external override onlyOwner {
        _active = false;
        emit Suspend(msg.sender);
    }

    function maxInitialLiquidityFunding() external override view returns (uint256) {
        return _maxInitialLiquidityFunding;
    }

    function constantMarginRatio() external override view returns (uint256) {
        return _constantMarginRatio;
    }

    function leverageExist(uint32 leverage_) external override view returns (bool) {
        return _leverages[leverage_];
    }

    function minInitialMargin() external override view returns (uint256) {
        return _minInitialMargin;
    }

    function minAddDeposit() external override view returns (uint256) {
        return _minAddDeposit;
    }

    function minHoldingPeriod() external override view returns (uint) {
        return _minHoldingPeriod;
    }

    function marginRatio() external override view returns (uint256) {
        return _marginRatio;
    }

    function positionClosingFee() external override view returns (uint256) {
        return _positionClosingFee;
    }

    function liquidationFee() external override view returns (uint256) {
        return _liquidationFee;
    }

    function rebaseInterval() external override view returns (uint) {
        return _rebaseInterval;
    }

    function rebaseRate() external override view returns (uint) {
        return _rebaseRate;
    }

    function imbalanceThreshold() external override view returns (uint) {
        return _imbalanceThreshold;
    }

    function minFundTokenRequired() external override view returns (uint) {
        return _minFundTokenRequired;
    }

    function setMaxInitialLiquidityFunding(uint256 maxInitialLiquidityFunding_) external onlyOwner {
        _maxInitialLiquidityFunding = maxInitialLiquidityFunding_;
    }

    function setConstantMarginRatio(uint256 constantMarginRatio_) external onlyOwner {
        _constantMarginRatio = constantMarginRatio_;
    }

    function setMinInitialMargin(uint256 minInitialMargin_) external onlyOwner {
        _minInitialMargin = minInitialMargin_;
    }

    function setMinAddDeposit(uint minAddDeposit_) external onlyOwner {
        _minAddDeposit = minAddDeposit_;
    }

    function setMinHoldingPeriod(uint minHoldingPeriod_) external onlyOwner {
        _minHoldingPeriod = minHoldingPeriod_;
    }

    function setMarginRatio(uint256 marginRatio_) external onlyOwner {
        _marginRatio = marginRatio_;
    }

    function setPositionClosingFee(uint256 positionClosingFee_) external onlyOwner {
        require(positionClosingFee_ >= POSITION_CLOSING_FEE_MIN, "positionClosingFee_ should >= 0.1%");
        require(positionClosingFee_ <= POSITION_CLOSING_FEE_MAX, "positionClosingFee_ should <= 0.5%");

        _positionClosingFee = positionClosingFee_;
    }

    function setLiquidationFee(uint256 liquidationFee_) external onlyOwner {
        require(liquidationFee_ >= LIQUIDATION_FEE_MIN, "liquidationFee_ should >= 10%");
        require(liquidationFee_ <= LIQUIDATION_FEE_MAX, "liquidationFee_ should <= 20%");

        _liquidationFee = liquidationFee_;
    }

    function addLeverage(uint32 leverage_) external onlyOwner {
        _leverages[leverage_] = true;
    }

    function deleteLeverage(uint32 leverage_) external onlyOwner {
        _leverages[leverage_] = false;
    }

    function setRebaseInterval(uint rebaseInterval_) external onlyOwner {
        _rebaseInterval = rebaseInterval_;
    }

    function setRebaseRate(uint rebaseRate_) external onlyOwner {
        require(rebaseRate_ >= REBASE_RATE_MIN, "rebaseRate_ should >= 200");
        require(rebaseRate_ <= REBASE_RATE_MAX, "rebaseRate_ should <= 2000");

        _rebaseRate = rebaseRate_;
    }

    function setImbalanceThreshold(uint imbalanceThreshold_) external onlyOwner {
        _imbalanceThreshold = imbalanceThreshold_;
    }

    function setMinFundTokenRequired(uint minFundTokenRequired_) external onlyOwner {
        _minFundTokenRequired = minFundTokenRequired_;
    }

    function checkOpenPosition(uint position, uint16 level) external view override {
        require(_active, "system is suspended");
        require(_leverages[level], "Leverage Not Exist");
        require(_minInitialMargin <= position, "Too Less Initial Margin");
    }

    function checkAddDeposit(uint margin) external view override {
        require(_active, "system is suspended");
        require(_minAddDeposit <= margin, "Too Less Margin");
    }
}
