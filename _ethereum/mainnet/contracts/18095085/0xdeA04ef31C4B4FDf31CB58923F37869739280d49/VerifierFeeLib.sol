// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import "./ERC165.sol";
import "./BitMaps.sol";

import "./ILayerZeroPriceFeed.sol";
import "./IVerifier.sol";
import "./IVerifierFeeLib.sol";
import "./VerifierOptions.sol";

contract VerifierFeeLib is IVerifierFeeLib {
    using BitMaps for BitMaps.BitMap256;
    using VerifierOptions for bytes;

    uint16 internal constant EXECUTE_FIXED_BYTES = 68; // encoded: funcSigHash + params -> 4  + (32 * 2)
    uint16 internal constant SIGNATURE_RAW_BYTES = 65; // not encoded
    // callData(updateHash) = 132 (4 + 32 * 4), padded to 32 = 160 and encoded as bytes with an 64 byte overhead = 224
    uint16 internal constant UPDATE_HASH_BYTES = 224;
    uint internal constant NATIVE_DECIMALS_RATE = 1e18;

    // ========================= External =========================

    /// @dev get fee function that can change state. e.g. paying priceFeed
    /// @param _params fee params
    /// @param _dstConfig dst config
    /// @param //_options options
    function getFeeOnSend(
        FeeParams memory _params,
        IVerifier.DstConfig memory _dstConfig,
        bytes memory /* _options */
    ) external payable returns (uint) {
        uint callDataSize = _getCallDataSize(_params.quorum);

        // for future versions where priceFeed charges a fee
        //        uint priceFeedFee = ILayerZeroPriceFeed(_params.priceFeed).getFee(_params.dstEid, callDataSize, _dstConfig.gas);
        //        (uint fee, , , uint128 nativePriceUSD) = ILayerZeroPriceFeed(_params.priceFeed).estimateFeeOnSend{
        //            value: priceFeedFee
        //        }(_params.dstEid, callDataSize, _dstConfig.gas);

        (uint fee, , , uint128 nativePriceUSD) = ILayerZeroPriceFeed(_params.priceFeed).estimateFeeOnSend(
            _params.dstEid,
            callDataSize,
            _dstConfig.gas
        );

        return
            _applyPremium(
                fee,
                _dstConfig.multiplierBps,
                _params.defaultMultiplierBps,
                _dstConfig.floorMarginUSD,
                nativePriceUSD
            );
    }

    // ========================= View =========================

    /// @dev get fee view function
    /// @param _params fee params
    /// @param _dstConfig dst config
    /// @param //_options options
    function getFee(
        FeeParams calldata _params,
        IVerifier.DstConfig calldata _dstConfig,
        bytes calldata /* _options */
    ) external view returns (uint) {
        uint callDataSize = _getCallDataSize(_params.quorum);
        (uint fee, , , uint128 nativePriceUSD) = ILayerZeroPriceFeed(_params.priceFeed).estimateFeeByEid(
            _params.dstEid,
            callDataSize,
            _dstConfig.gas
        );
        return
            _applyPremium(
                fee,
                _dstConfig.multiplierBps,
                _params.defaultMultiplierBps,
                _dstConfig.floorMarginUSD,
                nativePriceUSD
            );
    }

    // ========================= Internal =========================

    function _getCallDataSize(uint _quorum) internal pure returns (uint) {
        uint totalSignatureBytes = _quorum * SIGNATURE_RAW_BYTES;
        if (totalSignatureBytes % 32 != 0) {
            totalSignatureBytes = totalSignatureBytes - (totalSignatureBytes % 32) + 32;
        }
        // getFee should charge on execute(updateHash)
        // totalSignatureBytesPadded also has 64 overhead for bytes
        return uint(EXECUTE_FIXED_BYTES) + UPDATE_HASH_BYTES + totalSignatureBytes + 64;
    }

    function _applyPremium(
        uint _fee,
        uint16 _bps,
        uint16 _defaultBps,
        uint128 _marginUSD,
        uint128 _nativePriceUSD
    ) internal pure returns (uint) {
        uint16 multiplierBps = _bps == 0 ? _defaultBps : _bps;

        uint feeWithMultiplier = (_fee * multiplierBps) / 10000;
        if (_nativePriceUSD == 0 || _marginUSD == 0) {
            return feeWithMultiplier;
        }

        uint feeWithFloorMargin = _fee + (_marginUSD * NATIVE_DECIMALS_RATE) / _nativePriceUSD;

        return feeWithFloorMargin > feeWithMultiplier ? feeWithFloorMargin : feeWithMultiplier;
    }

    // todo: add to getFee and getFeeOnSend
    function _decodeVerifierOptions(bytes calldata _options) internal pure returns (uint totalFee) {
        BitMaps.BitMap256 bitmap;
        uint cursor;

        while (cursor < _options.length) {
            (uint8 optionType, , uint newCursor) = _options.nextVerifierOption(cursor);
            cursor = newCursor;

            // check if option type is duplicated
            require(!bitmap.get(optionType), Errors.DUPLICATED_OPTION);
            bitmap = bitmap.set(optionType);

            if (optionType == VerifierOptions.OPTION_TYPE_PRECRIME) {
                totalFee += 100; //todo: confirm fee
            } else {
                revert("VerifierFeeLib: invalid option type");
            }
        }
        require(cursor == _options.length, Errors.INVALID_VERIFIER_OPTION);
    }
}
