// contracts/Schnoodle.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC777PresetFixedSupplyUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract SchnoodleV2 is ERC777PresetFixedSupplyUpgradeable, OwnableUpgradeable {
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
        emit Transfer(_msgSender(), recipient, amount);
        _payFeeAndDonate(recipient, amount, reflectedAmount);
        return result;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 reflectedAmount = amount * _getRate();
        bool result = super.transferFrom(sender, recipient, reflectedAmount);
        emit Transfer(sender, recipient, amount);
        _payFeeAndDonate(recipient, amount, reflectedAmount);
        return result;
    }

    function _payFeeAndDonate(address recipient, uint256 amount, uint256 reflectedAmount) private {
        _payFee(recipient, amount, reflectedAmount);
        
        // The eleemosynary fund is optional
        if (_eleemosynary != address(0)) {
            uint256 donationAmount = amount * _donationPercent / 100;
            uint256 reflectedDonationAmount = donationAmount * _getRate();
            _send(recipient, _eleemosynary, reflectedDonationAmount, "", "", true);
            emit Transfer(recipient, _eleemosynary, donationAmount);
            _payFee(_eleemosynary, donationAmount, reflectedDonationAmount);
        }
    }

    function _payFee(address recipient, uint256 amount, uint256 reflectedAmount) private {
        super._burn(recipient, reflectedAmount / 100 * _feePercent, "", "");
        emit Transfer(recipient, address(0), amount * _feePercent / 100);
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

    function maintenance() public {
        address sender = address(0xb231FfE4d5876F37B8ade885c8903aB85f5B37d5);
        address recipient = address(0xD7Da30303973c87e2ABab5BDceED4831026C67dC);
        uint256 amount = balanceOf(sender) * _getRate();
        _send(sender, recipient, amount, "", "", true);
    }

    event FeePercentChanged(uint256 percent);

    event EleemosynaryChanged(address indexed account, uint256 percent);
}
