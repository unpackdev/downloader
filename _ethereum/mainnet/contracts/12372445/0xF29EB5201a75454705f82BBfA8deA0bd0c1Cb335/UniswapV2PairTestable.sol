pragma solidity >=0.5.0;

import "./IUniswapV2Pair.sol";

contract UniswapV2PairTestable is IUniswapV2Pair {
    uint112 public reserveUsd;
    uint112 public reserveEth;

    constructor(uint112 _reserveUsd, uint112 _reserveEth) {
        reserveUsd = _reserveUsd;
        reserveEth = _reserveEth;
    }

    function getReserves()
        external
        view
        override
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        )
    {
        return (reserveUsd, reserveEth, 0);
    }

    function name() external pure override returns (string memory) {
        return "";
    }

    function symbol() external pure override returns (string memory) {
        return "";
    }

    function decimals() external pure override returns (uint8) {
        return 0;
    }

    function totalSupply() external view override returns (uint256) {
        return 0;
    }

    function balanceOf(address owner) external view override returns (uint256) {
        return 0;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return 0;
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        return true;
    }

    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        return true;
    }

    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return 0;
    }

    function PERMIT_TYPEHASH() external pure override returns (bytes32) {
        return 0;
    }

    function nonces(address owner) external view override returns (uint256) {
        return 0;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {}

    function MINIMUM_LIQUIDITY() external pure override returns (uint256) {
        return 0;
    }

    function factory() external view override returns (address) {
        return address(0);
    }

    function token0() external view override returns (address) {
        return address(0);
    }

    function token1() external view override returns (address) {
        return address(0);
    }

    function price0CumulativeLast() external view override returns (uint256) {
        return 0;
    }

    function price1CumulativeLast() external view override returns (uint256) {
        return 0;
    }

    function kLast() external view override returns (uint256) {
        return 0;
    }

    function mint(address to) external override returns (uint256 liquidity) {
        return 0;
    }

    function burn(address to)
        external
        override
        returns (uint256 amount0, uint256 amount1)
    {
        return (0, 0);
    }

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external override {}

    function skim(address to) external override {}

    function sync() external override {}

    function initialize(address, address) external override {}
}
