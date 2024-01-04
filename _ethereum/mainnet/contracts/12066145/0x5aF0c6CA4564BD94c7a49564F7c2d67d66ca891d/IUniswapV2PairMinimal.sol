// SPDX-License-Identifier: WTFPL
pragma solidity ^0.6.0;

interface IUniswapV2PairMinimal {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
