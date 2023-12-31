// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

/**
 * @title IWeth9
 * @notice Interface for the WETH9 contract at 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 on mainnet
 * @dev Adaptated from contract to interface based on the verified code for WETH9 on etherscan
 */
interface IWeth9 {
    function name() external returns (string memory);
    function symbol() external returns (string memory);
    function decimals() external returns (uint8);

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    function balanceOf(address src) external view returns (uint256 balance);
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function deposit() external payable;
    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(address src, address dst, uint256 wad) external returns (bool);
}
