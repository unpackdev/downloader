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
import "./BaseTypes.sol";
import "./RequestTypes.sol";

/**************************************

    Raise facet interface

**************************************/

/// Interface for raise facet.
interface IRaiseFacet {
    // -----------------------------------------------------------------------
    //                              Functions
    // -----------------------------------------------------------------------

    /**************************************

        Create new raise

     **************************************/

    /// @dev Create new raise and initializes fresh escrow clone for it.
    /// @dev Validation: Supports standard and early stage raises.
    /// @dev Validation: Requires valid cosignature from AngelBlock validator to execute.
    /// @dev Events: NewRaise(address sender, BaseTypes.Raise raise, uint256 badgeId, bytes32 message).
    /// @param _request CreateRaiseRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function createRaise(RequestTypes.CreateRaiseRequest memory _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external;

    /**************************************

        Set token

     **************************************/

    /// @dev Sets token for early stage startups, that does not have ERC20 during raise creation.
    /// @dev Validation: Requires valid cosignature from AngelBlock validator to execute.
    /// @dev Events: TokenSet(address sender, string raiseId, address token).
    /// @param _request SetTokenRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function setToken(RequestTypes.SetTokenRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external;

    /**************************************

        Invest

     **************************************/

    /// @dev Invest in a raise and mint ERC1155 equity badge for it.
    /// @dev Validation: Requires valid cosignature from AngelBlock validator to execute.
    /// @dev Events: NewInvestment(address sender, string raiseId, uint256 investment, bytes32 message, uint256 data).
    /// @param _request InvestRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function invest(RequestTypes.InvestRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external;

    /**************************************

        Reclaim unsold

     **************************************/

    /// @dev Reclaim unsold ERC20 by startup if raise went successful, but did not reach hardcap.
    /// @dev Validation: Validate raise, sender and ability to reclaim.
    /// @dev Events: UnsoldReclaimed(address startup, string raiseId, uint256 amount).
    /// @param _raiseId ID of raise
    function reclaimUnsold(string memory _raiseId) external;

    /**************************************

        Refund funds

     **************************************/

    /// @dev Refund investment to investor, if raise was not successful.
    /// @dev Validation: Validate raise, sender and ability to refund.
    /// @dev Events: InvestmentRefunded(address sender, string raiseId, uint256 amount).
    /// @param _raiseId ID of raise
    function refundInvestment(string memory _raiseId) external;

    /**************************************

        Refund collateral to startup

    **************************************/

    /// @dev Refund ERC20 to startup, if raise was not successful.
    /// @dev Validation: Validate raise, sender and ability to refund.
    /// @dev Events: CollateralRefunded(address startup, string raiseId, uint256 amount).
    /// @param _raiseId ID of raise
    function refundStartup(string memory _raiseId) external;

    /**************************************

        View: Convert raise to badge

     **************************************/

    /// @dev Calculate ID of equity badge based on ID of raise.
    /// @param _raiseId ID of raise
    /// @return ID of badge (derived from hash of raise ID)
    function convertRaiseToBadge(string memory _raiseId) external pure returns (uint256);
}
