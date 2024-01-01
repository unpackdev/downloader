// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

// LayerZero
import "./ILayerZeroEndpoint.sol";

// Local imports - Structs
import "./RequestTypes.sol";
import "./CrossChainRequestTypes.sol";

// Local imports - Encoders
import "./CrossChainEncoder.sol";

// Local imports - Errors
import "./CrossChainErrors.sol";
import "./LayerZeroErrors.sol";

// Local imports - Storages
import "./LibCrossChainEvmConfiguration.sol";
import "./LibLayerZeroBase.sol";
import "./LibLayerZeroSender.sol";

/// @notice Service responsible for sending cross-chain messages through LayerZero
library LayerZeroSenderService {
    // -----------------------------------------------------------------------
    //                              Send message
    // -----------------------------------------------------------------------

    /// @dev Send cross-chain message.
    /// @param _crossChainData Encoded data to send
    /// @param _nativeChainId Destination chain native id
    function sendCrossChainMessage(bytes calldata _crossChainData, uint256 _nativeChainId) internal {
        // decode LayerZero params
        CrossChainRequestTypes.LayerZeroData memory lzData_ = CrossChainEncoder.decodeLayerZeroData(_crossChainData);

        // validate data
        validateLayerZeroSendData(lzData_, _nativeChainId);

        // get LayerZero chain id
        uint16 lzChainId_ = LibLayerZeroSender.getNetwork(_nativeChainId);

        // get LayerZero endpoint
        address lzEndpoint_ = LibLayerZeroBase.getCrossChainEndpoint();

        // get destination fundraising address
        address destination_ = LibCrossChainEvmConfiguration.getFundraising(_nativeChainId);

        // get address needed to potential refund
        address payable refundAddress_ = payable(LibLayerZeroSender.getRefundAddress());

        // calculate LayerZero trusted remote
        bytes memory trustedRemote_ = abi.encodePacked(destination_, address(this));

        // send cross-chain message
        ILayerZeroEndpoint(lzEndpoint_).send{ value: lzData_.fee }(
            lzChainId_,
            trustedRemote_,
            lzData_.payload,
            refundAddress_,
            address(0), // Parameter which will be used by LayerZero in the future when they'll have their token, right now hardcoded
            lzData_.additionalParams
        );
    }

    // -----------------------------------------------------------------------
    //                              Validation
    // -----------------------------------------------------------------------

    /// @dev Validate LayerZero data before send.
    /// @param _lzData RequestTypes.LayerZeroData struct
    /// @param _chainId Destination chain native id
    function validateLayerZeroSendData(CrossChainRequestTypes.LayerZeroData memory _lzData, uint256 _chainId) internal view {
        // validate if payload is not empty
        if (_lzData.payload.length == 0) {
            revert CrossChainErrors.EmptyPayload();
        }

        // validate if destination chain is supported
        if (LibLayerZeroSender.getNetwork(_chainId) == 0) {
            revert LayerZeroErrors.UnsupportedLayerZeroChain(_chainId);
        }

        // validate if function to perform is supported
        bytes4 functionToCall_ = bytes4(_lzData.payload);
        if (!LibCrossChainEvmConfiguration.getSupportedFunction(_chainId, functionToCall_)) {
            revert LayerZeroErrors.UnsupportedFunction(functionToCall_);
        }

        // validate if LayerZero fee is not equal 0
        if (_lzData.fee == 0) {
            revert LayerZeroErrors.InvalidLayerZeroFee();
        }

        // validate if sent native tokens is at least the same like LayerZero fee
        if (msg.value < _lzData.fee) {
            revert LayerZeroErrors.InvalidNativeSent(msg.value, _lzData.fee);
        }
    }
}
