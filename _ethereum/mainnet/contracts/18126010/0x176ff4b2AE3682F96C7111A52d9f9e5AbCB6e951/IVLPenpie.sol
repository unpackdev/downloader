// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "./ERC20.sol";
import "./ILocker.sol";

interface IVLPenpie is ILocker {
    
    function penpie() external view returns(IERC20);
}