// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IProductMint {
    error InvalidInvoker();
    error RedeemingTooMany(uint256 amount);

    event NftAddressSet(address nftAddress);
    event ShopAddressSet(address shopAddress);
    event TokenUrisSet(uint256[] tokenIds, string[] tokenUris);
    event MaxRedeemablePerTxnSet(uint256 maxRedeemablePerTxn);
    event NftMint(
        address nftAddress,
        address to,
        uint256[] ids,
        uint256[] amounts,
        uint256 transactionId
    );
}
