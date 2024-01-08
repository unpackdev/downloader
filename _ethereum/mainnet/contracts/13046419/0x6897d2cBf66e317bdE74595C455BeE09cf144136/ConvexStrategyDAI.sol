// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./ConvexStrategy.sol";

//solhint-disable no-empty-blocks
contract ConvexStrategyDAI is ConvexStrategy {
    string public constant NAME = "Curve-Convex-3pool-DAI-Strategy";
    string public constant VERSION = "3.0.12";
    address private constant THREEPOOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address private constant THREECRV = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address private constant GAUGE = 0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A;

    constructor(address _pool, address _swapManager)
        ConvexStrategy(_pool, THREEPOOL, THREECRV, GAUGE, _swapManager, 0, 9)
    {}
}
