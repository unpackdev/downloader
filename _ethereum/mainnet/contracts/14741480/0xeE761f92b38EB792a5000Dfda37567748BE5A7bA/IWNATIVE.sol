// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/**
 * @dev Interface of added Wrapped Native token functionality.
 */

import "./IERC20.sol";

interface IWNATIVE is IERC20 {
    function deposit() external payable;

    function transfer(address to, uint256 value) external override returns (bool);

    function withdraw(uint256 amount) external;

    function withdrawFor(address account, uint256 amount) external;

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
}
