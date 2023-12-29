// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IFlashLoanSimpleReceiver.sol";
import "./IPool.sol";

contract Flashloan {
    IPool public pool;
    address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    constructor (address _pool) {
        pool = IPool(_pool);
    }

    // function flashloan() public { 
    //     pool.flashLoanSimple(address(this), USDC, 100 * 10**6, "", 0);
    // }

}