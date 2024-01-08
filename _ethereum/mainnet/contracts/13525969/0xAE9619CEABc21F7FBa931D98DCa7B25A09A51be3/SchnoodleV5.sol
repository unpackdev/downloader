// contracts/Schnoodle.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC777PresetFixedSupplyUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract SchnoodleV5 is ERC777PresetFixedSupplyUpgradeable, OwnableUpgradeable {
    uint256 private constant MAX = ~uint256(0);
    uint256 private _totalSupply;
    uint256 private _feePercent;
    address private _eleemosynary;
    uint256 private _donationPercent;

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
        _payFee(recipient, amount, reflectedAmount);
        
        // The eleemosynary fund is optional
        if (_eleemosynary != address(0)) {
            uint256 donationAmount = amount * _donationPercent / 100;
            uint256 reflectedDonationAmount = _getReflectedAmount(donationAmount);
            donateCallback(recipient, reflectedDonationAmount);
            emit Transfer(recipient, _eleemosynary, donationAmount);
            _payFee(_eleemosynary, donationAmount, reflectedDonationAmount);
        }
    }

    function _payFee(address recipient, uint256 amount, uint256 reflectedAmount) private {
        super._burn(recipient, reflectedAmount / 100 * _feePercent, "", "");
        emit Transfer(recipient, address(0), amount * _feePercent / 100);
    }

    function changeFeePercent(uint256 percent) public onlyOwner {
        _feePercent = percent;
        emit FeePercentChanged(percent);
    }

    function changeEleemosynary(address account, uint256 percent) public onlyOwner {
        _eleemosynary = account;
        _donationPercent = percent;
        emit EleemosynaryChanged(account, percent);
    }

    function _burn(address account, uint256 amount, bytes memory data, bytes memory operatorData) internal virtual override {
        super._burn(account, _getReflectedAmount(amount), data, operatorData);
        _totalSupply -= amount;
    }

    function _getReflectedAmount(uint256 amount) private view returns(uint256) {
        return amount * _getRate();
    }

    function _getRate() private view returns(uint256) {
        return super.totalSupply() / totalSupply();
    }

    event FeePercentChanged(uint256 percent);

    event EleemosynaryChanged(address indexed account, uint256 percent);
}
