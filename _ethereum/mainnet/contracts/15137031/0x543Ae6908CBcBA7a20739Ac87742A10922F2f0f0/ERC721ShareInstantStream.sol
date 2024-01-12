// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "./Initializable.sol";
import "./Ownable.sol";

import "./Address.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./IERC721.sol";

import "./ERC721InstantReleaseExtension.sol";
import "./ERC721ShareSplitExtension.sol";

contract ERC721ShareInstantStream is
    Initializable,
    Ownable,
    ERC721InstantReleaseExtension,
    ERC721ShareSplitExtension
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

        __ERC721MultiTokenStream_init(
            config.ticketToken,
            config.lockedUntilTimestamp
        );
        __ERC721InstantReleaseExtension_init();
        __ERC721ShareSplitExtension_init(config.tokenIds, config.shares);
    }
}
