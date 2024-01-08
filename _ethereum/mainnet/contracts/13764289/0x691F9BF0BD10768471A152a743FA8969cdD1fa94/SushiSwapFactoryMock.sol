// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./TanosiaFactory.sol";

contract SushiSwapFactoryMock is TanosiaFactory {
    constructor(address _feeToSetter) public TanosiaFactory(_feeToSetter) {}
}