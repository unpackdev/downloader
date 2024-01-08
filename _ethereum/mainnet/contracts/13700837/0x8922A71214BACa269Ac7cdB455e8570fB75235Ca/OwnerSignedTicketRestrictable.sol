//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ECDSA.sol";

/**
 * @dev Implements a mixin that uses ECDSA cryptography to restrict token minting to "ticket"-holders.
 *      This allows off-chain, gasless allowlisting of minting.
 * 
 * A "Ticket" is a logical tuple of:
 *   - the Token ID
 *   - the address of a minter
 *   - the address of the token contract
 *   - a ticket ID (random number)
 * 
 * By signing this tuple, the owner of the contract can grant permission to a specific address
 * to mint a specific token ID at that specific token contract.
 */
abstract contract OwnerSignedTicketRestrictable is Ownable {
    // Mapping to enable (very basic) ticket revocation
    mapping (uint256 => bool) private _revokedTickets;

    /**
     * @dev Throws if the given signature, signed by the contract owner, does not grant
     *      the transaction sender a ticket to mint the given tokenId
     * @param tokenId the ID of the token to check
     * @param ticketId the ID of the ticket (included in signature)
     * @param signature the bytes of the signature to use for verification
     * 
     * This delegates straight into the checkTicket public function.
     */
    modifier onlyWithTicketFor(uint256 tokenId, uint256 ticketId, bytes memory signature) {
        checkTicket(msg.sender, tokenId, ticketId, signature);
        _;
    }

    /**
     * @notice Check the validity of a signature
     * @dev Throws if the given signature wasn't signed by the contract owner for the
     *      "ticket" described by address(this) and the passed parameters
     *      (or if the ticket ID is revoked)
     * @param minter the address of the minter in the ticket
     * @param tokenId the token ID of the ticket
     * @param ticketId the ticket ID
     * @param signature the bytes of the signature
     * 
     * Reuse of a ticket is prevented by existing controls preventing double-minting.
     */
    function checkTicket(
        address minter,
        uint256 tokenId,
        uint256 ticketId,
        bytes memory signature
    ) public view {
        bytes memory params = abi.encode(
            address(this),
            minter,
            tokenId,
            ticketId
        );
        address addr = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(keccak256(params)),
            signature
        );

        require(addr == owner(), "BAD_SIGNATURE");
        require(!_revokedTickets[ticketId], "TICKET_REVOKED");
    }

    /**
     * @notice Revokes the given ticket IDs, preventing them from being used in the future
     * @param ticketIds the ticket IDs to revoke
     * @dev This can do nothing if the ticket ID has already been used, but
     *      this function gives an escape hatch for accidents, etc.
     */
    function revokeTickets(uint256[] calldata ticketIds) public onlyOwner {
        for (uint i=0; i<ticketIds.length; i++) {
            _revokedTickets[ticketIds[i]] = true;
        }
    }
}
