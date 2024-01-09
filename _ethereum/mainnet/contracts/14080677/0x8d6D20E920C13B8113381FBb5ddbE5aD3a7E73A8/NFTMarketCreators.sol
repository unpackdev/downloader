// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./IBLSNFT721.sol";

import "./ReentrancyGuardUpgradeable.sol";

/**
 * @notice A mixin for associating creators to NFTs.
 * @dev In the future this may store creators directly in order to support NFTs created on a different platform.
 */
abstract contract NFTMarketCreators is
    ReentrancyGuardUpgradeable // Adding this unused mixin to help with linearization
{
    /**
     * @dev If the creator is not available then 0x0 is returned. Downstream this indicates that the creator
     * fee should be sent to the current seller instead.
     * This may apply when selling NFTs that were not minted on Blocksport.
     */
    function _getCreator(address nftContract, uint256 tokenId)
        internal
        view
        returns (address payable)
    {
        try IBLSNFT721(nftContract).tokenCreator(tokenId) returns (
            address payable creator
        ) {
            return creator;
        } catch {
            return payable(address(0));
        }
    }

    /**
     * @dev Returns the creator and a destination address for any payments to the creator,
     * returns address(0) if the creator is unknown.
     */
    function _getCreatorAndPaymentAddress(address nftContract, uint256 tokenId)
        internal
        view
        returns (address payable, address payable)
    {
        address payable creator = _getCreator(nftContract, tokenId);
        try
            IBLSNFT721(nftContract).getTokenCreatorPaymentAddress(tokenId)
        returns (address payable tokenCreatorPaymentAddress) {
            if (tokenCreatorPaymentAddress != address(0)) {
                return (creator, tokenCreatorPaymentAddress);
            }
        } catch // solhint-disable-next-line no-empty-blocks
        {
            // Fall through to return (creator, creator) below
        }
        return (creator, creator);
    }

    // 500 slots were added via the new SendValueWithFallbackWithdraw mixin
    uint256[500] private ______gap;
}
