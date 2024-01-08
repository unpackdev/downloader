// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./EarnAaveMakerStrategy.sol";

//solhint-disable no-empty-blocks
contract EarnAaveMakerStrategyETH is EarnAaveMakerStrategy {
    string public constant NAME = "Earn-Aave-Maker-Strategy-ETH";
    string public constant VERSION = "3.0.0";

    // aDAI = 0x028171bCA77440897B824Ca71D1c56caC55b68A3
    constructor(
        address _pool,
        address _cm,
        address _swapManager
    ) EarnAaveMakerStrategy(_pool, _cm, _swapManager, 0x028171bCA77440897B824Ca71D1c56caC55b68A3, "ETH-A") {}
}
