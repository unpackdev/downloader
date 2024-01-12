// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "./Initializable.sol";
import "./Ownable.sol";

import "./Address.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./IERC721.sol";

import "./EmergencyOwnerWithdrawExtension.sol";
import "./ERC721InstantReleaseExtension.sol";
import "./ERC721ShareSplitExtension.sol";
import "./ERC721LockableClaimExtension.sol";

contract ERC721ShareInstantStream is
    Initializable,
    Ownable,
    EmergencyOwnerWithdrawExtension,
    ERC721InstantReleaseExtension,
    ERC721ShareSplitExtension,
    ERC721LockableClaimExtension
{
    string public constant name = "ERC721 Share Instant Stream";

    string public constant version = "0.1";

    struct Config {
        // Base
        address ticketToken;
        uint64 lockedUntilTimestamp;
        // Share split extension
        uint256[] tokenIds;
        uint256[] shares;
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

        __EmergencyOwnerWithdrawExtension_init();
        __ERC721MultiTokenStream_init(
            config.ticketToken,
            config.lockedUntilTimestamp
        );
        __ERC721InstantReleaseExtension_init();
        __ERC721ShareSplitExtension_init(config.tokenIds, config.shares);
        __ERC721LockableClaimExtension_init(config.claimLockedUntil);
    }

    function _beforeClaim(
        uint256 ticketTokenId_,
        address claimToken_,
        address owner_
    ) internal override(ERC721MultiTokenStream, ERC721LockableClaimExtension) {
        ERC721LockableClaimExtension._beforeClaim(
            ticketTokenId_,
            claimToken_,
            owner_
        );
    }
}
