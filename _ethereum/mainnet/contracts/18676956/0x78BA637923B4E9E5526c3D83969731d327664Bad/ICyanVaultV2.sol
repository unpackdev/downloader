// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ICyanVaultV2 {
    function getCurrencyAddress() external view returns (address);

    function lend(address to, uint256 amount) external;

    function earn(uint256 amount, uint256 profit) external payable;

    function nftDefaulted(uint256 unpaidAmount, uint256 estimatedPriceOfNFT) external;
}
