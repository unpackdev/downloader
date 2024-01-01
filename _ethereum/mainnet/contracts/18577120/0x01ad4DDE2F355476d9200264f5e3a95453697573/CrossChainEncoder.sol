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

// Local imports - Structs
import "./RequestTypes.sol";
import "./CrossChainRequestTypes.sol";

/**************************************

    Raise encoder

**************************************/

/// @notice Raise encoder for EIP712 message hash.
library CrossChainEncoder {
    /// @dev Decode request data for raise registration.
    /// @param _payload Sent payload
    /// @return Decoded request data
    function decodeRegisterRaisePayload(
        bytes calldata _payload
    ) internal pure returns (RequestTypes.RegisterRaiseRequest memory, bytes32, uint8, bytes32, bytes32) {
        // return
        return abi.decode(_payload, (RequestTypes.RegisterRaiseRequest, bytes32, uint8, bytes32, bytes32));
    }

    /// @dev Decode LayerZero data needed to send cross-chain message
    /// @param _crossChainData Encoded data to send
    /// @return Decoded RequestTypes.LayerZeroData struct
    function decodeLayerZeroData(bytes calldata _crossChainData) internal pure returns (CrossChainRequestTypes.LayerZeroData memory) {
        // decode and return
        return abi.decode(_crossChainData, (CrossChainRequestTypes.LayerZeroData));
    }

    /// @dev Decode AlephZero data needed to send cross-chain message
    /// @param _crossChainData Encoded data to send
    /// @return Decoded RequestTypes.AlephZeroData struct
    function decodeAlephZeroData(bytes calldata _crossChainData) internal pure returns (CrossChainRequestTypes.AlephZeroData memory) {
        // decode and return
        return abi.decode(_crossChainData, (CrossChainRequestTypes.AlephZeroData));
    }
}
