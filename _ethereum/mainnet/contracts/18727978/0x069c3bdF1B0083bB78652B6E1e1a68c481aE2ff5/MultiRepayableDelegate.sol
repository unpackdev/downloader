// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BaseSFTDelegateUpgradeable.sol";
import "./ERC20TransferHelper.sol";
import "./IMultiRepayableDelegate.sol";
import "./IMultiRepayableConcrete.sol";

abstract contract MultiRepayableDelegate is IMultiRepayableDelegate, BaseSFTDelegateUpgradeable {

    function repay(uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable virtual override nonReentrant {
        IMultiRepayableConcrete(concrete()).repayOnlyDelegate(_msgSender(), slot_, currency_, repayCurrencyAmount_);
        ERC20TransferHelper.doTransferIn(currency_, _msgSender(), repayCurrencyAmount_);
        emit Repay(slot_, _msgSender(), repayCurrencyAmount_);
    }

    function repayWithBalance(uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable virtual override nonReentrant {
        require(allowRepayWithBalance(), "MultiRepayableDelegate: cannot repay with balance");
        IMultiRepayableConcrete(concrete()).repayWithBalanceOnlyDelegate(_msgSender(), slot_, currency_, repayCurrencyAmount_);
        emit Repay(slot_, _msgSender(), repayCurrencyAmount_);
    }

    function claimTo(address to_, uint256 tokenId_, address currency_, uint256 claimValue_) external virtual override nonReentrant {
        require(claimValue_ > 0, "MultiRepayableDelegate: claim value is zero");
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "MultiRepayableDelegate: caller is not owner nor approved");
        uint256 slot = ERC3525Upgradeable.slotOf(tokenId_);
        uint256 claimableValue = IMultiRepayableConcrete(concrete()).claimableValue(tokenId_);
        require(claimValue_ <= claimableValue, "MultiRepayableDelegate: over claim");
        
        if (claimValue_ == ERC3525Upgradeable.balanceOf(tokenId_)) {
            ERC3525Upgradeable._burn(tokenId_);
        } else {
            ERC3525Upgradeable._burnValue(tokenId_, claimValue_);
        }
        
        uint256 claimCurrencyAmount = IMultiRepayableConcrete(concrete()).claimOnlyDelegate(tokenId_, slot, currency_, claimValue_);
        ERC20TransferHelper.doTransferOut(currency_, payable(to_), claimCurrencyAmount);
        emit Claim(to_, tokenId_, claimValue_);
    }

    function _beforeValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual override(ERC3525SlotEnumerableUpgradeable) {
        super._beforeValueTransfer(from_, to_, fromTokenId_, toTokenId_, slot_, value_);

        if (from_ == address(0) && fromTokenId_ == 0) {
            IMultiRepayableConcrete(concrete()).mintOnlyDelegate(toTokenId_, slot_, value_);
        } 
        
		if (from_ != address(0) && fromTokenId_ != 0 && to_ != address(0) && toTokenId_ != 0) { 
            IMultiRepayableConcrete(concrete()).transferOnlyDelegate(fromTokenId_, toTokenId_, 
                ERC3525Upgradeable.balanceOf(fromTokenId_), value_);
		}
    }

    function allowRepayWithBalance() public view virtual returns (bool) {
        return true;
    }

    uint256[50] private __gap;
}