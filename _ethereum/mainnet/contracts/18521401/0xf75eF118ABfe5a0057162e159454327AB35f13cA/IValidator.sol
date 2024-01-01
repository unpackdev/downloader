// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/**
 * @title Asymetrix Protocol V2 IValidator
 * @author Asymetrix Protocol Inc Team
 * @notice An interface that all validators should implement.
 */
interface IValidator {
    /**
     * @notice Validates if stake parameters are valid.
     * @param _pid Staking pool ID.
     * @param _amountOrId Amount of ERC-20 LP tokens or ID of ERC-721 NFT token to validate.
     */
    function validateStake(uint8 _pid, uint256 _amountOrId) external;
}
