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

// Local imports - structs
import "./RequestTypes.sol";
import "./CrossChainRequestTypes.sol";
import "./BridgeTypes.sol";

// Local imports - encoders
import "./CrossChainEncoder.sol";

// Local imports - events
import "./AlephZeroEvents.sol";

// Local imports - errors
import "./CrossChainErrors.sol";
import "./AlephZeroErrors.sol";

// Local imports - storages
import "./LibCrossChainSubstrateConfiguration.sol";
import "./LibLayerZeroSender.sol";

/// @notice Service responsible for sending cross-chain messages to AlephZero
library AlephZeroSenderService {
    // -----------------------------------------------------------------------
    //                              Send message
    // -----------------------------------------------------------------------

    /// @dev Send cross-chain message.
    /// @param _crossChainData Encoded data to send
    /// @param _bridgeChainId Destination chain bridge id
    function sendCrossChainMessage(bytes calldata _crossChainData, uint256 _bridgeChainId) internal {
        // decode AlephZero params
        CrossChainRequestTypes.AlephZeroData memory azData_ = CrossChainEncoder.decodeAlephZeroData(_crossChainData);

        // get destination fundraising address
        bytes memory trustedRemote_ = LibCrossChainSubstrateConfiguration.getFundraising(_bridgeChainId);

        // validate data
        validateAlephZeroSendData(azData_, _bridgeChainId, trustedRemote_);

        // emit cross-chain message
        emit AlephZeroEvents.AlephZeroSenderEvent(
            BridgeTypes.Target(_bridgeChainId, trustedRemote_),
            BridgeTypes.Source(block.chainid, abi.encode(address(this))),
            BridgeTypes.Transaction(azData_.nonce, azData_.func, azData_.args, azData_.options)
        );
    }

    // -----------------------------------------------------------------------
    //                              Validation
    // -----------------------------------------------------------------------

    /// @dev Validate LayerZero data before send.
    /// @param _azData RequestTypes.LayerZeroData struct
    /// @param _chainId Destination chain native id
    /// @param _trustedRemote Trusted remote on desired chain id
    function validateAlephZeroSendData(
        CrossChainRequestTypes.AlephZeroData memory _azData,
        uint256 _chainId,
        bytes memory _trustedRemote
    ) internal view {
        // validate if destination chain is supported
        if (_trustedRemote.length == 0) {
            revert CrossChainErrors.UnsupportedChainId(_chainId);
        }

        // validate if function to perform is supported
        if (!LibCrossChainSubstrateConfiguration.getSupportedFunction(_chainId, _azData.func)) {
            revert AlephZeroErrors.UnsupportedFunction(_azData.func);
        }
    }
}
