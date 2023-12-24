// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";


contract OwnerWithdrawable is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    receive() external payable {}

    fallback() external payable {}

    function withdraw(address token, uint256 amount) public onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function withdrawAll(address token) public onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        withdraw(token, amount);
    }

    function withdrawCurrency(uint256 amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
    }
	
    function transfer(address to, address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        require(to != address(0), "Invalid address");
		require(amount > 0, "Invalid amount");
        require(IERC20(tokenAddress).balanceOf(address(this)) >= amount, "Insufficient token balance");
        IERC20(tokenAddress).safeTransfer(to, amount);												// Use SafeERC20 for token transfer
    }

    function transferCurrency(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Invalid amount");
        require(address(this).balance >= amount, "Insufficient contract balance");
        Address.sendValue(to, amount);																//  Use of safeTransferETH
    }

}
