// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IFeeDistributor.sol";
import "./IRoyaltySplitter.sol";

interface INFTFactory {
    struct CreateCollectionParams {
        uint256 transactionId;
        uint256 collectionId;
        string name;
        string symbol;
        uint256 itemLimit;
        IRoyaltySplitter.Royalty[] royalties;
        IFeeDistributor.Fee[] fees;
    }

    struct MintItemParams {
        uint256 transactionId;
        uint256 collectionId;
        uint256 deduplicationId;
        uint256 maxItemSupply;
        uint256 tokenId;
        address tokenReceiver;
        string tokenURI;
        IRoyaltySplitter.Royalty[] royalties;
        IFeeDistributor.Fee[] fees;
    }

    function createCollection(CreateCollectionParams calldata params, bytes calldata signature) external payable;

    function mintItem(MintItemParams calldata params, bytes calldata signature) external payable;

    function mintItemUnsigned(MintItemParams calldata params) external payable;

    function computeCollectionAddress(
        uint256 collectionId,
        string memory name,
        string memory symbol
    ) external view returns (address);

    function createCollectionHash(
        CreateCollectionParams calldata params,
        address sender
    ) external pure returns (bytes32);

    function mintItemHash(MintItemParams calldata params, address sender) external pure returns (bytes32);
}
