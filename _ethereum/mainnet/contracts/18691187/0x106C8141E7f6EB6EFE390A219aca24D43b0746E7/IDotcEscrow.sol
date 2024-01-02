//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

import "./IDotcManager.sol";
import "./DotcStructures.sol";

/**
 * @title Interface for Dotc Escrow contract (as part of the "SwarmX.eth Protocol")
 * @notice This interface is implemented by the Escrow contract in the DOTC trading system
 * to handle asset custody during trades.
 * ////////////////DISCLAIMER////////////////DISCLAIMER////////////////DISCLAIMER////////////////
 * Please read the Disclaimer featured on the SwarmX.eth website ("Terms") carefully before accessing,
 * interacting with, or using the SwarmX.eth Protocol software, consisting of the SwarmX.eth Protocol
 * technology stack (in particular its smart contracts) as well as any other SwarmX.eth technology such
 * as e.g., the launch kit for frontend operators (together the "SwarmX.eth Protocol Software").
 * By using any part of the SwarmX.eth Protocol you agree (1) to the Terms and acknowledge that you are
 * aware of the existing risk and knowingly accept it, (2) that you have read, understood and accept the
 * legal information and terms of service and privacy note presented in the Terms, and (3) that you are
 * neither a US person nor a person subject to international sanctions (in particular as imposed by the
 * European Union, Switzerland, the United Nations, as well as the USA). If you do not meet these
 * requirements, please refrain from using the SwarmX.eth Protocol.
 * ////////////////DISCLAIMER////////////////DISCLAIMER////////////////DISCLAIMER////////////////
 * @dev Defines the interface for the Dotc Escrow contract, outlining the key functionalities
 * for managing asset deposits and withdrawals.
 * @author Swarm
 */
interface IDotcEscrow {
    /**
     * @notice Sets the initial deposit of an asset by the maker for a specific offer.
     * @dev Stores the asset deposited by the maker in the escrow for a given offer.
     * REQUIRE: The sender must have the ESCROW_MANAGER_ROLE and the DOTC_ADMIN_ROLE.
     * @param offerId The ID of the offer for which the deposit is being made.
     * @param maker The address of the offer's maker.
     * @param asset The asset being deposited.
     * @return bool True if the deposit is successfully set.
     */
    function setDeposit(uint offerId, address maker, Asset calldata asset) external returns (bool);

    /**
     * @notice Withdraws a deposited asset from the escrow to the taker's address.
     * @dev Handles the transfer of assets from escrow to the taker upon successful trade.
     * REQUIRE: The sender must have the ESCROW_MANAGER_ROLE and the DOTC_ADMIN_ROLE.
     * @param offerId The ID of the offer for which the withdrawal is being made.
     * @param amountToWithdraw The amount of the asset to be withdrawn.
     * @param taker The address of the taker to receive the withdrawn assets.
     * @return True if the withdrawal is successful.
     */
    function withdrawDeposit(uint256 offerId, uint256 amountToWithdraw, address taker) external returns (bool);

    /**
     * @notice Cancels a deposit in the escrow, returning the assets to the maker.
     * @dev Reverses the asset deposit, sending the assets back to the maker of the offer.
     * REQUIRE The sender must have the ESCROW_MANAGER_ROLE and the DOTC_ADMIN_ROLE.
     * @param offerId The ID of the offer for which the deposit is being cancelled.
     * @param maker The address of the offer's maker.
     * @return status True if the cancellation is successful.
     * @return amountToWithdraw The amount of assets returned to the maker.
     */
    function cancelDeposit(uint256 offerId, address maker) external returns (bool status, uint256 amountToWithdraw);

    /**
     * @notice Withdraws fees from the escrow.
     * @dev Handles the transfer of fee amounts from escrow to the designated fee receiver.
     * @param offerId The ID of the offer related to the fees.
     * @param amountToWithdraw The amount of fees to be withdrawn.
     * @return status True if the fee withdrawal is successful.
     */
    function withdrawFees(uint256 offerId, uint256 amountToWithdraw) external returns (bool status);

    /**
     * @notice Changes the manager of the escrow contract.
     * @dev Updates the DotcManager address linked to the escrow contract.
     * @param _manager The new manager's address to be set.
     * @return status True if the manager is successfully changed.
     */
    function changeManager(IDotcManager _manager) external returns (bool status);
}
