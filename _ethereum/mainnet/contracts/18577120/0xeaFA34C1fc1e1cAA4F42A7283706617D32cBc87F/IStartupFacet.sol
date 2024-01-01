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

interface IStartupFacet {
    /// @dev Sets token for early stage startups, that haven't set ERC-20 token address during raise creation.
    /// @dev Validation: Requires valid cosignature from AngelBlock validator to execute.
    /// @dev Events: TokenSet(address sender, string raiseId, address token).
    /// @param _request SetTokenRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function setToken(RequestTypes.SetTokenRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external;

    /// @dev Reclaim unsold ERC20 by startup if raise went successful, but did not reach hardcap.
    /// @dev Validation: Validate raise, sender and ability to reclaim.
    /// @dev Events: UnsoldReclaimed(address startup, string raiseId, uint256 amount).
    /// @param _raiseId ID of raise
    function reclaimUnsold(string memory _raiseId) external;

    /// @dev Refund ERC20 to startup, if raise was not successful.
    /// @dev Validation: Validate raise, sender and ability to refund.
    /// @dev Events: CollateralRefunded(address startup, string raiseId, uint256 amount).
    /// @param _raiseId ID of raise
    function refundStartup(string memory _raiseId) external;
}
