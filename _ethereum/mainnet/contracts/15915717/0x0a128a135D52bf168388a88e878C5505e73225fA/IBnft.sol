// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Burnable.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBnft {
    //
    function mintToUser(address user) external returns (uint256);

    //
    function burnFromUser(address user) external returns (uint256);
}
