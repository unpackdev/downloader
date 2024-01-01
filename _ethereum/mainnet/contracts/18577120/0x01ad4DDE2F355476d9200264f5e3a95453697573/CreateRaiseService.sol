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
import "./RequestErrors.sol";
import "./RequestTypes.sol";
import "./RaiseService.sol";

library CreateRaiseService {
    /// @dev Validate create raise request.
    /// @param _request RequestTypes.CreateRaiseRequest struct
    function validateCreateRaiseRequest(RequestTypes.CreateRaiseRequest calldata _request) internal view {
        // tx.members
        address sender_ = msg.sender;
        uint256 now_ = block.timestamp;

        // check replay attack
        uint256 nonce_ = _request.base.nonce;

        // check request expiration
        if (now_ > _request.base.expiry) {
            revert RequestErrors.RequestExpired(sender_, _request.base.expiry);
        }

        // check request sender
        if (sender_ != _request.base.sender) {
            revert RequestErrors.IncorrectSender(sender_);
        }

        RaiseService.validateCreationRequest(_request.raise, _request.raiseDetails, _request.erc20Asset, sender_, nonce_);
    }
}
