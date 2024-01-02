// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Constants.sol";
import "./ERC3525Upgradeable.sol";
import "./BaseSFTConcreteUpgradeable.sol";
import "./ERC20.sol";
import "./IFCFSMultiRepayableConcrete.sol";

abstract contract FCFSMultiRepayableConcrete is IFCFSMultiRepayableConcrete, BaseSFTConcreteUpgradeable {

    mapping(uint256 => SlotRepayInfo) internal _slotRepayInfo;

    mapping(address => uint256) public allocatedCurrencyBalance;

    uint32 internal constant REPAY_RATE_SCALAR = 1e8;

    mapping(uint256 => SlotValueInfo) internal _slotValueInfo;

    function repayOnlyDelegate(address txSender_, uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable virtual override onlyDelegate {
        _beforeRepay(txSender_, slot_, currency_, repayCurrencyAmount_);
        _slotRepayInfo[slot_].repaidCurrencyAmount += repayCurrencyAmount_;
        _slotRepayInfo[slot_].currencyBalance += repayCurrencyAmount_;
        allocatedCurrencyBalance[currency_] += repayCurrencyAmount_;
    }

    function repayWithBalanceOnlyDelegate(address txSender_, uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable virtual override onlyDelegate {
        _beforeRepayWithBalance(txSender_, slot_, currency_, repayCurrencyAmount_);
        uint256 balance = ERC20(currency_).balanceOf(delegate());
        require(repayCurrencyAmount_ <= balance - allocatedCurrencyBalance[currency_], "MultiRepayableConcrete: insufficient unallocated balance");
        _slotRepayInfo[slot_].repaidCurrencyAmount += repayCurrencyAmount_;
        _slotRepayInfo[slot_].currencyBalance += repayCurrencyAmount_;
        allocatedCurrencyBalance[currency_] += repayCurrencyAmount_;
    }

    function mintOnlyDelegate(uint256 /** tokenId_ */, uint256 slot_, uint256 mintValue_) external virtual override onlyDelegate {
        _slotValueInfo[slot_].slotInitialValue += mintValue_;
        _slotValueInfo[slot_].slotTotalValue += mintValue_;
    }

    function claimOnlyDelegate(uint256 tokenId_, uint256 slot_, address currency_, uint256 claimValue_) external virtual override onlyDelegate returns (uint256 claimCurrencyAmount_) {
        _beforeClaim(tokenId_, slot_, currency_, claimValue_);
        require(claimValue_ <= claimableValue(tokenId_), "MR: insufficient claimable value");
        _slotValueInfo[slot_].slotTotalValue -= claimValue_;

        uint8 valueDecimals = ERC3525Upgradeable(delegate()).valueDecimals();
        claimCurrencyAmount_ = claimValue_ * _repayRate(slot_) / (10 ** valueDecimals);
        require(claimCurrencyAmount_ <= _slotRepayInfo[slot_].currencyBalance, "MR: insufficient repaid currency amount");
        allocatedCurrencyBalance[currency_] -= claimCurrencyAmount_;
        _slotRepayInfo[slot_].currencyBalance -= claimCurrencyAmount_;
    }

    function transferOnlyDelegate(uint256 fromTokenId_, uint256 toTokenId_, uint256 fromTokenBalance_, uint256 transferValue_) external virtual override onlyDelegate {
        _beforeTransfer(fromTokenId_, toTokenId_, fromTokenBalance_, transferValue_);
    }

    function claimableValue(uint256 tokenId_) public view virtual override returns (uint256) {
        uint256 slot = ERC3525Upgradeable(delegate()).slotOf(tokenId_);
        uint256 balance = ERC3525Upgradeable(delegate()).balanceOf(tokenId_);
        uint8 valueDecimals = ERC3525Upgradeable(delegate()).valueDecimals();
        uint256 dueAmount = balance *  _repayRate(slot) / (10 ** valueDecimals);
        return dueAmount < _slotRepayInfo[slot].currencyBalance ? balance : 
                _slotRepayInfo[slot].currencyBalance * (10 ** valueDecimals) / _repayRate(slot);
    }

    function slotRepaidCurrencyAmount(uint256 slot_) public view virtual override returns (uint256) {
        return _slotRepayInfo[slot_].repaidCurrencyAmount;
    }

    function slotCurrencyBalance(uint256 slot_) public view virtual override returns (uint256) {
        return _slotRepayInfo[slot_].currencyBalance;
    }

    function slotInitialValue(uint256 slot_) public view virtual override returns (uint256) {
        return _slotValueInfo[slot_].slotInitialValue;
    }

    function slotTotalValue(uint256 slot_) public view virtual override returns (uint256) {
        return _slotValueInfo[slot_].slotTotalValue;
    }

    function _currency(uint256 slot_) internal view virtual returns (address);
    function _repayRate(uint256 slot_) internal view virtual returns (uint256);

    function _beforeRepay(address /** txSender_ */, uint256 slot_, address currency_, uint256 /** repayCurrencyAmount_ */) internal virtual {
        require(currency_ == _currency(slot_), "FMR: invalid currency");
    }

    function _beforeRepayWithBalance(address /** txSender_ */, uint256 slot_, address currency_, uint256 /** repayCurrencyAmount_ */) internal virtual {
        require(currency_ == _currency(slot_), "FMR: invalid currency");
    }

    function _beforeClaim(uint256 /** tokenId_ */, uint256 slot_, address currency_, uint256 /** claimValue_ */) internal virtual {
        require(currency_ == _currency(slot_), "FMR: invalid currency");
    }

    function _beforeTransfer(uint256 fromTokenId_, uint256 toTokenId_, uint256 fromTokenBalance_, uint256 transferValue_) internal virtual {}

    uint256[46] private __gap;
}