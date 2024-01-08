// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IWETH {
		function approve(address to, uint amount) external returns (bool);
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
