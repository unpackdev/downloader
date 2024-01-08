// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
interface RecoverableInterface {

    /**
     * @dev Recovers `amount` of ERC20 `token` sent to the contract.
     */
    function recover(IERC20 token, uint256 amount) external;

}