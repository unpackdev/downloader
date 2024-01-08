// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;
import "./ERC721.sol";
import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";

import "./Mint.sol";

/*
 * Dev by @_MrCode_
 *
 *
 * ██╗░░░░░░█████╗░░██████╗  ██╗░░░██╗███████╗░██████╗░░█████╗░░██████╗
 * ██║░░░░░██╔══██╗██╔════╝  ██║░░░██║██╔════╝██╔════╝░██╔══██╗██╔════╝
 * ██║░░░░░███████║╚█████╗░  ╚██╗░██╔╝█████╗░░██║░░██╗░███████║╚█████╗░
 * ██║░░░░░██╔══██║░╚═══██╗  ░╚████╔╝░██╔══╝░░██║░░╚██╗██╔══██║░╚═══██╗
 * ███████╗██║░░██║██████╔╝  ░░╚██╔╝░░███████╗╚██████╔╝██║░░██║██████╔╝
 * ╚══════╝╚═╝░░╚═╝╚═════╝░  ░░░╚═╝░░░╚══════╝░╚═════╝░╚═╝░░╚═╝╚═════╝░
 *
 * ██╗███╗░░██╗███████╗███████╗██████╗░███╗░░██╗░█████╗░  ██████╗░███████╗░█████╗░██████╗░███████╗██████╗░░██████╗
 * ██║████╗░██║██╔════╝██╔════╝██╔══██╗████╗░██║██╔══██╗  ██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔════╝
 * ██║██╔██╗██║█████╗░░█████╗░░██████╔╝██╔██╗██║██║░░██║  ██████╔╝█████╗░░███████║██████╔╝█████╗░░██████╔╝╚█████╗░
 * ██║██║╚████║██╔══╝░░██╔══╝░░██╔══██╗██║╚████║██║░░██║  ██╔══██╗██╔══╝░░██╔══██║██╔═══╝░██╔══╝░░██╔══██╗░╚═══██╗
 * ██║██║░╚███║██║░░░░░███████╗██║░░██║██║░╚███║╚█████╔╝  ██║░░██║███████╗██║░░██║██║░░░░░███████╗██║░░██║██████╔╝
 * ╚═╝╚═╝░░╚══╝╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░  ╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═════╝░
 *
 */

contract VegasReapersContract is MintWhitelist {
    /// @notice constructor
    constructor(
        address[5] memory receiverAddresses_,
        uint256[5] memory receiverPercentages_,
        uint256 firstPaymentRemaining_
    ) ERC721("Vegas Reapers", "VGS") {
        firstPaymentRemaining = firstPaymentRemaining_;

        receiverAddresses = receiverAddresses_;
        receiverPercentages = receiverPercentages_;
        for (uint8 i = 0; i < receiverAddresses_.length; i++) {
            addressToIndex[receiverAddresses_[i]] = i + 1;
        }

        royaltyStages.push(RoyaltyStage(block.timestamp, 0, 0, 0, 0));

        // reserve first 1 tokens for the team
        for (uint256 tokenId = 1; tokenId <= 11; tokenId++) {
            setTokenId(tokenId);
        }

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(type(IERC721).interfaceId);
        _registerInterface(type(IERC721Metadata).interfaceId);
        _registerInterface(type(IERC721Enumerable).interfaceId);
    }
}
