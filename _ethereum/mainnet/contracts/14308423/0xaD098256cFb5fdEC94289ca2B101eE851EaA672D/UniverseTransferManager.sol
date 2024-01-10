// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IERC721Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./LibAsset.sol";
import "./IRoyaltiesProvider.sol";
import "./LibFill.sol";
import "./LibFeeSide.sol";
import "./ITransferManager.sol";
import "./INftTransferProxy.sol";
import "./TransferExecutor.sol";
import "./LibOrderData.sol";
import "./BpLibrary.sol";
import "./LibERC721LazyMint.sol";
import "./LibERC1155LazyMint.sol";

abstract contract UniverseTransferManager is OwnableUpgradeable, ITransferManager {
    using BpLibrary for uint;
    using SafeMathUpgradeable for uint;

    uint public daoFee;
    IRoyaltiesProvider public royaltiesRegistry;

    address public defaultFeeReceiver;
    mapping(address => address) public feeReceivers;

    struct FeeCalculateInfo {
        LibAsset.AssetType matchCalculate;
        uint amount;
        address from;
        bytes4 transferDirection;
        LibPart.Part[] revenueSplits;
        LibAsset.AssetType matchNft;
        uint matchNftValue;
    }

    function __UniverseTransferManager_init_unchained(
        uint _daoFee,
        address _daoAddress,
        IRoyaltiesProvider _royaltiesRegistry
    ) internal initializer {
        daoFee = _daoFee;
        defaultFeeReceiver = _daoAddress;
        royaltiesRegistry = _royaltiesRegistry;
    }

    function setRoyaltiesRegistry(IRoyaltiesProvider _royaltiesRegistry) external onlyOwner {
        royaltiesRegistry = _royaltiesRegistry;
    }

    function setDaoFee(uint _daoFee) external onlyOwner {
        daoFee = _daoFee;
    }

    function setDefaultFeeReceiver(address payable newDefaultFeeReceiver) external onlyOwner {
        defaultFeeReceiver = newDefaultFeeReceiver;
    }

    function setFeeReceiver(address token, address wallet) external onlyOwner {
        feeReceivers[token] = wallet;
    }

    function getFeeReceiver(address token) internal view returns (address) {
        address wallet = feeReceivers[token];
        if (wallet != address(0)) {
            return wallet;
        }
        return defaultFeeReceiver;
    }

    function doTransfers(
        LibAsset.AssetType memory makeMatch,
        LibAsset.AssetType memory takeMatch,
        LibFill.FillResult memory fill,
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder
    ) override internal returns (uint totalMakeValue, uint totalTakeValue) {
        LibFeeSide.FeeSide feeSide = LibFeeSide.getFeeSide(makeMatch.assetClass, takeMatch.assetClass);

        totalMakeValue = fill.makeValue;
        totalTakeValue = fill.takeValue;

        LibOrderData.Data memory leftOrderData = LibOrderData.parse(leftOrder);
        LibOrderData.Data memory rightOrderData = LibOrderData.parse(rightOrder);

        if (feeSide == LibFeeSide.FeeSide.MAKE) {
            FeeCalculateInfo memory feeCalculateInfo = FeeCalculateInfo(makeMatch, totalMakeValue, leftOrder.maker, TO_TAKER, rightOrderData.revenueSplits, takeMatch, totalTakeValue);
            uint totalFees = transferAllFees(feeCalculateInfo);

            transfer(LibAsset.Asset(makeMatch, totalMakeValue.sub(totalFees)), leftOrder.maker, rightOrder.maker, PAYOUT, TO_TAKER);
            transfer(LibAsset.Asset(takeMatch, totalTakeValue), rightOrder.maker, leftOrder.maker, PAYOUT, TO_MAKER);

        } else if (feeSide == LibFeeSide.FeeSide.TAKE) {
            FeeCalculateInfo memory feeCalculateInfo = FeeCalculateInfo(takeMatch, totalTakeValue, rightOrder.maker, TO_MAKER, leftOrderData.revenueSplits, makeMatch, totalMakeValue);
            uint totalFees = transferAllFees(feeCalculateInfo);

            transfer(LibAsset.Asset(takeMatch, totalTakeValue.sub(totalFees)), rightOrder.maker, leftOrder.maker, PAYOUT, TO_MAKER);
            transfer(LibAsset.Asset(makeMatch, totalMakeValue), leftOrder.maker, rightOrder.maker, PAYOUT, TO_TAKER);

        } else {
            transfer(LibAsset.Asset(takeMatch, fill.takeValue), rightOrder.maker, leftOrder.maker, PAYOUT, TO_MAKER);
            transfer(LibAsset.Asset(makeMatch, fill.makeValue), leftOrder.maker, rightOrder.maker, PAYOUT, TO_TAKER);
        }
    }

    function transferAllFees(FeeCalculateInfo memory feeCalculateInfo) internal returns (uint allFeesValue) {
        uint royaltiesValue = transferRoyaltyFees(feeCalculateInfo.matchCalculate, feeCalculateInfo.matchNft, feeCalculateInfo.matchNftValue, feeCalculateInfo.amount, feeCalculateInfo.from, feeCalculateInfo.transferDirection);
        uint daoFeeValue = transferDaoFee(feeCalculateInfo.matchCalculate, feeCalculateInfo.amount.sub(royaltiesValue), feeCalculateInfo.from, feeCalculateInfo.transferDirection);
        uint revenueSplitsValue = transferRevenueSplits(feeCalculateInfo.matchCalculate, feeCalculateInfo.amount.sub(royaltiesValue).sub(daoFeeValue), feeCalculateInfo.from, feeCalculateInfo.revenueSplits, feeCalculateInfo.transferDirection);
        return royaltiesValue.add(daoFeeValue).add(revenueSplitsValue);
    }

    function transferDaoFee(
        LibAsset.AssetType memory matchCalculate,
        uint amount,
        address from,
        bytes4 transferDirection
    ) internal returns (uint) {
        uint daoFeeValue = amount.bp(daoFee);
        transfer(LibAsset.Asset(matchCalculate, daoFeeValue), from, defaultFeeReceiver, transferDirection, DAO);
        return daoFeeValue;
    }

    function transferRevenueSplits(
        LibAsset.AssetType memory matchCalculate,
        uint amount,
        address from,
        LibPart.Part[] memory revenueSplits,
        bytes4 transferDirection
    ) internal returns (uint) {
        uint sumBps = 0;
        uint restValue = amount;
        for (uint256 i = 0; i < revenueSplits.length && i < 5; i++) {
            uint currentAmount = amount.bp(revenueSplits[i].value);
            sumBps = sumBps.add(revenueSplits[i].value);
            if (currentAmount > 0) {
                restValue = restValue.sub(currentAmount);
                transfer(LibAsset.Asset(matchCalculate, currentAmount), from, revenueSplits[i].account, transferDirection, REVENUE_SPLIT);
            }
        }

        return amount.sub(restValue);
    }

    function transferFees(
        LibAsset.AssetType memory matchCalculate,
        LibPart.Part[] memory fees,
        uint amount,
        address from,
        bytes4 transferDirection
    ) internal returns (uint) {
        uint totalFees = 0;
        uint restValue = amount;
        for (uint256 i = 0; i < fees.length && i < 5; i++) {
            totalFees = totalFees.add(fees[i].value);
            (uint newRestValue, uint feeValue) = subFeeInBp(restValue, amount,  fees[i].value);
            restValue = newRestValue;
            if (feeValue > 0) {
                transfer(LibAsset.Asset(matchCalculate, feeValue), from,  fees[i].account, transferDirection, ROYALTY);
            }
        }
        require(totalFees <= 5000, "Royalties are too high (>50%)");
        return amount.sub(restValue);
    }

    function transferRoyaltyFees(
        LibAsset.AssetType memory matchCalculate,
        LibAsset.AssetType memory matchNft,
        uint matchNftValue,
        uint amount,
        address from,
        bytes4 transferDirection
    ) internal returns (uint) {
        uint256 totalAmount = 0;
        if (matchNft.assetClass == LibAsset.ERC1155_ASSET_CLASS || matchNft.assetClass == LibAsset.ERC721_ASSET_CLASS) {
            (address token, uint tokenId) = abi.decode(matchNft.data, (address, uint));
            (LibPart.Part[] memory fees, LibPart.Part[] memory collectionRoyalties) = royaltiesRegistry.getRoyalties(token, tokenId);

            uint256 nftFees = transferFees(matchCalculate, fees, amount, from, transferDirection);
            uint256 collectionFees = transferFees(matchCalculate, collectionRoyalties, amount - nftFees, from, transferDirection);
            totalAmount = collectionFees + nftFees;
        } else if (matchNft.assetClass == LibERC1155LazyMint.ERC1155_LAZY_ASSET_CLASS) {
            (address token, LibERC1155LazyMint.Mint1155Data memory data) = abi.decode(matchNft.data, (address, LibERC1155LazyMint.Mint1155Data));
            LibPart.Part[] memory fees = data.royalties;
            totalAmount = transferFees(matchCalculate, fees, amount, from, transferDirection);
        } else if (matchNft.assetClass == LibERC721LazyMint.ERC721_LAZY_ASSET_CLASS) {
            (address token, LibERC721LazyMint.Mint721Data memory data) = abi.decode(matchNft.data, (address, LibERC721LazyMint.Mint721Data));
            LibPart.Part[] memory fees = data.royalties;
            totalAmount = transferFees(matchCalculate, fees, amount, from, transferDirection);
        } else if (matchNft.assetClass == LibAsset.ERC721_BUNDLE_ASSET_CLASS) {
            (INftTransferProxy.ERC721BundleItem[] memory erc721BundleItems) = abi.decode(matchNft.data, (INftTransferProxy.ERC721BundleItem[]));
            for (uint256 i = 0; i < erc721BundleItems.length; i++) {
                for (uint256 j = 0; j < erc721BundleItems[i].tokenIds.length; j++){
                    (LibPart.Part[] memory fees, LibPart.Part[] memory collectionRoyalties) = royaltiesRegistry.getRoyalties(erc721BundleItems[i].tokenAddress, erc721BundleItems[i].tokenIds[j]);
                    totalAmount = totalAmount.add(_transferRoyaltyRegistryFees(matchCalculate, matchNftValue, fees, collectionRoyalties, amount, from, transferDirection));
                }
            }
        }
        return totalAmount;
    }

    function _transferRoyaltyRegistryFees(
        LibAsset.AssetType memory matchCalculate,
        uint matchNftValue,
        LibPart.Part[] memory nftRoyalties,
        LibPart.Part[] memory collectionRoyalties,
        uint amount,
        address from,
        bytes4 transferDirection
    ) internal returns (uint256 totalRoyaltiesFee) {
        uint256 nftFees = transferFees(matchCalculate, nftRoyalties, amount.div(matchNftValue), from, transferDirection);
        uint256 collectionFees = transferFees(matchCalculate, collectionRoyalties, amount.div(matchNftValue).sub(nftFees), from, transferDirection);
        return totalRoyaltiesFee = collectionFees.add(nftFees);
    }

    function encodeOrderData(LibOrderData.Data memory data) external pure returns (bytes memory encodedOrderData) {
        encodedOrderData = abi.encode(data);
    }

    function subFeeInBp(uint value, uint total, uint feeInBp) internal pure returns (uint newValue, uint realFee) {
        return subFee(value, total.bp(feeInBp));
    }

    function subFee(uint value, uint fee) internal pure returns (uint newValue, uint realFee) {
        if (value > fee) {
            newValue = value.sub(fee);
            realFee = fee;
        } else {
            newValue = 0;
            realFee = value;
        }
    }

}
