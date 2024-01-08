//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./LibGovernance.sol";
import "./LibRouter.sol";

import "./WrappedToken.sol";
import "./Governable.sol";

import "./IUtility.sol";


contract UtilityFacet is IUtility, Governable {
    using Counters for Counters.Counter;

    /**
     *  @notice Pauses a given token contract
     *  @param _tokenAddress The token contract
     *  @param _signatures The array of signatures from the members, authorising the operation
     */
    function pauseToken(address _tokenAddress, bytes[] calldata _signatures)
        external override
        onlyConsensus(computeTokenActionMessage(IUtility.TokenAction.Pause, _tokenAddress), _signatures)
    {
        LibGovernance.governanceStorage().administrativeNonce.increment();
        WrappedToken(_tokenAddress).pause();

        emit TokenPause(msg.sender, _tokenAddress);
    }

    /**
     *  @notice Unpauses a given token contract
     *  @param _tokenAddress The token contract
     *  @param _signatures The array of signatures from the members, authorising the operation
     */
    function unpauseToken(address _tokenAddress, bytes[] calldata _signatures)
        external override
        onlyConsensus(computeTokenActionMessage(IUtility.TokenAction.Unpause, _tokenAddress), _signatures)
    {
        LibGovernance.governanceStorage().administrativeNonce.increment();
        WrappedToken(_tokenAddress).unpause();

        emit TokenUnpause(msg.sender, _tokenAddress);
    }

    /**
     *  @notice Computes the Eth signed message to use for extracting signature signers for toggling a token state
     *  @param _action The action that was used when creating the validator signatures
     *  @param _tokenAddress The token address that was used when creating the validator signatures
     */
    function computeTokenActionMessage(IUtility.TokenAction _action, address _tokenAddress) internal view returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(keccak256(
            abi.encode(
                "computeTokenActionMessage",
                uint8(_action), _tokenAddress,
                LibGovernance.governanceStorage().administrativeNonce.current())
            )
        );
    }

    /**
     *  @notice Adds an existing token contract to use as a WrappedToken
     *  @param _nativeChainId The native network for the token
     *  @param _nativeToken The address in the native network
     *  @param _wrappedToken The wrapped token address in this network
     *  @param _signatures The array of signatures from the members, authorising the operation
     */
    function setWrappedToken(uint8 _nativeChainId, bytes calldata _nativeToken, address _wrappedToken, bytes[] calldata _signatures)
        external override
        onlyConsensus(computeSetWrappedTokenMessage(_nativeChainId, _nativeToken, _wrappedToken), _signatures)
    {
        require(_wrappedToken != address(0), "Wrapped token address must be non-zero");

        LibRouter.Storage storage rs = LibRouter.routerStorage();
        rs.nativeToWrappedToken[_nativeChainId][_nativeToken] = _wrappedToken;
        rs.wrappedToNativeToken[_wrappedToken].chainId = _nativeChainId;
        rs.wrappedToNativeToken[_wrappedToken].token = _nativeToken;

        LibGovernance.governanceStorage().administrativeNonce.increment();

        emit WrappedTokenSet(_nativeChainId, _nativeToken, _wrappedToken);
    }

    /**
     *  @notice Computes the Eth signed message to use for extracting signature signers for toggling a token state
     *  @param _nativeChainId The native network for the token
     *  @param _nativeToken The address in the native network
     *  @param _wrappedToken The wrapped token address in this network
     */
    function computeSetWrappedTokenMessage(uint8 _nativeChainId, bytes calldata _nativeToken, address _wrappedToken)
        internal view returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(keccak256(
            abi.encode(
                "computeSetWrappedTokenMessage",
                _nativeChainId, _nativeToken, _wrappedToken,
                LibGovernance.governanceStorage().administrativeNonce.current())
            )
        );
    }

    /**
     *  @notice Removes a wrapped-native token pair from the bridge
     *  @param _wrappedToken The wrapped token address in this network
     *  @param _signatures The array of signatures from the members, authorising the operation
     */
    function unsetWrappedToken(address _wrappedToken, bytes[] calldata _signatures)
        external override
        onlyConsensus(computeUnsetWrappedTokenMessage(_wrappedToken), _signatures)
    {
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        delete rs.nativeToWrappedToken[rs.wrappedToNativeToken[_wrappedToken].chainId][rs.wrappedToNativeToken[_wrappedToken].token];
        delete rs.wrappedToNativeToken[_wrappedToken];

        LibGovernance.governanceStorage().administrativeNonce.increment();
        emit WrappedTokenUnset(_wrappedToken);
    }

    /**
     *  @notice Computes the Eth signed message to use for extracting signature signers for toggling a token state
     *  @param _wrappedToken The wrapped token address in this network
     */
    function computeUnsetWrappedTokenMessage(address _wrappedToken)
        internal view returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(keccak256(
            abi.encode(
                "computeUnsetWrappedTokenMessage",
                _wrappedToken,
                LibGovernance.governanceStorage().administrativeNonce.current())
            )
        );
    }

}
