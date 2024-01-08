// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CannonEvents.sol";
import "./CannonTicket.sol";
import "./IERC1155.sol";

/**
 * @title Nifty Cannon Activity
 *
 * @dev Volley activities associated with airdrop, will-call, and ticket modes
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract CannonActivity is CannonTicket, CannonEvents {

    /**
     * @notice Process a Volley
     * This is the Cannon's central transfer mechanism.
     * It has three operating modes: Airdrop and Will-call.
     * In Airdrop mode, all of the NFTs in the Volley will be transferred to the recipient, sender paying gas.
     * In Will-call mode, the volley will be stored, to be later executed by the recipient, who pays the gas.
     * In Ticket mode, a transferable ticket NFT will be created and sent to the recipient's wallet.
     * This contract must already be approved as an operator for the NFTs specified in the Volley.
     * @param _volley a valid Volley struct
     */
    function processVolley(Volley memory _volley) internal {

        // Destructure volley props
        Mode mode = _volley.mode;
        address sender = _volley.sender;
        address recipient = _volley.recipient;
        uint256[] memory tokenIds = _volley.tokenIds;
        uint256[] memory amounts = _volley.amounts;
        address tokenContract = _volley.tokenContract;

        // Possible token contract interfaces
        IERC721 singleTokenContract = IERC721(tokenContract);
        IERC1155 multiTokenContract = IERC1155(tokenContract);

        // For determining which interface to use
        bool isMultiToken = amounts.length == tokenIds.length;

        // Ensure this contract is an approved operator for the NFTs (same on both interfaces)
        require(singleTokenContract.isApprovedForAll(sender, address(this)), "Nifty Cannon not approved to transfer sender's NFTs" );

        // Handle the volley
        if (mode == Mode.AIRDROP) {

            if (isMultiToken && tokenIds.length > 1) {

                // The one case when we can use batch transfer rather than iterating
                multiTokenContract.safeBatchTransferFrom(sender, recipient, tokenIds, amounts, "");

            } else {

                require(tokenIds.length == amounts.length || amounts.length == 0, "Mismatch of token ids and amounts");

                // Iterate over the NFTs to be transferred
                for (uint256 index = 0; index < tokenIds.length; index++) {

                    // Get the current token id
                    uint256 token = tokenIds[index];

                    // Sender pays gas to transfer token directly to recipient wallet
                    if (isMultiToken) {
                        uint256 amount = amounts[index];
                        multiTokenContract.safeTransferFrom(sender, recipient, token, amount, "");
                    } else {
                        singleTokenContract.safeTransferFrom(sender, recipient, token);
                    }

                }

            }

            // Emit VolleyTransferred event
            emit VolleyTransferred(sender, recipient, tokenContract, tokenIds, amounts);

        } else if (mode == Mode.WILLCALL) {

            // Store the volley for the recipient to pickup later
            willCallVolleys[recipient].push(_volley);

            // Emit VolleyTransferred event
            emit VolleyStored(sender, recipient, tokenContract, tokenIds, amounts);

        } else if (mode == Mode.TICKET) {

            // Mint a transferable ticket
            uint256 ticketId = mintTicket(recipient);
            Ticket memory ticket = Ticket(sender, tokenContract, ticketId, tokenIds, amounts);
            transferableTickets[ticketId] = ticket;

            // Emit VolleyTicketed event
            emit VolleyTicketed(sender, recipient, ticketId, tokenContract, tokenIds, amounts);

        }

    }

}