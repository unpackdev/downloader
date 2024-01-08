// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.8;

import "./MockERC20.sol";


contract JAX is MockERC20 {
    // solhint-disable-next-line func-visibility
    constructor () MockERC20("JAX Token", "JAX") {}// solhint-disable-line no-empty-blocks
}
