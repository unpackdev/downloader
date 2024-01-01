// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IERC20Upgradeable.sol";

/**
 * @author Publius
 * @title WETH Interface
**/
interface IWETH is IERC20Upgradeable {

    function deposit() external payable;
    function withdraw(uint) external;

}
