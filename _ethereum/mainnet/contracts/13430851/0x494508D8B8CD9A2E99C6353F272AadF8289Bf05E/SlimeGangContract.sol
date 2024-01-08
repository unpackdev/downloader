// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;
import "./ERC721.sol";
import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";

import "./Mint.sol";
import "./Fields.sol";

/*
 * Dev by @_MrCode_
 *
 *
 * ░██████╗██╗░░░░░██╗███╗░░░███╗███████╗  ░██████╗░░█████╗░███╗░░██╗░██████╗░
 * ██╔════╝██║░░░░░██║████╗░████║██╔════╝  ██╔════╝░██╔══██╗████╗░██║██╔════╝░
 * ╚█████╗░██║░░░░░██║██╔████╔██║█████╗░░  ██║░░██╗░███████║██╔██╗██║██║░░██╗░
 * ░╚═══██╗██║░░░░░██║██║╚██╔╝██║██╔══╝░░  ██║░░╚██╗██╔══██║██║╚████║██║░░╚██╗
 * ██████╔╝███████╗██║██║░╚═╝░██║███████╗  ╚██████╔╝██║░░██║██║░╚███║╚██████╔╝
 * ╚═════╝░╚══════╝╚═╝╚═╝░░░░░╚═╝╚══════╝  ░╚═════╝░╚═╝░░╚═╝╚═╝░░╚══╝░╚═════╝░
 *
 */

contract SlimeGangContract is MintWhitelist {
    /// @notice constructor
    constructor(
        address[] memory receiverAddresses_,
        uint256[] memory receiverPercentages_,
        address[] memory royaltyReceiverAddresses_,
        uint256[] memory royaltyReceiverPercentages_,
        IDepositor depositor_
    ) ERC721("Slime Gang", "SLIME") {
        receiverAddresses = receiverAddresses_;
        receiverPercentages = receiverPercentages_;
        for (uint8 i = 0; i < receiverAddresses_.length; i++) {
            addressToIndex[receiverAddresses_[i]] = i + 1;
        }
        royaltyReceiverAddresses = royaltyReceiverAddresses_;
        royaltyReceiverPercentages = royaltyReceiverPercentages_;
        for (uint8 i = 0; i < royaltyReceiverAddresses_.length; i++) {
            addressRoyaltyToIndex[royaltyReceiverAddresses_[i]] = i + 1;
        }

        depositor = depositor_;
        indexStorage = IndexStorage(0, new uint16[](MAX_TOKENS));
        currentTeamBalance = new uint256[](receiverAddresses_.length);
        currentTeamRoyalty = new uint256[](royaltyReceiverAddresses_.length);
        royaltyStages.push(RoyaltyStage(block.timestamp, 0, 0));

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(type(IERC721).interfaceId);
        _registerInterface(type(IERC721Metadata).interfaceId);
        _registerInterface(type(IERC721Enumerable).interfaceId);
    }
}
