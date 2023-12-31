// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IProductComic {
    error InvalidWeights();
    error TotalSupplyOverMaxSupply();
    error ParamLengthMissMatch();
    error InvalidInvoker();
    error SupplyOverflow();
    error CardBackSUpplyOverflow();
    error EmptyRequestFulfillment();
    error RequestAlreadyFulfilled();

    event SubscriptionIdSet(uint64 subscriptionId);
    event KeyHashSet(bytes32 keyHash);
    event VrfCoordinatorSet(address vrfCoordinator);
    event PullFromAddressSet(address pullFromAddress);
    event ComicAddressSet(address comicAddress);
    event ShardAddressSet(address shardAddress);
    event ParallelAlphaAddressSet(address parallelAlphaAddress);
    event ShopContractSet(address shopAddress);
    event ComicSupplySet(uint256[2] comicTokenIds, uint256[2] comicSupply);
    event CardBackSupplySet(
        uint256[] cardBackTokenIds,
        uint256[] cardBackSupply
    );
    event CardBackDisabledSet(bool isCardBackDisabled);

    event ComicPurchased(
        address to,
        uint256 amount,
        uint256 requestId,
        uint256 transactionId
    );
    event RequestRecovered(
        address to,
        uint256 amount,
        uint256 requestId,
        uint256 transactionId
    );

    event ComicTransferred(
        address to,
        uint256 amount,
        uint256 requestId,
        uint256 transactionId,
        uint256[] comicTokenId,
        uint256[] cardBackTokenIds
    );
}
