// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SFTIssuableDelegate.sol";
import "./MultiRepayableDelegate.sol";
import "./IEarnConcrete.sol";

contract EarnDelegate is SFTIssuableDelegate, MultiRepayableDelegate {

    event SetCurrency(address indexed currency, bool isAllowed);
    event SetInterestRate(uint256 indexed slot, int32 interestRate);

    bool private __allowRepayWithBalance;

	function initialize(
        address resolver_, string calldata name_, string calldata symbol_, uint8 decimals_, 
		address concrete_, address descriptor_, address owner_, bool allowRepayWithBalance_
    ) external initializer {
		__SFTIssuableDelegate_init(resolver_, name_, symbol_, decimals_, concrete_, descriptor_, owner_);
        __allowRepayWithBalance = allowRepayWithBalance_;
	}

	function _beforeValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual override(ERC3525SlotEnumerableUpgradeable, MultiRepayableDelegate) {
        MultiRepayableDelegate._beforeValueTransfer(from_, to_, fromTokenId_, toTokenId_, slot_, value_);

        // untransferable
        if (from_ != address(0) && to_ != address(0)) {
            require(IEarnConcrete(concrete()).isSlotTransferable(slot_), "untransferable");
        }
    }

    function setCurrencyOnlyOwner(address currency_, bool isAllowed_) external onlyOwner {
        IEarnConcrete(concrete()).setCurrencyOnlyDelegate(currency_, isAllowed_);
        emit SetCurrency(currency_, isAllowed_);
    }

    function setInterestRateOnlySupervisor(uint256 slot_, int32 interestRate_) external {
        IEarnConcrete(concrete()).setInterestRateOnlyDelegate(_msgSender(), slot_, interestRate_);
        emit SetInterestRate(slot_, interestRate_);
    }

    function allowRepayWithBalance() public view virtual override returns (bool) {
        return __allowRepayWithBalance;
    }

    function contractType() external view virtual override returns (string memory) {
        return "Closed-end Fund";
    }
}