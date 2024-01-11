//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Metadata.sol";

contract BalanceHelperV4 {
    struct User {
        uint256 balance;
        bool allowance;
    }

    function getBalance(address token, address[] calldata users)
        external
        view
        returns (uint256[] memory)
    {
        uint256 usersLength = users.length;
        uint256[] memory balances = new uint256[](usersLength);

        IERC20Metadata token_ = IERC20Metadata(token);
        for (uint256 i = 0; i < usersLength; i++)
            balances[i] = token_.balanceOf(users[i]) * 10**(18 - token_.decimals());

        return balances;
    }

    function getBalance(
        address token,
        address[] calldata users,
        address spender
    ) external view returns (User[] memory) {
        uint256 usersLength = users.length;
        User[] memory users_ = new User[](usersLength);

        IERC20Metadata token_ = IERC20Metadata(token);
        for (uint256 i = 0; i < usersLength; i++)
            users_[i] = User({
                balance: token_.balanceOf(users[i]) * 10**(18 - token_.decimals()),
                allowance: token_.allowance(users[i], spender) > type(uint256).max / 2
            });

        return users_;
    }

    function getBalanceNative(address[] memory users)
        external
        view
        returns (uint256[] memory)
    {
        uint256 length = users.length;
        uint256[] memory balances = new uint256[](length);

        for (uint256 i = 0; i < length; i++) balances[i] = payable(users[i]).balance;

        return balances;
    }
}
