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
import "./LibNonce.sol";
import "./RequestTypes.sol";
import "./RequestErrors.sol";

/**************************************

    Request library

**************************************/

library LibRequest {
    // -----------------------------------------------------------------------
    //                              Internal
    // -----------------------------------------------------------------------

    function validateBaseRequest(RequestTypes.BaseRequest memory _baseRequest) internal view {
        // tx.members
        address sender_ = msg.sender;
        uint256 now_ = block.timestamp;

        // check replay attack
        uint256 nonce_ = _baseRequest.nonce;
        if (nonce_ <= LibNonce.getLastNonce(sender_)) {
            revert RequestErrors.NonceExpired(sender_, nonce_);
        }

        // check request expiration
        if (now_ > _baseRequest.expiry) {
            revert RequestErrors.RequestExpired(sender_, _baseRequest.expiry);
        }

        // check request sender
        if (sender_ != _baseRequest.sender) {
            revert RequestErrors.IncorrectSender(sender_);
        }
    }
}
