// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./YearnStrategy.sol";

// solhint-disable no-empty-blocks
/// @title Deposit DAI in Yearn's DAI yVault and earn interest.
contract YearnStrategyDAI is YearnStrategy {
    string public constant NAME = "Yearn-Strategy-DAI";
    string public constant VERSION = "3.0.0";

    // yvDAI = 0x19D3364A399d251E894aC732651be8B0E4e85001
    constructor(address _pool, address _swapManager)
        YearnStrategy(_pool, _swapManager, 0x19D3364A399d251E894aC732651be8B0E4e85001)
    {}
}
