// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "./Initializable.sol";
import "./Ownable.sol";

import "./Address.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./IERC721.sol";

import "./WithdrawExtension.sol";
import "./ERC721InstantReleaseExtension.sol";
import "./ERC721EqualSplitExtension.sol";
import "./ERC721LockableClaimExtension.sol";

contract ERC721EqualInstantStream is
    Initializable,
    Ownable,
    ERC721InstantReleaseExtension,
    ERC721EqualSplitExtension,
    ERC721LockableClaimExtension,
    WithdrawExtension
{
    string public constant name = "ERC721 Equal Instant Stream";

    string public constant version = "0.1";

    struct Config {
        // Base
        address ticketToken;
        uint64 lockedUntilTimestamp;
        // Equal split extension
        uint256 totalTickets;
        // Lockable claim extension
        uint64 claimLockedUntil;
    }

    /* INTERNAL */

    constructor(Config memory config) {
        initialize(config, msg.sender);
    }

    function initialize(Config memory config, address deployer)
        public
        initializer
    {
        _transferOwnership(deployer);

        __WithdrawExtension_init(deployer, WithdrawMode.OWNER);
        __ERC721MultiTokenStream_init(
            config.ticketToken,
            config.lockedUntilTimestamp
        );
        __ERC721EqualSplitExtension_init(config.totalTickets);
        __ERC721LockableClaimExtension_init(config.claimLockedUntil);
    }

    function _beforeClaim(
        uint256 ticketTokenId_,
        address claimToken_,
        address beneficiary_
    ) internal override(ERC721MultiTokenStream, ERC721LockableClaimExtension) {
        ERC721MultiTokenStream._beforeClaim(
            ticketTokenId_,
            claimToken_,
            beneficiary_
        );
        ERC721LockableClaimExtension._beforeClaim(
            ticketTokenId_,
            claimToken_,
            beneficiary_
        );
    }
}
