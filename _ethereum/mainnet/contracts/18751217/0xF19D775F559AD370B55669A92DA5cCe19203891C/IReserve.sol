// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./IBucket.sol";
import "./IPrimexDNS.sol";
import "./IReserveStorage.sol";
import "./IPausable.sol";

interface IReserve is IReserveStorage, IPausable {
    event BurnAmountCalculated(uint256 burnAmount);
    event TransferRestrictionsChanged(address indexed pToken, TransferRestrictions newTransferRestrictions);

    /**
     * @dev contract initializer
     * @param dns The address of PrimexDNS contract
     * @param registry The address of Registry contract
     */
    function initialize(IPrimexDNS dns, address registry) external;

    /**
     * @dev Burns the permanent loss amount (presented in pTokens) from the Reserve for a particular bucket
     * @param bucket The address of a bucket
     * Emits BurnAmountCalculated(burnAmount) event
     */
    function paybackPermanentLoss(IBucket bucket) external;

    /**
     * @dev Transfers some bonus in pTokens to receiver from Reserve
     * Can be called by executor only
     * @param _bucketName The bucket where the msg.sender should be a fee decreaser (for debtToken) or
     * interest increaser (for pToken)
     * @param _to The receiver of bonus pTokens
     * @param _amount The amount of bonus pTokens to transfer
     */
    function payBonus(string memory _bucketName, address _to, uint256 _amount) external;

    /**
     * @dev Function to transfer tokens to the Treasury. Only BIG_TIMELOCK_ADMIN can call it.
     * @param bucket The bucket from which to transfer pTokens
     * @param amount The amount of pTokens to transfer
     */
    function transferToTreasury(address bucket, uint256 amount) external;

    /**
     * @dev Function to set transfer restrictions for a token.
     * @notice Only BIG_TIMELOCK_ADMIN can call it.
     * @param pToken pToken to set restrictions for
     * @param transferRestrictions Min amount to be left in the Reserve
     */
    function setTransferRestrictions(address pToken, TransferRestrictions calldata transferRestrictions) external;
}
