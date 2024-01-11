// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IWoolController {
    /**
     * @dev mint and distribute ALPA to caller
     * NOTE: caller must be approved user
     */
    function mint(address _to, uint256 _amount) external;

    /**
     * @dev burn `_amount` from `_from`
     * NOTE: caller must be approved user
     */
    function burn(address _from, uint256 _amount) external;
}
