pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721.sol";
import "./NFT.sol";
import "./Token.sol";
import "./Buy.sol";
import "./Stake.sol";
import "./Redeem.sol";
import "./TokenId.sol";

interface Moonwalk is IERC721 {
    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory);

    function seriesMinted(uint256 seriesId) external view returns (uint256);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface MoonwalkBuy {
    function nft() external view returns (Moonwalk);

    function seriesMinted() external view returns (uint256[] memory);
}

contract ContractState {
    struct NFTState {
        uint256 tokenId;
        NFTStatus status;
        bool redeemed;
        uint256 unlockTimestamp;
        uint256 claimed;
        uint256 claimable;
    }

    function statusOfNFTs(
        Stake stake,
        Redeem redeem,
        IERC721 nft,
        uint256[] memory tokenIds
    ) internal view returns (NFTState[] memory) {
        NFTState[] memory states = new NFTState[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            states[i] = NFTState({
                tokenId: tokenId,
                status: stake.nftStatus(nft, tokenId),
                redeemed: redeem.nftRedeemed(nft, tokenId),
                unlockTimestamp: stake
                    .getNFTStakeDetails(
                    nft,
                    TokenIdLib.extractCollectionId(tokenId),
                    TokenIdLib.extractSeriesId(tokenId)
                )
                    .lockPeriod + stake.nftLockTimestamp(nft, tokenId),
                claimed: 0,
                claimable: 0
            });
        }

        return states;
    }

    function statusOfUnlockedNFTs(
        Stake stake,
        Redeem redeem,
        NFT nft,
        address owner
    ) public view returns (NFTState[] memory) {
        (uint256[] memory tokenIds, ) = nft.tokensOfOwner(owner);
        return statusOfNFTs(stake, redeem, nft, tokenIds);
    }

    function statusOfUnlockedNFTsV0(
        Stake stake,
        Redeem redeem,
        Moonwalk nft,
        address owner
    ) public view returns (NFTState[] memory) {
        uint256[] memory tokenIds = nft.tokensOfOwner(owner);
        return statusOfNFTs(stake, redeem, nft, tokenIds);
    }

    function statusOfLockedNFTs(
        Stake stake,
        Redeem redeem,
        NFT nft,
        address owner
    ) public view returns (NFTState[] memory) {
        uint256[] memory tokenIds = stake.getOwnerNFTs(nft, owner);

        NFTState[] memory stats = new NFTState[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            stats[i] = NFTState({
                status: stake.nftStatus(nft, tokenIds[i]),
                redeemed: redeem.nftRedeemed(nft, tokenIds[i]),
                unlockTimestamp: stake
                    .getNFTStakeDetails(
                    nft,
                    TokenIdLib.extractCollectionId(tokenIds[i]),
                    TokenIdLib.extractSeriesId(tokenIds[i])
                )
                    .lockPeriod + stake.nftLockTimestamp(nft, tokenIds[i]),
                claimed: stake.nftTokensClaimed(nft, tokenIds[i]),
                claimable: stake.claimableTokens(nft, tokenIds[i]),
                tokenId: tokenIds[i]
            });
        }

        return stats;
    }

    struct SeriesWithRelic {
        uint256 id;
        uint256 limit;
        uint256 minted;
        uint256 initialPrice;
        int256 priceChange;
        // Only set in `getCollections`.
        uint256 currentPrice;
        uint256 nextPrice;
        // Relic info
        uint256 power;
        uint256 lockPeriod;
        uint256 redeemFee;
    }

    struct CollectionFlatWithRelic {
        uint256 id;
        string title;
        string uriBase;
        uint256 priceChangeTime;
        uint256 initialTimestamp;
        address paymentToken;
        SeriesWithRelic[] series;
    }

    function getCollections(
        Buy buy,
        Stake stake,
        Redeem redeem
    ) public view returns (CollectionFlatWithRelic[] memory) {
        CollectionFlat[] memory collections = buy.getCollections();
        CollectionFlatWithRelic[] memory collectionsWithRelic =
            new CollectionFlatWithRelic[](collections.length);

        NFT nft = buy.nft();

        for (uint256 i = 0; i < collections.length; i++) {
            CollectionFlat memory collection = collections[i];
            SeriesWithRelic[] memory series =
                new SeriesWithRelic[](collection.series.length);
            for (uint256 j = 0; j < series.length; j++) {
                series[j] = SeriesWithRelic({
                    id: collection.series[j].id,
                    limit: collection.series[j].limit,
                    minted: collection.series[j].minted,
                    initialPrice: collection.series[j].initialPrice,
                    priceChange: collection.series[j].priceChange,
                    currentPrice: collection.series[j].currentPrice,
                    nextPrice: collection.series[j].nextPrice,
                    power: stake
                        .getNFTStakeDetails(
                        nft,
                        collection
                            .id,
                        collection.series[j]
                            .id
                    )
                        .power,
                    lockPeriod: stake
                        .getNFTStakeDetails(
                        nft,
                        collection
                            .id,
                        collection.series[j]
                            .id
                    )
                        .lockPeriod,
                    redeemFee: redeem
                        .getNFTRedeemDetails(
                        nft,
                        collection
                            .id,
                        collection.series[j]
                            .id
                    )
                        .redeemFee
                });
            }
            collectionsWithRelic[i] = CollectionFlatWithRelic({
                id: collection.id,
                series: series,
                title: collection.title,
                uriBase: collection.uriBase,
                priceChangeTime: collection.priceChangeTime,
                initialTimestamp: collection.initialTimestamp,
                paymentToken: collection.paymentToken
            });
        }

        return collectionsWithRelic;
    }

    struct SeriesRelicInfo {
        uint256 id;
        uint256 power;
        // uint256 minted;
        uint256 lockPeriod;
        uint256 redeemFee;
    }

    struct CollectionRelicInfo {
        uint256 id;
        SeriesRelicInfo[] series;
    }

    function getMoonwalkRelicInfo(
        MoonwalkBuy moonwalkBuy,
        Stake stake,
        Redeem redeem
    ) public view returns (CollectionRelicInfo memory) {
        Moonwalk nft = moonwalkBuy.nft();

        // uint256[] memory minted = redeem.seriesMinted();
        // uint256[3] memory minted =
        //     [nft.seriesMinted(0), nft.seriesMinted(1), nft.seriesMinted(2)];

        SeriesRelicInfo[] memory series = new SeriesRelicInfo[](3);

        uint256 collectionId = 0;

        for (uint256 seriesId = 0; seriesId < series.length; seriesId++) {
            series[seriesId] = SeriesRelicInfo({
                id: seriesId, // minted: minted[seriesId],
                power: stake
                    .getNFTStakeDetails(nft, collectionId, seriesId)
                    .power,
                lockPeriod: stake
                    .getNFTStakeDetails(nft, collectionId, seriesId)
                    .lockPeriod,
                redeemFee: redeem
                    .getNFTRedeemDetails(nft, collectionId, seriesId)
                    .redeemFee
            });
        }
        return CollectionRelicInfo({id: collectionId, series: series});
    }
}
