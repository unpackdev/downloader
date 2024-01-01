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

interface IInvestorFacet {
    /// @dev Invest in a raise and mint ERC1155 equity badge for it.
    /// @dev Validation: Requires valid cosignature from AngelBlock validator to execute.
    /// @dev Events: NewInvestment(address sender, string raiseId, uint256 investment, bytes32 message, uint256 data).
    /// @param _request InvestRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function invest(RequestTypes.InvestRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external;

    /// @dev Refund investment to investor, if raise was not successful (softcap hasn't been reached).
    /// @dev Validation: Validate raise, sender and ability to refund.
    /// @dev Events: InvestmentRefunded(address sender, string raiseId, uint256 amount).
    /// @param _raiseId ID of raise
    function refundInvestment(string memory _raiseId) external;
}
