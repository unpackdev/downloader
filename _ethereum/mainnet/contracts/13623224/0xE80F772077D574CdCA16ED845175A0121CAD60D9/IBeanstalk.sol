/**
 * SPDX-License-Identifier: MIT
**/

pragma solidity ^0.8.6;

/**
 * @author Publius
 * @title Bean Interface
**/
abstract contract IBeanstalk {

    function sowBeans(uint256 amount) external virtual returns (uint256);
    function transferPlot(address sender, address recipient, uint256 id, uint256 start, uint256 end) external virtual;
}
