// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title Swap Proxy contract
 * @author Pino development team
 * @notice Swaps tokens and send the new token to the recipient
 */
interface ISwap {
    /**
     * @notice Throws when the call to the 0x protocol fails
     * @param _caller Address of the caller of the transaction
     */
    error FailedToSwapUsingZeroX(address _caller);

    /**
     * @notice Throws when the call to the 1Inch protocol fails
     * @param _caller Address of the caller of the transaction
     */
    error FailedToSwapUsingOneInch(address _caller);

    /**
     * @notice Throws when the call to the ParaSwap protocol fails
     * @param _caller Address of the caller of the transaction
     */
    error FailedToSwapUsingParaSwap(address _caller);

    /**
     * @notice Swaps using 0x protocol
     * @param _calldata 0x protocol calldata from API
     */
    function swapZeroX(bytes calldata _calldata) external payable;

    /**
     * @notice Swaps using 1Inch protocol
     * @param _calldata 1Inch protocol calldata from API
     */
    function swapOneInch(bytes calldata _calldata) external payable;

    /**
     * @notice Swaps using ParaSwap protocol
     * @param _calldata ParaSwap protocol calldata from API
     */
    function swapParaSwap(bytes calldata _calldata) external payable;
}
