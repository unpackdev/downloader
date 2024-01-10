//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "./ERC20.sol";

interface IPolygonBridge {
   
    function exit(bytes calldata inputData) external;
}
