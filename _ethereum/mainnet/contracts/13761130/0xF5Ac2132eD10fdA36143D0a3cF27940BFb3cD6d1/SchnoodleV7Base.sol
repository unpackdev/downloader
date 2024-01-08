// contracts/imports/SchnoodleV7Base.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC777PresetFixedSupplyUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./MathUpgradeable.sol";

abstract contract SchnoodleV7Base is ERC777PresetFixedSupplyUpgradeable, OwnableUpgradeable {
    uint256 private constant MAX = ~uint256(0);
    uint256 private _totalSupply;
    uint256 private _feeRate;
    address private _eleemosynaryAccount;
    uint256 private _donationRate;
    uint256 private _sellThreshold;
    TokenMeter private _sellQuota;
    uint256 private _rateEscalator;

    struct TokenMeter {
        uint256 blockMetric;
        int256 amount;
    }

    function initialize(uint256 initialTokens, address serviceAccount) public initializer {
        __Ownable_init();
        _totalSupply = initialTokens * 10 ** decimals();
        __ERC777PresetFixedSupply_init("Schnoodle", "SNOOD", new address[](0), MAX - (MAX % totalSupply()), serviceAccount);
    }

    function configure(bool testnet) internal onlyOwner {
        _feeRate = 40;
        _rateEscalator = 6;

        if (testnet) {
            _sellThreshold = 10 ** 9 * 10 ** decimals();
        }
    }

    // Transfer overrides

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _getStandardAmount(super.balanceOf(account));
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 reflectedAmount = _getReflectedAmount(amount);
        bool result = super.transfer(recipient, reflectedAmount);
        emit Transfer(_msgSender(), recipient, amount);
        processSwap(_msgSender(), recipient, amount, reflectedAmount, _transferFromReflected);

        return result;
    }

    function allowance(address holder, address spender) public view virtual override returns (uint256) {
        return _getStandardAmount(super.allowance(holder, spender));
    }

    function approve(address spender, uint256 value) public virtual override returns (bool) {
        return super.approve(spender, _getReflectedAmount(value));
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 reflectedAmount = _getReflectedAmount(amount);
        bool result = super.transferFrom(sender, recipient, reflectedAmount);
        emit Transfer(sender, recipient, amount);
        processSwap(sender, recipient, amount, reflectedAmount, _transferFromReflected);

        return result;
    }

    function _mint(address account, uint256 amount, bytes memory userData, bytes memory operatorData, bool requireReceptionAck) internal virtual override {
        super._mint(account, amount, userData, operatorData, requireReceptionAck);
    }

    function _burn(address account, uint256 amount, bytes memory data, bytes memory operatorData) internal virtual override {
        super._burn(account, _getReflectedAmount(amount), data, operatorData);
        _totalSupply -= amount;
    }

    function _send(address from, address to, uint256 amount, bytes memory userData, bytes memory operatorData, bool requireReceptionAck) internal virtual override {
        uint256 reflectedAmount = _getReflectedAmount(amount);
        super._send(from, to, reflectedAmount, userData, operatorData, requireReceptionAck);
        emit Transfer(from, to, amount);
        processSwap(from, to, amount, reflectedAmount, _sendReflected);
    }

    // Reflection convenience functions

    function _transferFromReflected(address from, address to, uint256 reflectedAmount) internal {
        _approve(from, _msgSender(), reflectedAmount);
        super.transferFrom(from, to, reflectedAmount);
    }

    function _sendReflected(address from, address to, uint256 reflectedAmount) internal {
        super._send(from, to, reflectedAmount, "", "", true);
    }

    function _getReflectedAmount(uint256 amount) internal view returns(uint256) {
        return amount * _getReflectRate();
    }

    function _getStandardAmount(uint256 reflectedAmount) internal view returns(uint256) {
        // Condition prevents a divide-by-zero error when the total supply is zero
        return reflectedAmount == 0 ? 0 : reflectedAmount / _getReflectRate();
    }

    function _getReflectRate() private view returns(uint256) {
        uint256 reflectedTotalSupply = super.totalSupply();
        return reflectedTotalSupply == 0 ? 0 : super.totalSupply() / totalSupply();
    }

    // Taxation functions

    function processSwap(address from, address to, uint256 amount, uint256 reflectedAmount, function(address, address, uint256) internal transferCallback) internal virtual {
        // Maintain a sell quota as the net of all daily buys and sells, plus a predefined threshold
        if (_sellThreshold > 0) {
            uint256 blockTimestamp = block.timestamp;

            if (_sellQuota.blockMetric == 0 || _sellQuota.blockMetric < blockTimestamp - 1 days) {
                _sellQuota.blockMetric = blockTimestamp;
                _sellQuota.amount = int256(_sellThreshold);
                emit SellQuotaChanged(_sellQuota.blockMetric, _sellQuota.amount);
            }

            _sellQuota.amount += (isLiquidityToken(from) ? int256(1) : -1) * int256(amount);
            emit SellQuotaChanged(_sellQuota.blockMetric, _sellQuota.amount);
        }

        // Proceed to pay fee and tax if only a sell at this point
        if (!(isLiquidityToken(to))) return;

        payFees(to, amount, reflectedAmount, transferCallback);
    }

    function isLiquidityToken(address) internal view virtual returns(bool);

    function payFees(address to, uint256 amount, uint256 reflectedAmount, function(address, address, uint256) internal transferCallback) internal virtual {
        uint256 operativeFeeRate = getOperativeFeeRate();
        super._burn(to, reflectedAmount / 1000 * operativeFeeRate, "", "");
        emit Transfer(to, address(0), amount * operativeFeeRate / 1000);

        payFund(to, _eleemosynaryAccount, amount, _donationRate, transferCallback);
    }

    function payFund(address from, address to, uint256 amount, uint256 rate, function(address, address, uint256) internal transferCallback) internal {
        // Skip if not enabled ('to' address not set)
        if (to != address(0)) {
            uint256 fundAmount = amount * rate / 1000;
            uint256 reflectedFundAmount = _getReflectedAmount(fundAmount);
            transferCallback(from, to, reflectedFundAmount);
            emit Transfer(from, to, fundAmount);
        }
    }

    function changeFeeRate(uint256 rate) external onlyOwner {
        _feeRate = rate;
        emit FeeRateChanged(rate);
    }

    function getFeeRate() external view returns(uint256) {
        return _feeRate;
    }

    function getOperativeFeeRate() public view returns(uint256) {
        // Increase the fee linearly when the sell quota is negative (more daily sells than buys including the predefined threshold)
        if (_sellThreshold > 0 && _sellQuota.amount < 0)
        {
            return _feeRate + _feeRate * _rateEscalator * MathUpgradeable.min(uint256(-_sellQuota.amount), _sellThreshold) / _sellThreshold;
        }

        return _feeRate;
    }

    function changeEleemosynaryDetails(address eleemosynaryAccount, uint256 donationRate) external onlyOwner {
        _eleemosynaryAccount = eleemosynaryAccount;
        _donationRate = donationRate;
        emit EleemosynaryDetailsChanged(eleemosynaryAccount, donationRate);
    }

    function getEleemosynaryDetails() external view returns(address, uint256) {
        return (_eleemosynaryAccount, _donationRate);
    }

    function changeSellThresholdDetails(uint256 sellThreshold, uint256 rateEscalator) external onlyOwner {
        _sellThreshold = sellThreshold;
        _rateEscalator = rateEscalator;
        emit SellThresholdDetailsChanged(sellThreshold, rateEscalator);
    }

    function getSellThresholdDetails() external view returns(uint256, uint256) {
        return (_sellThreshold, _rateEscalator);
    }

    function getSellQuota() external view returns(TokenMeter memory) {
        return _sellQuota;
    }

    event FeeRateChanged(uint256 rate);

    event EleemosynaryDetailsChanged(address indexed eleemosynaryAccount, uint256 donationRate);

    event SellThresholdDetailsChanged(uint256 sellThreshold, uint256 rateEscalator);

    event SellQuotaChanged(uint256 blockTimestamp, int256 amount);
}
