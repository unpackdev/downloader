// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./Ownable.sol";
import "./IERC20.sol";

contract FundsRecoverable is Ownable {
    /**
    Recover accidental tokens sent to contract
    */
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        public
        onlyOwner
    {
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
    }

    /**
    Recover accidental ETH sent to contract
    */
    function recoverETH() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "TransferFailed");
    }
}
