// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;




interface IERC20 {
    function transfer(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external;
}

contract Vault {
    address immutable RECEIVER;
    IERC20 immutable USDT;

    constructor(address _receiver, address _usdt) {
        RECEIVER = _receiver;
        USDT = IERC20(_usdt);
    }

    function deposit(uint256 value) external payable {
        USDT.transferFrom(msg.sender, address(this), value);
        USDT.transfer(RECEIVER, value);
    }
}