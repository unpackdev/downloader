// contracts/Schnoodle.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC777PresetFixedSupplyUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract SchnoodleV1 is ERC777PresetFixedSupplyUpgradeable, OwnableUpgradeable {
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
        uint256 reflectedAmount = amount * _getRate();
        bool result = super.transfer(recipient, reflectedAmount);
        _payFeeAndDonate(recipient, reflectedAmount, amount);
        return result;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 reflectedAmount = amount * _getRate();
        bool result = super.transferFrom(sender, recipient, reflectedAmount);
        _payFeeAndDonate(recipient, reflectedAmount, amount);
        return result;
    }

    function _payFeeAndDonate(address recipient, uint256 reflectedAmount, uint256 amount) private {
        _payFee(recipient, reflectedAmount);
        
        // The eleemosynary fund is optional
        if (_eleemosynary != address(0)) {
            uint256 donationAmount = amount * _getRate() / 100 * _donationPercent;
            _send(recipient, _eleemosynary, donationAmount, "", "", true);
            _payFee(_eleemosynary, donationAmount);
        }
    }

    function _payFee(address recipient, uint256 reflectedAmount) private {
        super._burn(recipient, reflectedAmount / 100 * _feePercent, "", "");
    }

    function _getRate() private view returns(uint256) {
        return super.totalSupply() / totalSupply();
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
        super._burn(account, amount * _getRate(), data, operatorData);
        _totalSupply -= amount;
    }

    event FeePercentChanged(uint256 percent);

    event EleemosynaryChanged(address indexed account, uint256 percent);
}
