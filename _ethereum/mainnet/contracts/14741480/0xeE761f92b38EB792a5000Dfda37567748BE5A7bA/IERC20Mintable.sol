// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/**
 * @dev Interface of ERC20 Mint functionality.
 */

interface IERC20Mintable {
    function mint(address _to, uint256 _amount) external;
}
