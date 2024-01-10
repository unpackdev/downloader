// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./SeenTypes.sol";
import "./IMarketHandler.sol";

/**
 * @title ISaleBuilder
 *
 * @notice Handles the creation of Seen.Haus sales.
 *
 * The ERC-165 identifier for this interface is: 0x4811411a
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
interface ISaleBuilder is IMarketHandler {

    // Events
    event SalePending(address indexed consignor, address indexed seller, SeenTypes.Sale sale);

    /**
     * @notice The sale getter
     */
    function getSale(uint256 _consignmentId) external view returns (SeenTypes.Sale memory);

    /**
     * @notice Create a new sale.
     *
     * For some lot size of one ERC-1155 token.
     *
     * Ownership of the consigned inventory is transferred to this contract
     * for the duration of the sale.
     *
     * Reverts if:
     *  - Sale exists for consignment
     *  - Consignment has already been marketed
     *  - Sale start is zero
     *
     * Emits a SalePending event.
     *
     * @param _consignmentId - id of the consignment being sold
     * @param _start - the scheduled start time of the sale
     * @param _price - the price of each item in the lot
     * @param _perTxCap - the maximum amount that can be bought in a single transaction
     * @param _audience - the initial audience that can participate. See {SeenTypes.Audience}
     */
    function createPrimarySale (
        uint256 _consignmentId,
        uint256 _start,
        uint256 _price,
        uint256 _perTxCap,
        SeenTypes.Audience _audience
    ) external;

    /**
     * @notice Create a new sale.
     *
     * For some lot size of one ERC-1155 token.
     *
     * Ownership of the consigned inventory is transferred to this contract
     * for the duration of the sale.
     *
     * Reverts if:
     *  - Sale exists for consignment
     *  - Sale start is zero
     *  - This contract isn't approved to transfer seller's tokens
     *
     * Emits a SalePending event.
     *
     * @param _seller - the current owner of the consignment
     * @param _tokenAddress - the contract address issuing the NFT behind the consignment
     * @param _tokenId - the id of the token being consigned
     * @param _start - the scheduled start time of the sale
     * @param _supply - the supply of the given consigned token being sold
     * @param _price - the price of each item in the lot
     * @param _perTxCap - the maximum amount that can be bought in a single transaction
     * @param _audience - the initial audience that can participate. See {SeenTypes.Audience}
     */
    function createSecondarySale (
        address payable _seller,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _start,
        uint256 _supply,
        uint256 _price,
        uint256 _perTxCap,
        SeenTypes.Audience _audience
    ) external;

}