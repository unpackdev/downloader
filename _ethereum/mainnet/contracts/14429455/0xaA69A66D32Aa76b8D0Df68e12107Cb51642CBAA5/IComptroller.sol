// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ICErc20.sol";

interface IComptroller {
    /**
     * @notice Claim all the comp accrued by the holder in all markets.
     *
     * @param holder The address to claim COMP for
     */
    function claimComp(address holder) external;

    /**
     * @notice Claim all comp accrued by the holders
     * @param holders The addresses to claim COMP for
     * @param cTokens The list of markets to claim COMP in
     * @param borrowers Whether or not to claim COMP earned by borrowing
     * @param suppliers Whether or not to claim COMP earned by supplying
     */
    function claimComp(
        address[] memory holders,
        ICErc20[] memory cTokens,
        bool borrowers,
        bool suppliers
    ) external;
}
