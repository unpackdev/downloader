// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ReentrancyGuard.sol";

abstract contract BasicWithdraw {
    /// @dev an event to call when funds are withdrawn
    event OnWithdraw(address addr, uint256 balance);

    /// @dev allows to withdraw all the funds from the contract
    function _withdrawAllFunds(address payable _to) internal {
        _withdraw(_to, address(this).balance);
    }

    /// @dev allows to withdraw funds from the contract
    function _withdraw(address payable _to, uint256 amount) internal {
        require(_to != address(0), "address 0");
        uint256 balance = address(this).balance;
        require(balance >= amount, "no funds");

        /// solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _to.call{value: amount}("");
        require(success, "failed withdraw");
        emit OnWithdraw(_to, amount);
    }
}
