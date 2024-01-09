// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./IERC721Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./LibAsset.sol";
import "./IRoyaltiesProvider.sol";
import "./LibERC721LazyMint.sol";
import "./LibERC1155LazyMint.sol";
import "./LibFill.sol";
import "./LibFeeSide.sol";
import "./ITransferManager.sol";
import "./TransferExecutor.sol";
import "./BpLibrary.sol";

abstract contract RaribleTransferManager is
  OwnableUpgradeable,
  ITransferManager
{
  using BpLibrary for uint256;
  using SafeMathUpgradeable for uint256;

  uint256 public protocolFee;
  IRoyaltiesProvider public royaltiesRegistry;

  address public defaultFeeReceiver;
  mapping(address => address) public feeReceivers;

  function __RaribleTransferManager_init_unchained(
    uint256 newProtocolFee,
    address newDefaultFeeReceiver,
    IRoyaltiesProvider newRoyaltiesProvider
  ) internal initializer {
    protocolFee = newProtocolFee;
    defaultFeeReceiver = newDefaultFeeReceiver;
    royaltiesRegistry = newRoyaltiesProvider;
  }

  function setRoyaltiesRegistry(IRoyaltiesProvider newRoyaltiesRegistry)
    external
    onlyOwner
  {
    royaltiesRegistry = newRoyaltiesRegistry;
  }

  function setProtocolFee(uint256 newProtocolFee) external onlyOwner {
    protocolFee = newProtocolFee;
  }

  function setDefaultFeeReceiver(address payable newDefaultFeeReceiver)
    external
    onlyOwner
  {
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
    LibOrder.Order memory rightOrder,
    LibOrderDataV2.DataV2 memory leftOrderData,
    LibOrderDataV2.DataV2 memory rightOrderData
  ) internal override returns (uint256 totalMakeValue, uint256 totalTakeValue) {
    LibFeeSide.FeeSide feeSide = LibFeeSide.getFeeSide(
      makeMatch.assetClass,
      takeMatch.assetClass
    );
    totalMakeValue = fill.leftValue;
    totalTakeValue = fill.rightValue;
    if (feeSide == LibFeeSide.FeeSide.MAKE) {
      totalMakeValue = doTransfersWithFees(
        fill.leftValue,
        leftOrder.maker,
        leftOrderData,
        rightOrderData,
        makeMatch,
        takeMatch,
        TO_TAKER
      );
      transferPayouts(
        takeMatch,
        fill.rightValue,
        rightOrder.maker,
        leftOrderData.payouts,
        TO_MAKER
      );
    } else if (feeSide == LibFeeSide.FeeSide.TAKE) {
      totalTakeValue = doTransfersWithFees(
        fill.rightValue,
        rightOrder.maker,
        rightOrderData,
        leftOrderData,
        takeMatch,
        makeMatch,
        TO_MAKER
      );
      transferPayouts(
        makeMatch,
        fill.leftValue,
        leftOrder.maker,
        rightOrderData.payouts,
        TO_TAKER
      );
    } else {
      transferPayouts(
        makeMatch,
        fill.leftValue,
        leftOrder.maker,
        rightOrderData.payouts,
        TO_TAKER
      );
      transferPayouts(
        takeMatch,
        fill.rightValue,
        rightOrder.maker,
        leftOrderData.payouts,
        TO_MAKER
      );
    }
  }

  function doTransfersWithFees(
    uint256 amount,
    address from,
    LibOrderDataV2.DataV2 memory dataCalculate,
    LibOrderDataV2.DataV2 memory dataNft,
    LibAsset.AssetType memory matchCalculate,
    LibAsset.AssetType memory matchNft,
    bytes4 transferDirection
  ) internal returns (uint256 totalAmount) {
    totalAmount = calculateTotalAmount(
      amount,
      protocolFee,
      dataCalculate.originFees
    );
    uint256 rest = transferProtocolFee(
      totalAmount,
      amount,
      from,
      matchCalculate,
      transferDirection
    );
    rest = transferRoyalties(
      matchCalculate,
      matchNft,
      rest,
      amount,
      from,
      transferDirection
    );
    (rest, ) = transferFees(
      matchCalculate,
      rest,
      amount,
      dataCalculate.originFees,
      from,
      transferDirection,
      ORIGIN
    );
    (rest, ) = transferFees(
      matchCalculate,
      rest,
      amount,
      dataNft.originFees,
      from,
      transferDirection,
      ORIGIN
    );
    transferPayouts(
      matchCalculate,
      rest,
      from,
      dataNft.payouts,
      transferDirection
    );
  }

  function transferProtocolFee(
    uint256 totalAmount,
    uint256 amount,
    address from,
    LibAsset.AssetType memory matchCalculate,
    bytes4 transferDirection
  ) internal returns (uint256) {
    (uint256 rest, uint256 fee) = subFeeInBp(
      totalAmount,
      amount,
      protocolFee.mul(2)
    );
    if (fee > 0) {
      address tokenAddress = address(0);
      if (matchCalculate.assetClass == LibAsset.ERC20_ASSET_CLASS) {
        tokenAddress = abi.decode(matchCalculate.data, (address));
      } else if (matchCalculate.assetClass == LibAsset.ERC1155_ASSET_CLASS) {
        uint256 tokenId;
        (tokenAddress, tokenId) = abi.decode(
          matchCalculate.data,
          (address, uint256)
        );
      }
      transfer(
        LibAsset.Asset(matchCalculate, fee),
        from,
        getFeeReceiver(tokenAddress),
        transferDirection,
        PROTOCOL
      );
    }
    return rest;
  }

  function transferRoyalties(
    LibAsset.AssetType memory matchCalculate,
    LibAsset.AssetType memory matchNft,
    uint256 rest,
    uint256 amount,
    address from,
    bytes4 transferDirection
  ) internal returns (uint256) {
    LibPart.Part[] memory fees = getRoyaltiesByAssetType(matchNft);

    (uint256 result, uint256 totalRoyalties) = transferFees(
      matchCalculate,
      rest,
      amount,
      fees,
      from,
      transferDirection,
      ROYALTY
    );
    require(totalRoyalties <= 5000, "Royalties are too high (>50%)");

    return result;
  }

  function getRoyaltiesByAssetType(LibAsset.AssetType memory matchNft)
    internal
    returns (LibPart.Part[] memory)
  {
    if (
      matchNft.assetClass == LibAsset.ERC1155_ASSET_CLASS ||
      matchNft.assetClass == LibAsset.ERC721_ASSET_CLASS
    ) {
      (address token, uint256 tokenId) = abi.decode(
        matchNft.data,
        (address, uint256)
      );

      return royaltiesRegistry.getRoyalties(token, tokenId);
    } else if (
      matchNft.assetClass == LibERC1155LazyMint.ERC1155_LAZY_ASSET_CLASS
    ) {
      (address token, LibERC1155LazyMint.Mint1155Data memory data) = abi.decode(
        matchNft.data,
        (address, LibERC1155LazyMint.Mint1155Data)
      );
      return data.royalties;
    } else if (
      matchNft.assetClass == LibERC721LazyMint.ERC721_LAZY_ASSET_CLASS
    ) {
      (address token, LibERC721LazyMint.Mint721Data memory data) = abi.decode(
        matchNft.data,
        (address, LibERC721LazyMint.Mint721Data)
      );

      return data.royalties;
    }
    LibPart.Part[] memory empty;
    return empty;
  }

  function transferFees(
    LibAsset.AssetType memory matchCalculate,
    uint256 rest,
    uint256 amount,
    LibPart.Part[] memory fees,
    address from,
    bytes4 transferDirection,
    bytes4 transferType
  ) internal returns (uint256 restValue, uint256 totalFees) {
    totalFees = 0;
    restValue = rest;
    for (uint256 i = 0; i < fees.length; i++) {
      totalFees = totalFees.add(fees[i].value);
      (uint256 newRestValue, uint256 feeValue) = subFeeInBp(
        restValue,
        amount,
        fees[i].value
      );
      restValue = newRestValue;
      if (feeValue > 0) {
        transfer(
          LibAsset.Asset(matchCalculate, feeValue),
          from,
          fees[i].account,
          transferDirection,
          transferType
        );
      }
    }
  }

  function transferPayouts(
    LibAsset.AssetType memory matchCalculate,
    uint256 amount,
    address from,
    LibPart.Part[] memory payouts,
    bytes4 transferDirection
  ) internal {
    uint256 sumBps = 0;
    uint256 restValue = amount;
    for (uint256 i = 0; i < payouts.length - 1; i++) {
      uint256 currentAmount = amount.bp(payouts[i].value);
      sumBps = sumBps.add(payouts[i].value);
      if (currentAmount > 0) {
        restValue = restValue.sub(currentAmount);
        transfer(
          LibAsset.Asset(matchCalculate, currentAmount),
          from,
          payouts[i].account,
          transferDirection,
          PAYOUT
        );
      }
    }
    LibPart.Part memory lastPayout = payouts[payouts.length - 1];
    sumBps = sumBps.add(lastPayout.value);
    require(sumBps == 10000, "Sum payouts Bps not equal 100%");
    if (restValue > 0) {
      transfer(
        LibAsset.Asset(matchCalculate, restValue),
        from,
        lastPayout.account,
        transferDirection,
        PAYOUT
      );
    }
  }

  function calculateTotalAmount(
    uint256 amount,
    uint256 feeOnTopBp,
    LibPart.Part[] memory orderOriginFees
  ) internal pure returns (uint256 total) {
    total = amount.add(amount.bp(feeOnTopBp));
    for (uint256 i = 0; i < orderOriginFees.length; i++) {
      total = total.add(amount.bp(orderOriginFees[i].value));
    }
  }

  function subFeeInBp(
    uint256 value,
    uint256 total,
    uint256 feeInBp
  ) internal pure returns (uint256 newValue, uint256 realFee) {
    return subFee(value, total.bp(feeInBp));
  }

  function subFee(uint256 value, uint256 fee)
    internal
    pure
    returns (uint256 newValue, uint256 realFee)
  {
    if (value > fee) {
      newValue = value.sub(fee);
      realFee = fee;
    } else {
      newValue = 0;
      realFee = value;
    }
  }

  uint256[46] private __gap;
}
