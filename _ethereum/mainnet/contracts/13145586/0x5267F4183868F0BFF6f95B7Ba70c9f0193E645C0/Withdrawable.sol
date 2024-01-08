//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./IWithdrawable.sol";

contract Withdrawable is IWithdrawable, Ownable {
    function pendingWithdrawal() external view override returns (uint) {
        return address(this).balance;
    }

    function withdraw(uint _amount) external override onlyOwner {
        _withdraw(_amount);
    }

    function withdrawAll() external override onlyOwner {
        _withdraw(address(this).balance);
    }

    function _withdraw(uint _amount) internal {
        require(_amount > 0, "Withdrawable: Amount has to be greater than 0");
        require(
            _amount <= address(this).balance,
            "Withdrawable: Not enough funds"
        );
        payable(msg.sender).transfer(_amount);
    }
}