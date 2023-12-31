// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IERC20.sol";

contract WagmiPower {

    address public immutable wagmi;
    address public immutable ice;
    address public immutable nice;
    address public immutable v2pair;

    /**
     * @dev The multiplier equals to ice.balanceOf(nice) / nice.totalSupply() with 1e18 BPS
     */
    uint256 public constant NICE_MULTIPLIER = 82079452713910313409;
    uint256 public constant BPS = 1e18;

    constructor(
        address _wagmi,
        address _ice,
        address _nice,
        address _v2pair
    ) {
        wagmi = _wagmi;
        ice = _ice;
        nice = _nice;
        v2pair = _v2pair;
    }

    function balanceOfAll(address account) external view returns (uint256 powah) {
        if (wagmi != address(0))
            powah += safeBalanceOf(wagmi, account);
        if (ice != address(0))
            powah += safeBalanceOf(ice, account) * 69;
        if (nice != address(0))
            powah += safeBalanceOf(nice, account) * NICE_MULTIPLIER / BPS;
        if (v2pair != address(0))
            powah += safeBalanceOf(v2pair, account) * safeBalanceOf(ice, v2pair) / IERC20(v2pair).totalSupply() * 2 * 69;
    }

    function balanceOfWagmi(address account) external view returns (uint256 powah) {
        if (wagmi != address(0))
            powah += safeBalanceOf(wagmi, account);
    }

    function safeBalanceOf(address token, address owner) private view returns (uint256 balance) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, owner)
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

}