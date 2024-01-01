// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProxyableToken {
    function deposit(
        address sender,
        uint256[] memory tokenAmounts,
        uint256 minLpAmount
    ) external returns (uint256 lpAmount);

    function withdraw(
        address sender,
        uint256 lpAmount,
        uint256[] memory minTokenAmounts
    ) external returns (uint256[] memory tokenAmounts);

    function transfer(address sender, address to, uint256 amount) external returns (bool);

    function approve(address sender, address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address from, address to, uint256 amount) external returns (bool);

    function increaseAllowance(address sender, address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address sender, address spender, uint256 subtractedValue) external returns (bool);

    function isSameKind(address token) external view returns (bool);

    function updateSecurityParams(bytes memory newSecurityParams) external;
}
