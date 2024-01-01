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
import "./RaiseConstants.sol";
import "./RequestTypes.sol";

/**************************************

    Raise encoder

**************************************/

/// @notice Raise encoder for EIP712 message hash.
library RaiseEncoder {
    /// @dev Encode create raise request data.
    /// @param _request RequestTypes.CreateRaiseRequest struct
    function encodeCreateRaise(RequestTypes.CreateRaiseRequest memory _request) internal pure returns (bytes memory) {
        // encode request elements
        bytes memory encodedRaise_ = abi.encode(_request.raise);
        bytes memory encodedRaiseDetails_ = abi.encode(_request.raiseDetails);
        bytes memory encodedERC20Asset_ = abi.encode(_request.erc20Asset);
        bytes memory encodedBaseAsset_ = abi.encode(_request.baseAsset);
        bytes memory encodedBase_ = abi.encode(_request.base);

        // return encoded data
        return
            abi.encode(
                RaiseConstants.STARTUP_CREATE_RAISE_TYPEHASH,
                keccak256(encodedRaise_),
                keccak256(encodedRaiseDetails_),
                keccak256(encodedERC20Asset_),
                keccak256(encodedBaseAsset_),
                keccak256(encodedBase_),
                keccak256(bytes(_request.badgeUri))
            );
    }

    /// @dev Encode register raise request.
    /// @param _request RequestTypes.RegisterRaiseRequest struct
    /// @return Encoded message.
    function encodeRegisterRaise(RequestTypes.RegisterRaiseRequest memory _request) internal pure returns (bytes memory) {
        bytes memory encodedRaise_ = abi.encode(_request.raise);
        bytes memory encodedRaiseDetails_ = abi.encode(_request.raiseDetails);
        bytes memory encodedERC20Asset_ = abi.encode(_request.erc20Asset);
        bytes memory encodedBaseAsset = abi.encode(_request.baseAsset);

        return
            abi.encode(
                RaiseConstants.STARTUP_REGISTER_RAISE_TYPEHASH,
                keccak256(encodedRaise_),
                keccak256(encodedRaiseDetails_),
                keccak256(encodedERC20Asset_),
                keccak256(encodedBaseAsset)
            );
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
