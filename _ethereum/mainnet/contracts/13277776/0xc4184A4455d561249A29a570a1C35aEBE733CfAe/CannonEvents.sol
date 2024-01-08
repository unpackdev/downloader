// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Nifty Cannon Events
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract CannonEvents {

    /**
     * @notice Event emitted upon successful storage of a will-call volley.
     * @param sender the sender of the volley
     * @param recipient the recipient of the volley
     * @param tokenContract the token contract that minted the NFTs
     * @param tokenIds the ids of NFTs that were transferred
     * @param amounts the corresponding amounts of tokens to be transferred (empty unless ERC-1155)
     */
    event VolleyStored(
        address indexed sender,
        address indexed recipient,
        address tokenContract,
        uint256[] tokenIds,
        uint256[] amounts
    );

    /**
     * @notice Event emitted upon successful transfer of a volley, via airdrop or pickup of a will-call.
     * @param sender the sender of the volley
     * @param recipient the recipient of the volley
     * @param tokenContract the token contract that minted the NFTs
     * @param amounts the corresponding amounts of tokens to be transferred (empty unless ERC-1155)
     */
    event VolleyTransferred(
        address indexed sender,
        address indexed recipient,
        address tokenContract,
        uint256[] tokenIds,
        uint256[] amounts
    );

    /**
     * @notice Event emitted upon successful storage and ticketing of a volley,
     * @param sender the sender of the volley
     * @param recipient the recipient of the ticket
     * @param ticketId the id of the transferable ticket
     * @param tokenContract the token contract that minted the NFTs
     * @param tokenIds the ids of tokens to be transferred
     * @param amounts the corresponding amounts of tokens to be transferred (empty unless ERC-1155)
     */
    event VolleyTicketed(
        address indexed sender,
        address indexed recipient,
        uint256 indexed ticketId,
        address tokenContract,
        uint256[] tokenIds,
        uint256[] amounts
    );


}