// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
interface IERC20 {
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
}
contract Holdings {
     modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    address public owner;
    constructor() payable {
        owner = msg.sender;
    }
    function withdraw(address erc20, uint256 amount) public onlyOwner {
        if (erc20 == address(0x0)) {
            uint256 balance = address(this).balance;
            require(balance > 0, "No Ether to withdraw");
            payable(msg.sender).transfer(amount);
        }
        else {
            uint256 balance = IERC20(erc20).balanceOf(address(this));
            require(balance > 0, "No erc to withdraw");
            IERC20(erc20).transfer(msg.sender, amount);
        }
    }
    receive() external payable {}
}