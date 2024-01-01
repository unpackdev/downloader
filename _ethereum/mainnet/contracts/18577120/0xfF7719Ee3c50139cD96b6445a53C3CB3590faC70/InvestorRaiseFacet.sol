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
import "./IInvestorFacet.sol";

// Local imports - Structs
import "./RequestTypes.sol";

// Local imports - Events
import "./RaiseEvents.sol";

// Local imports - Encoders
import "./RaiseEncoder.sol";

// Local imports - Constants
import "./RaiseConstants.sol";

// Local imports - Storages
import "./LibNonce.sol";

// Local imports - Services
import "./InvestorService.sol";
import "./SignatureService.sol";
import "./BadgeService.sol";
import "./BaseAssetService.sol";

contract InvestorRaiseFacet is IInvestorFacet {
    // -----------------------------------------------------------------------
    //                              Invest
    // -----------------------------------------------------------------------

    /// @dev Invest in a raise and mint ERC1155 equity badge for it.
    /// @dev Validation: Requires valid cosignature from AngelBlock validator to execute.
    /// @dev Events: NewInvestment(address sender, string raiseId, uint256 investment, bytes32 message, uint256 data).
    /// @param _request InvestRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function invest(RequestTypes.InvestRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external {
        // tx.members
        address sender_ = msg.sender;

        // request.members
        string memory raiseId_ = _request.raiseId;
        uint256 investment_ = _request.investment;

        // validate request
        InvestorService.validateInvestRequest(_request);

        // eip712 encoding
        bytes memory encodedMsg_ = RaiseEncoder.encodeInvest(_request);

        // verify message
        SignatureService.verifyMessage(RaiseConstants.EIP712_NAME, RaiseConstants.EIP712_VERSION, keccak256(encodedMsg_), _message);

        // verify signature
        SignatureService.verifySignature(_message, _v, _r, _s);

        // collect investment
        BaseAssetService.collectBaseAsset(raiseId_, sender_, _request.investment);

        // equity id
        uint256 badgeId_ = BadgeService.convertRaiseToBadge(raiseId_);

        // increase nonce
        LibNonce.setNonce(sender_, _request.base.nonce);

        // mint badge
        BadgeService.mintBadge(raiseId_, badgeId_, investment_);

        // storage
        InvestorService.saveInvestment(raiseId_, investment_);

        // event
        emit RaiseEvents.NewInvestment(sender_, raiseId_, investment_, _message, badgeId_);
    }

    // -----------------------------------------------------------------------
    //                              Refund
    // -----------------------------------------------------------------------

    /// @dev Refund investment to investor, if raise was not successful (softcap hasn't been reached).
    /// @dev Validation: Validate raise, sender and ability to refund.
    /// @dev Events: InvestmentRefunded(address sender, string raiseId, uint256 amount).
    /// @param _raiseId ID of raise
    function refundInvestment(string memory _raiseId) external {
        // tx.members
        address sender_ = msg.sender;

        // validate request
        InvestorService.validateRefundInvestment(_raiseId);

        // refund base asset
        uint256 investment_ = BaseAssetService.refundBaseAsset(_raiseId, sender_);

        // emit
        emit RaiseEvents.InvestmentRefunded(sender_, _raiseId, investment_);
    }
}
