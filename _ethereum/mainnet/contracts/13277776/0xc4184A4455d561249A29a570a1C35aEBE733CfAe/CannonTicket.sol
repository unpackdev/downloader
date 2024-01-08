// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CannonState.sol";
import "./ERC721Enumerable.sol";

/**
 * @title Nifty Cannon Transferable Ticket Factory
 *
 * @notice Manages the Cannon-native NFTs that represent transferable tickets.
 * Only the current holder of a ticket can claim the associated nifties.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract CannonTicket is ERC721Enumerable, CannonState {

    constructor() ERC721(TOKEN_NAME, TOKEN_SYMBOL) {}

    string public constant TICKET_URI = "ipfs://QmdEkQjAXJAjPZtJFzJZJPxnBtu2FsoDGfH7EofA5sc6vT";
    string public constant TOKEN_NAME = "Nifty Cannon Transferable Ticket";
    string public constant TOKEN_SYMBOL = "FODDER";

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return TICKET_URI;
    }

    /**
     * Mint a ticket
     * @param _owner the address that will own the ticket
     * @return ticketId the token id of the ticket
     */
    function mintTicket(address _owner)
    internal
    returns (uint256 ticketId) {
        ticketId = nextTicketNumber;
        nextTicketNumber = nextTicketNumber + 1;
        _mint(_owner, ticketId);
        return ticketId;
    }

    /**
     * Burn a ticket
     * @param _ticketId the ticket to burn
     */
    function burnTicket(uint256 _ticketId)
    internal
    {
        _burn(_ticketId);
    }

}