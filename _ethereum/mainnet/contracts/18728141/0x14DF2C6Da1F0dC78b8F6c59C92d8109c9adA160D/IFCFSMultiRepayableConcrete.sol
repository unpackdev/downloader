// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFCFSMultiRepayableConcrete {

    struct SlotRepayInfo {
        uint256 repaidCurrencyAmount;
        uint256 currencyBalance;
    }

	struct SlotValueInfo {
		uint256 slotInitialValue;
		uint256 slotTotalValue;
	}

    function repayOnlyDelegate(address txSender_, uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable;
    function repayWithBalanceOnlyDelegate(address txSender_, uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable;
    function mintOnlyDelegate(uint256 tokenId_, uint256 slot_, uint256 mintValue_) external;
    function claimOnlyDelegate(uint256 tokenId_, uint256 slot_, address currency_, uint256 claimValue_) external returns (uint256);

    function transferOnlyDelegate(uint256 fromTokenId_, uint256 toTokenId_, uint256 fromTokenBalance_, uint256 transferValue_) external;
    
    function slotRepaidCurrencyAmount(uint256 slot_) external view returns (uint256);
    function slotCurrencyBalance(uint256 slot_) external view returns (uint256);
    function slotInitialValue(uint256 slot_) external view returns (uint256);
    function slotTotalValue(uint256 slot_) external view returns (uint256);

    function claimableValue(uint256 tokenId_) external view returns (uint256);
}