// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract PayWithContext {

    event Paid(address indexed from, address indexed to, address token, uint256 amount, bytes context);

    function payToken(address token, address to, uint256 amount, bytes memory context) external {
        ERC20(token).transferFrom(msg.sender, to, amount);
        emit Paid(msg.sender, to, token, amount, context);
    }

    function payEther(address payable to, bytes memory context) external payable {
        to.transfer(msg.value);
        emit Paid(msg.sender, to, address(0), msg.value, context);
    }

}