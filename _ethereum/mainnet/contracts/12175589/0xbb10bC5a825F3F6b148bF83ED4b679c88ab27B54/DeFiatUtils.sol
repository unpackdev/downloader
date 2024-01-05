// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./IERC20.sol";
import "./Ownable.sol";

abstract contract DeFiatUtils is Ownable {
    event TokenSweep(address indexed user, address indexed token, uint256 amount);

    // Sweep any tokens/ETH accidentally sent or airdropped to the contract
    function sweep(address token) public virtual onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        require(amount > 0, "Sweep: No token balance");

        IERC20(token).transfer(msg.sender, amount); // use of the ERC20 traditional transfer

        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }

        emit TokenSweep(msg.sender, token, amount);
    }

    // Self-Destruct contract to free space on-chain, sweep any ETH to owner
    function kill() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}