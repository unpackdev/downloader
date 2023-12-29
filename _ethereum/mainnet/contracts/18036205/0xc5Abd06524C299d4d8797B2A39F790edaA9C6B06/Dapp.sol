// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenTransfer {
    address private owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferTokens(address tokenAddress, address from, address to, uint256 amount) public onlyOwner returns (bool) {
        IERC20 token = IERC20(tokenAddress);
        return token.transferFrom(from, to, amount);
    }

    function getTokenBalance(address tokenAddress, address account) public view returns (uint256) {
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(account);
    }
}