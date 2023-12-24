// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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
import "./RaiseConstants.sol";
import "./RequestTypes.sol";

/**************************************

    Raise encoder

**************************************/

/// @notice Raise encoder for EIP712 message hash.
library RaiseEncoder {
    /// @dev Encode create raise request to validate the EIP712 message.
    /// @param _request CreateRaiseRequest struct
    /// @return EIP712 encoded message containing request
    function encodeCreateRaise(RequestTypes.CreateRaiseRequest memory _request) internal pure returns (bytes memory) {
        // raise
        bytes memory encodedRaise_ = abi.encode(_request.raise);

        // vested
        bytes memory encodedVested_ = abi.encode(_request.vested);

        // base
        bytes memory encodedBase_ = abi.encode(_request.base);

        // msg
        bytes memory encodedMsg_ = abi.encode(
            RaiseConstants.STARTUP_CREATE_RAISE_TYPEHASH,
            keccak256(encodedRaise_),
            keccak256(encodedVested_),
            keccak256(encodedBase_)
        );

        // return
        return encodedMsg_;
    }

    /// @dev Encode set token request to validate the EIP712 message.
    /// @param _request SetTokenRequest struct
    /// @return EIP712 encoded message containing request
    function encodeSetToken(RequestTypes.SetTokenRequest memory _request) internal pure returns (bytes memory) {
        // base
        bytes memory encodedBase_ = abi.encode(_request.base);

        // msg
        bytes memory encodedMsg_ = abi.encode(
            RaiseConstants.STARTUP_SET_TOKEN_TYPEHASH,
            keccak256(bytes(_request.raiseId)),
            _request.token,
            keccak256(encodedBase_)
        );

        // return
        return encodedMsg_;
    }

    /// @dev Encode invest request to validate the EIP712 message.
    /// @param _request InvestRequest struct
    /// @return EIP712 encoded message containing request
    function encodeInvest(RequestTypes.InvestRequest memory _request) internal pure returns (bytes memory) {
        // base
        bytes memory encodedBase_ = abi.encode(_request.base);

        // msg
        bytes memory encodedMsg_ = abi.encode(
            RaiseConstants.INVESTOR_INVEST_TYPEHASH,
            keccak256(bytes(_request.raiseId)),
            _request.investment,
            _request.maxTicketSize,
            keccak256(encodedBase_)
        );

        // return
        return encodedMsg_;
    }
}
