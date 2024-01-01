// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./EIP712.sol";
import "./ECDSA.sol";
import "./DataTypes.sol";

contract BrokersSignatureUtils is EIP712 {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum BrokerSignatureUtilsErrorCodes {
        INVALID_ASSET_INFO_SIGNATURE
    }

    error BrokerSignatureUtilsError(BrokerSignatureUtilsErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------
    using ECDSA for bytes32;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    bytes32 private immutable ASSET_DATA_TYPE_HASH;
    bytes32 private immutable ASSETS_TYPE_HASH;
    bytes32 private immutable FEES_TYPE_HASH;
    bytes32 private immutable TRADE_INFO_TYPE_HASH;

    /* ===== INIT ===== */

    /// @dev Constructor
    /// @dev Calculate and set type hashes for all the structs and nested structs types
    constructor() EIP712("NF3 Broker Swaps", "0.1.0") {
        bytes memory assetDataTypeString = abi.encodePacked(
            "AssetData(",
            "address token,",
            "uint8 assetType,",
            "uint256 tokenId,",
            "uint256 amount",
            ")"
        );

        bytes memory assetsTypeString = abi.encodePacked(
            "Assets(",
            "AssetData[] assets"
            ")"
        );

        bytes memory feesTypeString = abi.encodePacked(
            "Fees(",
            "address token,",
            "address broker,",
            "address platform,",
            "uint256 brokerAmount,",
            "uint256 platformAmount",
            ")"
        );

        bytes memory tradeInfoTyepString = abi.encodePacked(
            "TradeInfo(",
            "Assets makerAssets,",
            "Assets takerAssets,",
            "Fees makerFees,",
            "Fees takerFees,",
            "address maker,",
            "address taker,",
            "uint256 duration,",
            "uint256 makerNonce,",
            "uint256 takerNonce",
            ")"
        );

        ASSET_DATA_TYPE_HASH = keccak256(assetDataTypeString);

        ASSETS_TYPE_HASH = keccak256(
            abi.encodePacked(assetsTypeString, assetDataTypeString)
        );

        FEES_TYPE_HASH = keccak256(feesTypeString);

        TRADE_INFO_TYPE_HASH = keccak256(
            abi.encodePacked(
                tradeInfoTyepString,
                assetDataTypeString,
                assetsTypeString,
                feesTypeString
            )
        );
    }

    /// -----------------------------------------------------------------------
    /// Signature Verification Functions
    /// -----------------------------------------------------------------------

    function _verifyTradeInfoSignature(
        TradeInfo calldata _tradeInfo,
        bytes memory _makerSignature,
        bytes memory _takerSignature
    ) internal view {
        bytes32 tradeInfoHash = _hashTradeInfo(_tradeInfo);

        address _maker = _hashTypedDataV4(tradeInfoHash).recover(
            _makerSignature
        );
        address _taker = _hashTypedDataV4(tradeInfoHash).recover(
            _takerSignature
        );

        if (_tradeInfo.maker != _maker || _tradeInfo.taker != _taker) {
            revert BrokerSignatureUtilsError(
                BrokerSignatureUtilsErrorCodes.INVALID_ASSET_INFO_SIGNATURE
            );
        }
    }

    /// -----------------------------------------------------------------------
    /// Private functions
    /// -----------------------------------------------------------------------

    /// @dev Get eip 712 compliant hash for TradeInfo struct type
    /// @param _tradeInfo TradeInfo struct to be hashed
    function _hashTradeInfo(
        TradeInfo calldata _tradeInfo
    ) private view returns (bytes32) {
        bytes32 tradeInfoHash = keccak256(
            abi.encode(
                TRADE_INFO_TYPE_HASH,
                _hashAssets(_tradeInfo.makerAssets),
                _hashAssets(_tradeInfo.takerAssets),
                _hashFees(_tradeInfo.makerFees),
                _hashFees(_tradeInfo.takerFees),
                _tradeInfo.maker,
                _tradeInfo.taker,
                _tradeInfo.duration,
                _tradeInfo.makerNonce,
                _tradeInfo.takerNonce
            )
        );

        return tradeInfoHash;
    }

    /// @dev Get eip 712 compliant hash for Fees struct type
    /// @param _fees Fees struct to be hashed
    function _hashFees(Fees calldata _fees) private view returns (bytes32) {
        bytes32 feesTypeHash = keccak256(
            abi.encode(
                FEES_TYPE_HASH,
                _fees.token,
                _fees.broker,
                _fees.platform,
                _fees.brokerAmount,
                _fees.platformAmount
            )
        );
        return feesTypeHash;
    }

    /// @dev Get eip 712 compliant hash for Assets struct type
    /// @param _assets Assetes struct to be hashed
    function _hashAssets(
        Assets calldata _assets
    ) private view returns (bytes32) {
        uint256 assetsCount = _assets.assets.length;
        bytes32[] memory assetsHashes = new bytes32[](assetsCount);

        for (uint i; i < assetsCount; ) {
            assetsHashes[i] = _hashAssetData(_assets.assets[i]);
            unchecked {
                ++i;
            }
        }

        bytes32 assetsTypeHash = keccak256(
            abi.encode(
                ASSETS_TYPE_HASH,
                keccak256(abi.encodePacked(assetsHashes))
            )
        );

        return assetsTypeHash;
    }

    /// @dev Get eip 712 compliant hash for AssetData struct type
    /// @param _asset AssetData struct to be hashed
    function _hashAssetData(
        AssetData calldata _asset
    ) private view returns (bytes32) {
        bytes32 assetDataTypeHash = keccak256(
            abi.encode(
                ASSET_DATA_TYPE_HASH,
                _asset.token,
                _asset.assetType,
                _asset.tokenId,
                _asset.amount
            )
        );

        return assetDataTypeHash;
    }
}
