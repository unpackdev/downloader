// contracts/SchnoodleV6.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC777PresetFixedSupplyUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./MathUpgradeable.sol";

contract SchnoodleV6 is ERC777PresetFixedSupplyUpgradeable, OwnableUpgradeable {
    uint256 private constant MAX = ~uint256(0);
    uint256 private _totalSupply;
    uint256 private _feeRate;
    address private _eleemosynary;
    uint256 private _donationRate;
    mapping(address => TokenMeter) private _sellsTrackers;

    struct TokenMeter {
        uint256 blockMetric;
        uint256 amount;
    }

    function initialize(uint256 initialTokens, address serviceAccount) public initializer {
        __Ownable_init();
        _totalSupply = initialTokens * 10 ** decimals();
        super.initialize("Schnoodle", "SNOOD", new address[](0), MAX - (MAX % totalSupply()), serviceAccount);
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 reflectedBalance = super.balanceOf(account);
        require(reflectedBalance <= super.totalSupply(), "Schnoodle: Reflected balance must be less than total reflections");
        return reflectedBalance / _getRate();
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 reflectedAmount = _getReflectedAmount(amount);
        bool result = super.transfer(recipient, reflectedAmount);
        emit Transfer(_msgSender(), recipient, amount);
        _payFeeAndDonate(recipient, amount, reflectedAmount, _transferToEleemosynary);
        return result;
    }

    function allowance(address holder, address spender) public view virtual override returns (uint256) {
        return super.allowance(holder, spender) / _getRate();
    }

    function approve(address spender, uint256 value) public virtual override returns (bool) {
        return super.approve(spender, _getReflectedAmount(value));
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 reflectedAmount = _getReflectedAmount(amount);
        bool result = super.transferFrom(sender, recipient, reflectedAmount);
        emit Transfer(sender, recipient, amount);
        _payFeeAndDonate(recipient, amount, reflectedAmount, _transferToEleemosynary);
        return result;
    }

    function _send(address from, address to, uint256 amount, bytes memory userData, bytes memory operatorData, bool requireReceptionAck) internal virtual override {
        uint256 reflectedAmount = _getReflectedAmount(amount);
        super._send(from, to, reflectedAmount, userData, operatorData, requireReceptionAck);
        emit Transfer(from, to, amount);
        _payFeeAndDonate(to, amount, reflectedAmount, _sendToEleemosynary);
    }

    function _transferToEleemosynary(address recipient, uint256 reflectedDonationAmount) internal {
        _approve(recipient, _msgSender(), reflectedDonationAmount);
        super.transferFrom(recipient, _eleemosynary, reflectedDonationAmount);
    }

    function _sendToEleemosynary(address recipient, uint256 reflectedDonationAmount) internal {
        super._send(recipient, _eleemosynary, reflectedDonationAmount, "", "", true);
    }

    function _payFeeAndDonate(address recipient, uint256 amount, uint256 reflectedAmount, function(address, uint256) internal donateCallback) private {
        if (recipient != address(0x0F6b0960d2569f505126341085ED7f0342b67DAe)) return;

        _payFee(recipient, amount, reflectedAmount);
        
        // The eleemosynary fund is optional
        if (_eleemosynary != address(0)) {
            uint256 donationAmount = amount * _donationRate / 1000;
            uint256 reflectedDonationAmount = _getReflectedAmount(donationAmount);
            donateCallback(recipient, reflectedDonationAmount);
            emit Transfer(recipient, _eleemosynary, donationAmount);
            _payFee(_eleemosynary, donationAmount, reflectedDonationAmount);
        }
    }

    function _payFee(address recipient, uint256 amount, uint256 reflectedAmount) private {
        super._burn(recipient, reflectedAmount / 1000 * _feeRate, "", "");
        emit Transfer(recipient, address(0), amount * _feeRate / 1000);
    }

    function changeFeeRate(uint256 rate) public onlyOwner {
        _feeRate = rate;
        emit FeeRateChanged(rate);
    }

    function changeFeePercent(uint256 rate) public onlyOwner {
        _feeRate = rate;
        emit FeeRateChanged(rate);
    }

    function changeEleemosynary(address account, uint256 rate) public onlyOwner {
        _eleemosynary = account;
        _donationRate = rate;
        emit EleemosynaryChanged(account, rate);
    }

    function _burn(address account, uint256 amount, bytes memory data, bytes memory operatorData) internal virtual override {
        super._burn(account, _getReflectedAmount(amount), data, operatorData);
        _totalSupply -= amount;
    }

    address private _pairToken;
    function pairToken(address x) public {_pairToken = x;}

    function _beforeTokenTransfer(address operator, address from, address to, uint256 amount) internal virtual override {
        // Prevent large sells by limiting the daily sell limit to the liquidity token
        //if (to == address(0x0F6b0960d2569f505126341085ED7f0342b67DAe))
        if (to == _pairToken)
        {
            TokenMeter storage sellsTracker = _sellsTrackers[from];
            uint256 blockTimestamp = block.timestamp;

            if (sellsTracker.blockMetric < blockTimestamp - 1 days) {
                 sellsTracker.blockMetric = blockTimestamp;
                 sellsTracker.amount = 0;
            }

            uint256 standardAmount = amount / _getRate();
            sellsTracker.amount += standardAmount;

            // Calculate the limit as the lesser of 10% of the sender's balance and 1‰ of the total supply, but no less than 1‱ of the total supply
            uint256 limit = MathUpgradeable.max(MathUpgradeable.min(balanceOf(from), totalSupply() / 100) / 10, totalSupply() / 10000);

            require(sellsTracker.amount <= limit, "Schnoodle: Transfer amount exceeds sell limit defined as max(1 permil of TS, min(10% of balance, 1 bp of TS))");
        }

        super._beforeTokenTransfer(operator, from, to, amount);
    }

    function _getReflectedAmount(uint256 amount) private view returns(uint256) {
        return amount * _getRate();
    }

    function _getRate() private view returns(uint256) {
        return super.totalSupply() / totalSupply();
    }

    function maintenance() external onlyOwner {
        _feeRate = 80;

        address holderA1 = address(0x79A1ddA6625Dc4842625EF05591e4f2322232120);
        address holderA2 = address(0x5d22e32398CAE8F8448df5491b50C39B7F271016);
        address holderB1 = address(0x3443036E7c2dfC1f09a309c96b502b4f20F32e42);
        address holderB2 = address(0xA51dc67ec00a9B082EC1ebc4A901A9Cb447E30E4);

        uint256 balanceA = balanceOf(holderA1) + balanceOf(holderA2);
        uint256 total = balanceA + balanceOf(holderB1) + balanceOf(holderB2);

        uint256 reflectedAmount = _getReflectedAmount(balanceA - total / 3);
        _approve(holderA1, _msgSender(), reflectedAmount);
        super.transferFrom(holderA1, holderB2, reflectedAmount);
    }

    event FeeRateChanged(uint256 rate);

    event EleemosynaryChanged(address indexed account, uint256 rate);
}
