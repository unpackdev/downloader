pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./Token.sol";
import "./TokenId.sol";
import "./Stake.sol";

address constant ETHEREUM = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

contract Redeem is Ownable {
    struct NFTRedeemDetails {
        uint256 redeemFee;
    }

    // Power map for each series - { collectionId: { seriesId: power }}.
    mapping(IERC721 => mapping(uint256 => mapping(uint256 => NFTRedeemDetails)))
        public nftRedeemDetails;

    // Record the owner of each token ID.
    mapping(IERC721 => mapping(uint256 => bool)) public nftRedeemed;

    IERC20 public feeCurrency;
    Stake public lock;

    constructor(Stake lock_, IERC20 feeCurrency_) Ownable() {
        lock = lock_;
        feeCurrency = feeCurrency_;
    }

    function getNFTRedeemDetails(
        IERC721 nft,
        uint256 collectionId,
        uint256 seriesId
    ) public view returns (NFTRedeemDetails memory) {
        return nftRedeemDetails[nft][collectionId][seriesId];
    }

    // EVENTS //////////////////////////////////////////////////////////////////

    event NFTRedeemed(
        IERC721 indexed nft,
        uint256 indexed tokenId,
        bytes32 formHash
    );

    // PERMISSIONED METHODS ////////////////////////////////////////////////////

    function setLock(Stake lock_) public onlyOwner {
        lock = lock_;
    }

    function setPaymentCurrency(IERC20 feeCurrency_) public onlyOwner {
        feeCurrency = feeCurrency_;
    }

    function addNFTRedeemDetails(
        IERC721 nft,
        uint256 collectionId,
        uint256[] memory seriesIds,
        uint256[] memory fees
    ) public onlyOwner {
        for (uint256 i = 0; i < seriesIds.length; i++) {
            nftRedeemDetails[nft][collectionId][
                seriesIds[i]
            ] = NFTRedeemDetails({redeemFee: fees[i]});
        }
    }

    // USER METHODS ////////////////////////////////////////////////////////////

    // Only callable by the owner of the NFTs.
    function redeemNFTs(
        IERC721 nft,
        uint256[] memory tokenIds,
        bytes32 formHash
    ) public {
        uint256 summedRedeemShippingFee = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                lock.nftStatus(nft, tokenId) != NFTStatus.Lockable,
                "NEVER_LOCKED"
            );
            require(!nftRedeemed[nft][tokenId], "ALREADY_REDEEMED");
            require(lock.nftOwner(nft, tokenId) == msg.sender, "NOT_NFT_OWNER");
            nftRedeemed[nft][tokenId] = true;

            uint256 collectionId = TokenIdLib.extractCollectionId(tokenId);
            uint256 seriesId = TokenIdLib.extractSeriesId(tokenId);

            summedRedeemShippingFee += nftRedeemDetails[nft][collectionId][
                seriesId
            ]
                .redeemFee;

            emit NFTRedeemed(nft, tokenId, formHash);
        }

        takePayment(address(feeCurrency), summedRedeemShippingFee);
    }

    function takePayment(address token, uint256 amount) internal {
        if (token == ETHEREUM) {
            require(msg.value >= amount, "INSUFFICIENT_ETH_AMOUNT");
            // Refund change.
            payable(msg.sender).transfer(msg.value - amount);
        } else {
            IERC20(token).transferFrom(msg.sender, address(this), amount);
        }
    }

    function withdraw(address token) public onlyOwner {
        if (token == ETHEREUM) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20(token).transfer(
                msg.sender,
                IERC20(token).balanceOf(address(this))
            );
        }
    }

    // USER METHODS - MULTIPLE NFT CONTRACTS ///////////////////////////////////

    function redeemMultipleNFTs(
        IERC721[] memory nftArray,
        uint256[][] memory tokenIdsArray,
        bytes32 formHash
    ) public {
        require(nftArray.length == tokenIdsArray.length, "MISMATCHED_LENGTHS");
        for (uint256 i = 0; i < nftArray.length; i++) {
            redeemNFTs(nftArray[i], tokenIdsArray[i], formHash);
        }
    }
}
