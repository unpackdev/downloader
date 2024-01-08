// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEgg {
    /**
     * mints $EGG to a recipient
     * @param to the recipient of the $EGG
     * @param amount the amount of $EGG to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * burns $EGG from a holder
     * @param from the holder of the $EGG
     * @param amount the amount of $EGG to burn
     */
    function burn(address from, uint256 amount) external;
}
