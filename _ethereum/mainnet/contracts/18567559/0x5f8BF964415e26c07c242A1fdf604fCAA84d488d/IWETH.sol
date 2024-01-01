// SPDX-License-Identifier: MIT

pragma solidity >=0.4.23 <0.9.0;

import "Ownable.sol";
import "ERC20.sol";
import "SafeERC20.sol";

// WETH Inteface //
interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external; 
}
