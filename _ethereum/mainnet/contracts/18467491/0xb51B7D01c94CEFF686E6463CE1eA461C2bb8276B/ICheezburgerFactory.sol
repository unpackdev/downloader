// SPDX-License-Identifier: MITz
pragma solidity ^0.8.22;

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./CheezburgerStructs.sol";

interface ICheezburgerFactory is CheezburgerStructs {
    function beforeTokenTransfer(
        uint256 _leftSideBalance
    ) external returns (bool);

    function burgerRegistryRouterOnly(
        address token
    ) external view returns (IUniswapV2Router02, IUniswapV2Pair);
}
