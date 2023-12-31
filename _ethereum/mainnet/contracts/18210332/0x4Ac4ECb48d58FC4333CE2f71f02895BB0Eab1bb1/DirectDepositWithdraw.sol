pragma solidity ^0.8.9;

// SPDX-License-Identifier: UNLICENSED
import "./Initializable.sol";

interface ERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract DirectDepositWithdraw is Initializable {
    address public owner;

    function init(address ownerAddr) public virtual initializer {
        owner = ownerAddr;
    }

    receive() external payable {}

    function withdraw(uint256 amount, address payable recipient) public {
        require(msg.sender == owner, "Only owner can withdraw");
        recipient.transfer(amount);
    }

    function withdrawERC20(
        address tokenAddress,
        uint256 amount,
        address recipient
    ) public {
        require(msg.sender == owner, "Only owner can withdraw");
        ERC20 token = ERC20(tokenAddress);
        require(token.transfer(recipient, amount), "Transfer failed");
    }
}
