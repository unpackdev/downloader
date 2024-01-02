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

// Local imports
import "./LibLayerZeroBase.sol";
import "./LibCrossChainEvmConfiguration.sol";
import "./LibLayerZeroSender.sol";

/**************************************

    Fundraising initializer for LayerZero sender

 **************************************/

/// @dev Initializer for LayerZero Bridge that adds new supported network id
contract LayerZeroSenderInit {
    // -----------------------------------------------------------------------
    //                              Structs
    // -----------------------------------------------------------------------

    /// @dev Args for initializer.
    /// @param endpoint LayerZero endpoint contract address on source chain
    /// @param refundAddress Refund address for LayerZero calls
    /// @param lzChainId LayerZero chain id of destination
    /// @param nativeChainId Native chain id of destination
    /// @param remoteFundraising Address of the fundraising on the destination chain
    /// @param supportedFunctions Supported functions in bytes4 format
    struct Arguments {
        address endpoint;
        address refundAddress;
        uint16 lzChainId;
        uint256 nativeChainId;
        address remoteFundraising;
        bytes4[] supportedFunctions;
    }

    // -----------------------------------------------------------------------
    //                              Functions
    // -----------------------------------------------------------------------

    /// @dev External init function for a delegate call.
    /// @param _args Arguments struct
    function init(Arguments calldata _args) external {
        // init layer zero
        _initLz(_args.endpoint, _args.refundAddress);

        // register fundraising on new network
        _registerNetwork(_args.nativeChainId, _args.lzChainId, _args.remoteFundraising, _args.supportedFunctions);
    }

    /// @dev Internal init function for LayerZero provider.
    /// @param _endpoint LayerZero endpoint contract address on source chain
    /// @param _refundAddress Refund address for LayerZero calls
    function _initLz(address _endpoint, address _refundAddress) internal {
        // set endpoint
        LibLayerZeroBase.setCrossChainEndpoint(_endpoint);

        // set refund address
        LibLayerZeroSender.setRefundAddress(_refundAddress);
    }

    /// @dev Register network for relaying cross-chain messages via LayerZero.
    /// @param _nativeChainId Native chain id of destination
    /// @param _lzChainId LayerZero chain id of destination
    /// @param _remoteFundraising Address of the fundraising on the destination chain
    /// @param _supportedFunctions Supported functions in bytes4 format
    function _registerNetwork(
        uint256 _nativeChainId,
        uint16 _lzChainId,
        address _remoteFundraising,
        bytes4[] memory _supportedFunctions
    ) internal {
        // network init
        LibLayerZeroSender.setNetwork(_nativeChainId, _lzChainId);

        // fundraising init
        LibCrossChainEvmConfiguration.setFundraising(_nativeChainId, _remoteFundraising);

        // functions init
        for (uint i = 0; i < _supportedFunctions.length; i++) {
            LibCrossChainEvmConfiguration.setSupportedFunction(_nativeChainId, _supportedFunctions[i], true);
        }
    }
}
