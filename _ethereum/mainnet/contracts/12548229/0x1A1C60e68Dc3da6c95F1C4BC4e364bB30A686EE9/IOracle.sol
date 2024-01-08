// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @title Oracle interface
 */
interface IOracle {

    function getPrice() external view returns (uint256);

}
