// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IFlashBorrower.sol";

interface IFlashLender {
    /**
     * @dev The fee to be charged for a given loan.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IFlashBorrower receiver,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}
