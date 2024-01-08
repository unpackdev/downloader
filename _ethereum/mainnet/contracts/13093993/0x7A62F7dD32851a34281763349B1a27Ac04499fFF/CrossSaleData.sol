// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./Ownable.sol";
import "./Lockable.sol";

contract CrossSaleData is Ownable, Lockable {
    mapping(address => uint256) public balanceOf;

    function addUser(address user, uint256 amount) external onlyOwner whenNotLocked {
        balanceOf[user] = amount;
    }

    function massAddUsers(address[] calldata user, uint256[] calldata amount) external onlyOwner whenNotLocked {
        uint256 len = user.length;
        require(len == amount.length, "Data size mismatch");
        uint256 i;
        for (i; i < len; i++) {
            balanceOf[user[i]] = amount[i];
        }
    }
}
