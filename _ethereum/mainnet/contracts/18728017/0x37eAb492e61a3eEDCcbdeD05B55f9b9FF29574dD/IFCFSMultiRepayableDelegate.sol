// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFCFSMultiRepayableDelegate {
    event Repay(uint256 indexed slot, address indexed payer, address currency, uint256 repayCurrencyAmount);
    event Claim(address indexed to, uint256 indexed tokenId, uint256 claimValue, address currency, uint256 claimCurrencyAmount);

    function repay(uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable;
    function repayWithBalance(uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable;
    function claimTo(address to_, uint256 tokenId_, address currency_, uint256 claimValue_) external;
}