// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IMoonCatAcclimator {
    /**
     * @dev rewrap several MoonCats from the old wrapper at once
     * Owner needs to call setApprovalForAll in old wrapper first.
     * @param _rescueOrders an array of MoonCats, identified by rescue order, to rewrap
     * @param _oldTokenIds an array holding the corresponding token ID
     *        in the old wrapper for each MoonCat to be rewrapped
     */
    function batchReWrap(
        uint256[] memory _rescueOrders,
        uint256[] memory _oldTokenIds
    ) external;

    /**
     * @dev Take a list of unwrapped MoonCat rescue orders and wrap them.
     * @param _rescueOrders an array of MoonCats, identified by rescue order, to rewrap
     */
    function batchWrap(uint256[] memory _rescueOrders) external;

    /**
     * @dev Take a list of MoonCats wrapped in this contract and unwrap them.
     * @param _rescueOrders an array of MoonCats, identified by rescue order, to unwrap
     */
    function batchUnwrap(uint256[] memory _rescueOrders) external;
}

