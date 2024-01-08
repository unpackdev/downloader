// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.4;

/**
 * @author Asaf Silman
 * @title FeeDistributor Interface
 * @notice Interface for a FeeDistributor based on curve.finance implementation.
 * @dev This is a minimal implementation of the interface in solidity to implement and test the feeExchanger
 */
interface IFeeDistributor {
    event CheckpointToken(uint256 time, uint256 tokens);

    function checkpoint_token() external;
    function burn(address) external;

    function toggle_allow_checkpoint_token() external;
    function can_checkpoint_token() external returns (bool);
    function token_last_balance() external returns (uint256);
}
