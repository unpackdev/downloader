// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./Ownable.sol";

contract SharesWallet is Ownable {

    event Deposit(address user, uint amount);
    event Withdraw(address user, uint amount);

    constructor() {

    }

    function deposit() external payable {
        require(msg.value > 0, "non of eth value deposited");
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint amount, address toUser ) external onlyOwner {
        require(address(this).balance >= amount, "insufficient balance");
        (bool success, ) = payable(toUser).call{value: amount}("");
        require(success, "withdraw faild");
        emit Withdraw(msg.sender, amount);
    }
}
