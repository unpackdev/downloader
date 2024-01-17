// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @author ishan@highlight.xyz
 * @dev If token managers implement this, transfer actions will call
 *      postBurn on the token manager.
 */
interface IPostBurn {
    /**
     * @dev Hook called by contract after burn, if token manager of burned token implements this
     *      interface.
     * @param operator Operator burning tokens
     * @param sender Msg sender
     * @param id Burned token's id
     */
    function postBurn(
        address operator,
        address sender,
        uint256 id
    ) external;
}
