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

// Local imports - Constants
import "./RaiseConstants.sol";

// Local imports - Errors
import "./CrossChainErrors.sol";
import "./RequestErrors.sol";
import "./RaiseErrors.sol";

// Local imports - Storages
import "./LibRaise.sol";
import "./LibBaseAsset.sol";
import "./LibNonce.sol";
import "./LibInvestorFundsInfo.sol";

// Local imports - Services
import "./RaiseService.sol";

library InvestorService {
    /// @dev Validate invest request.
    /// @dev Validation: Checks validity of sender, request, raise and investment.
    /// @param _request InvestRequest struct
    function validateInvestRequest(RequestTypes.InvestRequest calldata _request) internal view {
        // tx.members
        address sender_ = msg.sender;
        uint256 now_ = block.timestamp;

        // request members
        string memory raiseId_ = _request.raiseId;

        // check replay attack
        uint256 nonce_ = _request.base.nonce;
        if (nonce_ <= LibNonce.getLastNonce(sender_)) {
            revert RequestErrors.NonceExpired(sender_, nonce_);
        }

        // check request expiration
        if (now_ > _request.base.expiry) {
            revert RequestErrors.RequestExpired(sender_, _request.base.expiry);
        }

        // verify sender
        if (sender_ != _request.base.sender) {
            revert RequestErrors.IncorrectSender(sender_);
        }

        // existence check
        if (!RaiseService.isRaiseExists(raiseId_)) {
            revert RaiseErrors.RaiseDoesNotExists(raiseId_);
        }

        // get base asset chain id
        uint256 baseAssetChainId_ = LibBaseAsset.getChainId(raiseId_);

        // validate if base asset is on the current chain
        if (baseAssetChainId_ != block.chainid) {
            revert CrossChainErrors.InvalidChainId(block.chainid, baseAssetChainId_);
        }

        // startup owner cannot invest
        if (sender_ == LibRaise.getOwner(raiseId_)) {
            revert RaiseErrors.OwnerCannotInvest(sender_, raiseId_);
        }

        // check if fundraising is active (in time)
        if (!RaiseService.isRaiseActive(raiseId_)) {
            revert RaiseErrors.RaiseNotActive(raiseId_, now_);
        }

        // verify amount + storage vs ticket size
        uint256 existingInvestment_ = LibInvestorFundsInfo.getInvested(raiseId_, sender_);
        if (existingInvestment_ + _request.investment > _request.maxTicketSize) {
            revert RaiseErrors.InvestmentOverLimit(existingInvestment_, _request.investment, _request.maxTicketSize);
        }

        // check if the investement does not make the total investment exceed the limit
        uint256 existingTotalInvestment_ = LibRaise.getRaised(raiseId_);
        uint256 hardcap_ = LibRaise.getHardcap(raiseId_);
        if (existingTotalInvestment_ + _request.investment > hardcap_) {
            revert RaiseErrors.InvestmentOverHardcap(existingTotalInvestment_, _request.investment, hardcap_);
        }
    }

    /// @dev Validate refund investment.
    /// @dev Validation: Validate raise, sender and ability to refund.
    /// @param _raiseId ID of raise
    function validateRefundInvestment(string memory _raiseId) internal view {
        // tx.members
        address sender_ = msg.sender;

        // check if raise exists
        if (!RaiseService.isRaiseExists(_raiseId)) {
            revert RaiseErrors.RaiseDoesNotExists(_raiseId);
        }

        // get base asset chain id
        uint256 baseAssetChainId_ = LibBaseAsset.getChainId(_raiseId);

        // validate if base asset is on the current chain
        if (baseAssetChainId_ != block.chainid) {
            revert CrossChainErrors.InvalidChainId(block.chainid, baseAssetChainId_);
        }

        // check if raise is finished already
        if (!RaiseService.isRaiseFinished(_raiseId)) {
            revert RaiseErrors.RaiseNotFinished(_raiseId);
        }

        // check if raise didn't reach softcap
        if (RaiseService.isSoftcapAchieved(_raiseId)) {
            revert RaiseErrors.SoftcapAchieved(_raiseId);
        }

        // check if user invested
        if (LibInvestorFundsInfo.getInvested(_raiseId, sender_) == 0) {
            revert RaiseErrors.UserHasNotInvested(sender_, _raiseId);
        }

        // check if already refunded
        if (LibInvestorFundsInfo.getInvestmentRefunded(_raiseId, sender_)) {
            revert RaiseErrors.InvestorAlreadyRefunded(sender_, _raiseId);
        }
    }

    /// @dev Diamond storage setter: investment.
    /// @param _raiseId ID of raise
    /// @param _investment Invested amount to save
    function saveInvestment(string memory _raiseId, uint256 _investment) internal {
        // tx.members
        address sender_ = msg.sender;

        // increase raised amount for raise
        LibRaise.increaseRaised(_raiseId, _investment);

        // increase invested amount for user
        LibInvestorFundsInfo.increaseInvested(_raiseId, sender_, _investment);
    }
}
