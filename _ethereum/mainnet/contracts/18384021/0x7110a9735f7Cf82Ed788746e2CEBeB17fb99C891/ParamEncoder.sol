// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IFeeDistributor.sol";
import "./IRoyaltySplitter.sol";
import "./IPassClaim.sol";
import "./IIncinerator.sol";

library ParamEncoder {
    function encodeFees(IFeeDistributor.Fee[] calldata fees) internal pure returns (bytes memory encodedFees) {
        uint256 feeCount = fees.length;
        for (uint256 i = 0; i < feeCount; ) {
            IFeeDistributor.Fee calldata fee = fees[i];
            encodedFees = bytes.concat(encodedFees, abi.encode(fee.payee, fee.token, fee.amount));
            unchecked {
                i++;
            }
        }
    }

    function encodeRoyalty(
        IRoyaltySplitter.Royalty[] calldata royalties
    ) internal pure returns (bytes memory encodedRoyalties) {
        uint256 royaltyCount = royalties.length;
        for (uint256 i = 0; i < royaltyCount; ) {
            IRoyaltySplitter.Royalty calldata royalty = royalties[i];
            encodedRoyalties = bytes.concat(encodedRoyalties, abi.encode(royalty.payee, royalty.share));
            unchecked {
                i++;
            }
        }
    }

    function encodeNFTItems(
        IPassClaim.NFTItem[] calldata nftItems
    ) internal pure returns (bytes memory encodedNFTItems) {
        uint256 nftItemCount = nftItems.length;
        for (uint256 i = 0; i < nftItemCount; ) {
            IPassClaim.NFTItem calldata nftItem = nftItems[i];
            bytes.concat(
                encodedNFTItems,
                abi.encode(nftItem.collection, nftItem.tokenId, nftItem.deduplicationId, nftItem.maxUsage)
            );
            unchecked {
                i++;
            }
        }
    }

    function encodeNFTItems(
        IIncinerator.NFTItem[] calldata nftItems
    ) internal pure returns (bytes memory encodedNFTItems) {
        uint256 nftItemCount = nftItems.length;
        for (uint256 i = 0; i < nftItemCount; ) {
            IIncinerator.NFTItem calldata nftItem = nftItems[i];
            bytes.concat(encodedNFTItems, abi.encode(nftItem.collection, nftItem.tokenId));
            unchecked {
                i++;
            }
        }
    }
}
