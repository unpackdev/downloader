// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IERC721Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./LibFill.sol";
import "./TransferExecutor.sol";

abstract contract TransferManager is Initializable, TransferExecutor {
    using SafeMathUpgradeable for uint256;

    enum FeeSide {
        NONE,
        MAKE,
        TAKE
    }

    function __TransferManager_init_unchained() internal initializer {}

    function _getFeeSide(bytes4 make, bytes4 take)
        internal
        pure
        returns (FeeSide)
    {
        if (make == LibAsset.ETH_ASSET_CLASS) {
            return FeeSide.MAKE;
        }
        if (take == LibAsset.ETH_ASSET_CLASS) {
            return FeeSide.TAKE;
        }
        if (make == LibAsset.ERC20_ASSET_CLASS) {
            return FeeSide.MAKE;
        }
        if (take == LibAsset.ERC20_ASSET_CLASS) {
            return FeeSide.TAKE;
        }
        return FeeSide.NONE;
    }

    function encode(LibOrderData.Data memory data)
        external
        pure
        returns (bytes memory)
    {
        return abi.encode(data);
    }

    function encodeNFT(LibPart.Part[] memory royalties)
        external
        pure
        returns (bytes memory)
    {
        return abi.encode(royalties);
    }

    // doTransfers
    function _doTransfers(
        LibAsset.AssetType memory makeMatch,
        LibAsset.AssetType memory takeMatch,
        LibFill.FillResult memory fill,
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder,
        LibOrderData.Data memory leftData,
        LibOrderData.Data memory rightData
    )
        internal
    {
        FeeSide feeSide = _getFeeSide(
            makeMatch.assetClass,
            takeMatch.assetClass
        );
        if (feeSide == FeeSide.MAKE) {
            _doTransfersWithFees(
                fill.leftValue,
                leftOrder.maker,
                leftData,
                makeMatch,
                takeMatch
            );
            _transfer(
                LibAsset.Asset(
                    takeMatch,
                    fill.rightValue,
                    leftOrder.makeAsset.token,
                    leftOrder.makeAsset.tokenId
                ),
                rightOrder.maker,
                leftData.recipient
            );
        } else if (feeSide == FeeSide.TAKE) {
            _doTransfersWithFees(
                fill.rightValue,
                rightOrder.maker,
                leftData,
                takeMatch,
                makeMatch
            );
            _transfer(
                LibAsset.Asset(
                    makeMatch,
                    fill.leftValue,
                    leftOrder.makeAsset.token,
                    leftOrder.makeAsset.tokenId
                ),
                leftOrder.maker,
                rightData.recipient
            );
        } else {
            revert("doTransfer is invalid");
        }
    }

    function _doTransfersWithFees(
        uint256 amount,
        address from,
        LibOrderData.Data memory data,
        LibAsset.AssetType memory matchCalculate,
        LibAsset.AssetType memory matchNft
    ) internal {
        uint256 rest = amount;
        // royalties
        rest = _transferRoyalties(matchCalculate, matchNft, rest, amount, from);

        // trading fee
        (rest, ) = _transferFees(
            matchCalculate,
            rest,
            amount,
            data.originFees,
            from
        );

        // receiver
        _transferPayouts(matchCalculate, rest, from, data.recipient);
    }

    function _transferRoyalties(
        LibAsset.AssetType memory matchCalculate,
        LibAsset.AssetType memory matchNft,
        uint256 rest,
        uint256 amount,
        address from
    ) internal returns (uint256) {
        LibPart.Part[] memory fees = _getRoyaltiesByAssetType(matchNft);

        (uint256 result, uint256 totalRoyalties) = _transferFees(
            matchCalculate,
            rest,
            amount,
            fees,
            from
        );
        require(totalRoyalties <= 1000, "Royalties are too high (>10%)");
        return result;
    }

    function _getRoyaltiesByAssetType(LibAsset.AssetType memory matchNft)
        internal
        pure
        returns (LibPart.Part[] memory royalties)
    {
        (royalties) = abi.decode(matchNft.data, (LibPart.Part[]));

        return royalties;
    }

    function _transferFees(
        LibAsset.AssetType memory matchCalculate,
        uint256 rest,
        uint256 amount,
        LibPart.Part[] memory fees,
        address from
    ) internal returns (uint256, uint256) {
        uint256 totalFees = 0;
        uint256 restValue = rest;
        for (uint256 i = 0; i < fees.length; i++) {
            totalFees = totalFees.add(fees[i].value);
            (uint256 newRestValue, uint256 feeValue) = _subFeeInBp(
                restValue,
                amount,
                fees[i].value
            );
            restValue = newRestValue;
            if (feeValue > 0) {
                _transfer(
                    LibAsset.Asset(matchCalculate, feeValue, address(0), 0),
                    from,
                    fees[i].account
                );
            }
        }
        return (restValue, totalFees);
    }

    function _transferPayouts(
        LibAsset.AssetType memory matchCalculate,
        uint256 amount,
        address from,
        address recipient
    ) internal {
        if (amount > 0) {
            _transfer(
                LibAsset.Asset(matchCalculate, amount, address(0), 0),
                from,
                recipient
            );
        }
    }

    function _bp(uint256 value, uint256 bpValue)
        internal
        pure
        returns (uint256)
    {
        return value.mul(bpValue).div(10000);
    }

    function _subFeeInBp(
        uint256 value,
        uint256 total,
        uint256 feeInBp
    ) internal pure returns (uint256 newValue, uint256 realFee) {
        return _subFee(value, _bp(total, feeInBp));
    }

    function _subFee(uint256 value, uint256 fee)
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
}
