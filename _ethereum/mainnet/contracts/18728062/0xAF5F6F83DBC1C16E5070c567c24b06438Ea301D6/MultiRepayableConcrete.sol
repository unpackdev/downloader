// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Constants.sol";
import "./ERC3525Upgradeable.sol";
import "./BaseSFTConcreteUpgradeable.sol";
import "./ERC20.sol";
import "./IMultiRepayableConcrete.sol";

abstract contract MultiRepayableConcrete is IMultiRepayableConcrete, BaseSFTConcreteUpgradeable {

    mapping(uint256 => SlotRepayInfo) internal _slotRepayInfo;
    mapping(uint256 => TokenRepayInfo) internal _tokenRepayInfo;

    // currency address => the portion of balance that has been allocated to any slots
    mapping(address => uint256) public allocatedCurrencyBalance;

    uint32 internal constant REPAY_RATE_SCALAR = 1e8;

    function repayOnlyDelegate(address txSender_, uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable virtual override onlyDelegate {
        _beforeRepay(txSender_, slot_, currency_, repayCurrencyAmount_);
        _slotRepayInfo[slot_].repaidCurrencyAmount += repayCurrencyAmount_;
        allocatedCurrencyBalance[currency_] += repayCurrencyAmount_;
    }

    function repayWithBalanceOnlyDelegate(address txSender_, uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable virtual override onlyDelegate {
        _beforeRepayWithBalance(txSender_, slot_, currency_, repayCurrencyAmount_);
        uint256 balance = ERC20(currency_).balanceOf(delegate());
        require(repayCurrencyAmount_ <= balance - allocatedCurrencyBalance[currency_], "MultiRepayableConcrete: insufficient unallocated balance");
        _slotRepayInfo[slot_].repaidCurrencyAmount += repayCurrencyAmount_;
        allocatedCurrencyBalance[currency_] += repayCurrencyAmount_;
    }

    function mintOnlyDelegate(uint256 tokenId_, uint256 slot_, uint256 mintValue_) external virtual override onlyDelegate {
        _beforeMint(tokenId_, slot_, mintValue_);
        _slotRepayInfo[slot_].initialValue += mintValue_;
        _slotRepayInfo[slot_].totalValue += mintValue_;
        _tokenRepayInfo[tokenId_].initialValue += mintValue_;
    }

    function claimOnlyDelegate(uint256 tokenId_, uint256 slot_, address currency_, uint256 claimValue_) external virtual override onlyDelegate returns (uint256 claimCurrencyAmount_) {
        _beforeClaim(tokenId_, slot_, currency_, claimValue_);
        _slotRepayInfo[slot_].totalValue -= claimValue_;

        uint8 valueDecimals = ERC3525Upgradeable(delegate()).valueDecimals();
        uint8 currencyDecimals = ERC20(_currency(slot_)).decimals();
        claimCurrencyAmount_ = claimValue_ * _repayRate(slot_) * (10 ** currencyDecimals) / Constants.FULL_PERCENTAGE / REPAY_RATE_SCALAR / (10 ** valueDecimals);
        allocatedCurrencyBalance[currency_] -= claimCurrencyAmount_;
    }

    function transferOnlyDelegate(uint256 fromTokenId_, uint256 toTokenId_, uint256 fromTokenBalance_, uint256 transferValue_) external virtual override onlyDelegate {
        _beforeTransfer(fromTokenId_, toTokenId_, fromTokenBalance_, transferValue_);
        uint256 transferInitialValue = transferValue_ * _tokenRepayInfo[fromTokenId_].initialValue / fromTokenBalance_;
        _tokenRepayInfo[fromTokenId_].initialValue -= transferInitialValue;
        _tokenRepayInfo[toTokenId_].initialValue += transferInitialValue;
    }

    function slotInitialValue(uint256 slot_) public view returns (uint256) {
        return _slotRepayInfo[slot_].initialValue;
    }
    
    function slotTotalValue(uint256 slot_) public view virtual override returns (uint256) {
        return _slotRepayInfo[slot_].totalValue;
    }

    function repaidCurrencyAmount(uint256 slot_) public view virtual override returns (uint256) {
        return _slotRepayInfo[slot_].repaidCurrencyAmount;
    }

    function tokenInitialValue(uint256 tokenId_) public view virtual override returns (uint256) {
        return _tokenRepayInfo[tokenId_].initialValue;
    }

    function claimableValue(uint256 tokenId_) public view virtual override returns (uint256) {
        uint256 slot = ERC3525Upgradeable(delegate()).slotOf(tokenId_);
        uint256 balance = ERC3525Upgradeable(delegate()).balanceOf(tokenId_);
        uint8 valueDecimals = ERC3525Upgradeable(delegate()).valueDecimals();
        uint8 currencyDecimals = ERC20(_currency(slot)).decimals();
        uint256 initialValueOfSlot = _slotRepayInfo[slot].initialValue;
        uint256 initialValueOfToken = tokenInitialValue(tokenId_);

        uint256 slotDueAmount = initialValueOfSlot * _repayRate(slot) * (10 ** currencyDecimals) / Constants.FULL_PERCENTAGE / REPAY_RATE_SCALAR / (10 ** valueDecimals);
        uint256 slotRepaidAmount = repaidCurrencyAmount(slot);
        uint256 tokenTotalClaimableValue = slotRepaidAmount >= slotDueAmount ? initialValueOfToken : initialValueOfToken * slotRepaidAmount / slotDueAmount;

        uint256 tokenClaimedBalance = initialValueOfToken - balance;
        return tokenTotalClaimableValue > tokenClaimedBalance ? tokenTotalClaimableValue - tokenClaimedBalance : 0;
    }

    function _currency(uint256 slot_) internal view virtual returns (address);
    function _repayRate(uint256 slot_) internal view virtual returns (uint256);

    function _beforeRepay(address /** txSender_ */, uint256 slot_, address currency_, uint256 /** repayCurrencyAmount_ */) internal virtual {
        require(currency_ == _currency(slot_), "MultiRepayableConcrete: invalid currency");
    }

    function _beforeRepayWithBalance(address /** txSender_ */, uint256 slot_, address currency_, uint256 /** repayCurrencyAmount_ */) internal virtual {
        require(currency_ == _currency(slot_), "MultiRepayableConcrete: invalid currency");
    }

    function _beforeMint(uint256 /** tokenId_ */, uint256 slot_, uint256 mintValue_) internal virtual {
        // skip repayment check when minting in the process of transferring from id to address
        if (mintValue_ > 0) {
            require(repaidCurrencyAmount(slot_) == 0, "MultiRepayableConcrete: already repaid");
        }
    }

    function _beforeClaim(uint256 /** tokenId_ */, uint256 slot_, address currency_, uint256 /** claimValue_ */) internal virtual {
        require(currency_ == _currency(slot_), "MultiRepayableConcrete: invalid currency");
    }

    function _beforeTransfer(uint256 fromTokenId_, uint256 toTokenId_, uint256 fromTokenBalance_, uint256 transferValue_) internal virtual {}

    uint256[47] private __gap;
}