// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IProductNft {
    error InvalidInvoker();

    event NftPurchase(
        address nftAddress,
        address to,
        uint256[] ids,
        uint256[] amounts,
        uint256 transactionId
    );
}
