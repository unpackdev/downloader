// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "./ERC20StakeMiningV1.sol";
import "./MiningPoolFactory.sol";

contract ERC20StakeMiningV1Factory is MiningPoolFactory {
    bytes4 public override poolType =
        ERC20StakeMiningV1(0).erc20StakeMiningV1.selector;

    constructor() MiningPoolFactory() {
        address _controller = address(new ERC20StakeMiningV1());
        _setController(_controller);
    }
}
