// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IArrakisV2.sol";
import "./IERC20.sol";

struct SetupPayload {
    // Initialized Payload properties
    uint24[] feeTiers;
    IERC20 token0;
    IERC20 token1;
    bool projectTknIsTknZero;
    address owner;
    uint256 amount0;
    uint256 amount1;
    bytes datas;
    string strat;
    bool isBeacon;
    address delegate;
    address[] routers;
}

struct IncreaseBalance {
    IArrakisV2 vault;
    bool projectTknIsTknZero;
    uint256 amount0;
    uint256 amount1;
}

struct DecreaseBalance {
    IArrakisV2 vault;
    uint256 amount0;
    uint256 amount1;
    address to;
}

struct Inits {
    uint256 init0;
    uint256 init1;
}
