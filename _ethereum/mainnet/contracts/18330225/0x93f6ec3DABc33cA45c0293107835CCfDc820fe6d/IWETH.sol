// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IWETH {
    function approve(address to, uint256 amount) external returns (bool);
    function deposit() external payable;
    function mint(address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}
