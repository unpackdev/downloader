// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IXNFTLiquidityPool {
    function initialize(address xnftCloneAddress, uint256 _accountId) external;

    function claim(address requestor, uint256 tokenId) external payable;

    function accountTvl() external view returns (uint256);

    function redeem(address requestor, uint256 tokenId) external;

    function redeemPrice() external view returns (uint256);
}
