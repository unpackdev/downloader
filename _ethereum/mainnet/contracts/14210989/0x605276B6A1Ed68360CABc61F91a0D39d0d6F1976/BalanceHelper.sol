//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract BalanceHelper {
    function getBalance(address token, address[] calldata users)
        external
        view
        returns (uint256[] memory)
    {
        uint256 usersLength = users.length;
        uint256[] memory balances = new uint256[](usersLength);

        IERC20 token_ = IERC20(token);
        for (uint256 i = 0; i < usersLength; i++) {
            balances[i] = token_.balanceOf(users[i]);
        }

        return balances;
    }

    function getBalanceNative(address[] memory users)
        external
        view
        returns (uint256[] memory)
    {
        uint256 length = users.length;
        uint256[] memory balances = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            balances[i] = payable(users[i]).balance;
        }

        return balances;
    }
}
