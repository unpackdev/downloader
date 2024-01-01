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

// Local imports - Interfaces
import "./IStartupFacet.sol";

// Local imports - Structs
import "./RequestTypes.sol";

// Local imports - Events
import "./RaiseEvents.sol";

// Local imports - Encoders
import "./RaiseEncoder.sol";

// Local imports - Constants
import "./RaiseConstants.sol";

// Local imports - Storages
import "./LibERC20Asset.sol";
import "./LibStartupFundsInfo.sol";

// Local imports - Services
import "./StartupService.sol";
import "./SignatureService.sol";

contract StartupRaiseFacet is IStartupFacet {
    /// @dev Sets token for early stage startups, that haven't set ERC-20 token address during raise creation.
    /// @dev Validation: Requires valid cosignature from AngelBlock validator to execute.
    /// @dev Events: TokenSet(address sender, string raiseId, address token).
    /// @param _request SetTokenRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function setToken(RequestTypes.SetTokenRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external {
        // tx.members
        address sender_ = msg.sender;

        // request.members
        string memory raiseId_ = _request.raiseId;
        address token_ = _request.token;

        // validate request
        StartupService.validateSetTokenRequest(_request);

        // eip712 encoding
        bytes memory encodedMsg_ = RaiseEncoder.encodeSetToken(_request);

        // verify message
        SignatureService.verifyMessage(RaiseConstants.EIP712_NAME, RaiseConstants.EIP712_VERSION, keccak256(encodedMsg_), _message);

        // verify signature
        SignatureService.verifySignature(_message, _v, _r, _s);

        // set token address
        LibERC20Asset.setERC20Address(raiseId_, token_);

        // emit event
        emit RaiseEvents.TokenSet(sender_, raiseId_, token_);
    }

    /// @dev Reclaim unsold ERC20 by startup if raise went successful, but did not reach hardcap.
    /// @dev Validation: Validate raise, sender and ability to reclaim.
    /// @dev Events: UnsoldReclaimed(address startup, string raiseId, uint256 amount).
    /// @param _raiseId ID of raise
    function reclaimUnsold(string memory _raiseId) external {
        // tx.members
        address sender_ = msg.sender;

        // validations
        StartupService.validateReclaimUnsold(_raiseId);

        // mark as reclaimed
        LibStartupFundsInfo.setReclaimed(_raiseId, true);

        // send tokens
        uint256 unsold_ = StartupService.reclaimUnsold(sender_, _raiseId);

        // emit
        emit RaiseEvents.UnsoldReclaimed(sender_, _raiseId, unsold_);
    }

    /// @dev Refund ERC20 to startup, if raise was not successful.
    /// @dev Validation: Validate raise, sender and ability to refund.
    /// @dev Events: CollateralRefunded(address startup, string raiseId, uint256 amount).
    /// @param _raiseId ID of raise
    function refundStartup(string memory _raiseId) external {
        // tx.members
        address sender_ = msg.sender;

        // validate request
        StartupService.validateRefundStartup(_raiseId);

        // set collateral refunded in storage
        LibStartupFundsInfo.setCollateralRefunded(_raiseId, true);

        // refund collateral
        uint256 collateral_ = StartupService.refundCollateral(_raiseId);

        // emit
        emit RaiseEvents.CollateralRefunded(sender_, _raiseId, collateral_);
    }
}
