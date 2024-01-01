// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ITOS.sol";
import "./ISwapRouter.sol";

contract PowerTONSwapperStorage {

    bool public pauseProxy;

    address public wton;
    ITOS public tos;
    ISwapRouter public uniswapRouter;
    address public autocoinageSnapshot;
    address public layer2Registry;
    address public seigManager;

    bool public migratedL2;
}
