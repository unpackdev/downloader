// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMultiRepayableConcrete {

    struct SlotRepayInfo {
        uint256 initialValue;
        uint256 totalValue;
        uint256 repaidCurrencyAmount;
    }

    struct TokenRepayInfo {
        uint256 initialValue;
    }

    function repayOnlyDelegate(address txSender_, uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable;
    function repayWithBalanceOnlyDelegate(address txSender_, uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable;
    function mintOnlyDelegate(uint256 tokenId_, uint256 slot_, uint256 mintValue_) external;
    function claimOnlyDelegate(uint256 tokenId_, uint256 slot_, address currency_, uint256 claimValue_) external returns (uint256);

    function transferOnlyDelegate(uint256 fromTokenId_, uint256 toTokenId_, uint256 fromTokenBalance_, uint256 transferValue_) external;
    
    function slotInitialValue(uint256 slot_) external view returns (uint256);
    function slotTotalValue(uint256 slot_) external view returns (uint256);
    function repaidCurrencyAmount(uint256 slot_) external view returns (uint256);

    function tokenInitialValue(uint256 tokenId_) external view returns (uint256);
    function claimableValue(uint256 tokenId_) external view returns (uint256);
}