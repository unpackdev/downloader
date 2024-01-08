//PDX-License-Identifier: <SPDX-License>
pragma solidity ^0.6.2;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function deposit() external payable;

    function withdraw(uint256 amount) external;
}
