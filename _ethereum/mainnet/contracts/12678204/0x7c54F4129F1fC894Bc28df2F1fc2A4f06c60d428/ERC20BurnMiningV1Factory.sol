// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "./ERC20BurnMiningV1.sol";
import "./MiningPoolFactory.sol";

contract ERC20BurnMiningV1Factory is MiningPoolFactory {
    bytes4 public override poolType =
        ERC20BurnMiningV1(0).erc20BurnMiningV1.selector;

    constructor() MiningPoolFactory() {
        address _controller = address(new ERC20BurnMiningV1());
        _setController(_controller);
    }
}
