// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IWETH {
    function deposit() external payable;

    function balanceOf(address _account)
        external
        view
        returns (uint256 _balance);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}
