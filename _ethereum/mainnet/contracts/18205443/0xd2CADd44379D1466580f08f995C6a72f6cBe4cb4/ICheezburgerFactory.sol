// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./IUniswapV2Pair.sol";

interface ICheezburgerFactory {
    function afterTokenTransfer(
        address _sender,
        uint256 _leftSideBalance
    ) external;

    function selfPair() external returns (IUniswapV2Pair);
}
