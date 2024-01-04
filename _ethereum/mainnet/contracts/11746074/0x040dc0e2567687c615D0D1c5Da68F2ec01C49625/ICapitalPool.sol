// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12; 

import "./IERC20.sol";

interface ICapitalPool is IERC20{
    event Provide(address indexed account, uint amount, uint burnt);
    event Withdraw(address indexed account, uint amount, uint burnt);

    function totalBalance() external view returns (uint);
    function availableBalance() external view returns (uint);

    function sendTo(address to, uint amount) external;
    function updateInvestedBalance(bool isAddOrSubstract, uint amount) external;

    function provide(uint minMint) external payable returns (uint amountToMint);
    function withdraw(uint amount, uint maxBurn) external returns (uint amountToBurn);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}