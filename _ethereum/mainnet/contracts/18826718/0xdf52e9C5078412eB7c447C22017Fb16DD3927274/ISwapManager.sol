// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
* @title Interface defining a swap manager, a contract that can exchange currencies
*/
interface ISwapManager {
    /**
    * @notice Swaps one currency for another
    * @param srcToken The address of the token to be exchanged
    * @param dstToken The address of the token to be exchanged for
    * @param amount the amount of src token to exchange
    * @param destination The recipient of the funds after the exchange
    */
    function swap(
        address srcToken,
        address dstToken,
        uint256 amount,
        address destination
    ) external payable;
}
