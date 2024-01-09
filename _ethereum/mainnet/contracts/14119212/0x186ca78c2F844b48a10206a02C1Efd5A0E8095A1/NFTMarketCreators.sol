// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "./ICRNFT721.sol";

import "./Ownable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC165Checker.sol";

import "./Constants.sol";

/**
 * @notice A mixin for associating creators to NFTs.
 * @dev In the future this may store creators directly in order to support NFTs created on a different platform.
 */
abstract contract NFTMarketCreators is
Constants,
ReentrancyGuardUpgradeable // Adding this unused mixin to help with linearization
{
    using ERC165Checker for address;

    /**
     * @dev Returns the destination address for any payments to the creator,
   * or address(0) if the destination is unknown.
   * It also checks if the current seller is the creator for isPrimary checks.
   */
    // solhint-disable-next-line code-complexity
    function _getCreatorPaymentInfo(
        address nftContract,
        uint256 tokenId,
        address seller
    )
    internal
    view
    returns (
        address payable[] memory recipients,
        uint256[] memory splitPerRecipientInBasisPoints,
        bool isCreator
    )
    {
        // All NFTs implement 165 so we skip that check, individual interfaces should return false if 165 is not implemented

        //tokenCreator w/o requiring 165
        try ICRNFT721(nftContract).tokenCreator{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (address payable _creator) {
            if (_creator != address(0)) {
                if (recipients.length == 0) {
                    // Only pay the tokenCreator if there wasn't a tokenCreatorPaymentAddress defined
                    recipients = new address payable[](1);
                    recipients[0] = _creator;
                }
                // splitPerRecipientInBasisPoints is not relevant when only 1 recipient is defined
                return (recipients, splitPerRecipientInBasisPoints, _creator == seller);
            }
        } catch // solhint-disable-next-line no-empty-blocks
        {
            // Fall through
        }

        // If no valid payment address or creator is found, return 0 recipients
    }

    // 500 slots were added via the new SendValueWithFallbackWithdraw mixin
    uint256[500] private ______gap;
}