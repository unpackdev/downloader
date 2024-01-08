// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.5.0;

import "./IERC20.sol";

interface IEmiswapRegistry {
    function pools(IERC20 token1, IERC20 token2)
        external
        view
        returns (IEmiswap);

    function isPool(address addr) external view returns (bool);

    function deploy(IERC20 tokenA, IERC20 tokenB) external returns (IEmiswap);
    function getAllPools() external view returns (IEmiswap[] memory);
}

interface IEmiswap {
    function fee() external view returns (uint256);

    function tokens(uint256 i) external view returns (IERC20);

    function deposit(
        uint256[] calldata amounts,
        uint256[] calldata minAmounts,
        address referral
    ) external payable returns (uint256 fairSupply);

    function withdraw(uint256 amount, uint256[] calldata minReturns) external;

    function getBalanceForAddition(IERC20 token)
        external
        view
        returns (uint256);

    function getBalanceForRemoval(IERC20 token) external view returns (uint256);

    function getReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) external view returns (uint256, uint256);

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        address to,
        address referral
    ) external payable returns (uint256 returnAmount);

    function initialize(IERC20[] calldata assets) external;
}
