// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "./Initializable.sol";
import "./Ownable.sol";
import "./ERC165Storage.sol";

import "./Address.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./IERC721.sol";

import "./ERC721MultiTokenStream.sol";

interface IERC721InstantReleaseExtension {
    function hasERC721InstantReleaseExtension() external view returns (bool);
}

abstract contract ERC721InstantReleaseExtension is
    IERC721InstantReleaseExtension,
    Initializable,
    ERC165Storage,
    Ownable,
    ERC721MultiTokenStream
{
    /* INIT */

    function __ERC721InstantReleaseExtension_init() internal onlyInitializing {
        __ERC721InstantReleaseExtension_init_unchained();
    }

    function __ERC721InstantReleaseExtension_init_unchained()
        internal
        onlyInitializing
    {
        _registerInterface(type(IERC721InstantReleaseExtension).interfaceId);
    }

    /* PUBLIC */

    function hasERC721InstantReleaseExtension() external pure returns (bool) {
        return true;
    }

    /* INTERNAL */

    function _totalReleasedAmount(
        uint256 streamTotalSupply_,
        uint256 ticketTokenId_,
        address claimToken_
    ) internal pure override returns (uint256) {
        ticketTokenId_;
        claimToken_;

        return streamTotalSupply_;
    }
}
