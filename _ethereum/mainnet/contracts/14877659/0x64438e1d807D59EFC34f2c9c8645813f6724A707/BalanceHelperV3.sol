//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Metadata.sol";
import "./console.sol";

contract BalanceHelperV3 {
    constructor() {
        uint256 balance = address(this).balance;
        require(balance == 0.1 ether, 'Wrong balance');
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance(address token, address[] calldata users)
        external
        view
        returns (int256[] memory)
    {
        uint256 usersLength = users.length;
        int256[] memory balances = new int256[](usersLength);

        IERC20Metadata token_ = IERC20Metadata(token);
        for (uint256 i = 0; i < usersLength; i++)
            balances[i] = int256(
                token_.balanceOf(users[i]) * 10**(18 - token_.decimals())
            );

        return balances;
    }

    function getBalance(
        address token,
        address[] calldata users,
        address spender
    ) external view returns (int256[] memory) {
        uint256 usersLength = users.length;
        int256[] memory balances = new int256[](usersLength);

        IERC20Metadata token_ = IERC20Metadata(token);
        for (uint256 i = 0; i < usersLength; i++) {
            int256 balance = int256(
                token_.balanceOf(users[i]) * 10**(18 - token_.decimals())
            );
            uint256 allowance = token_.allowance(users[i], spender);
            balances[i] =
                balance *
                (allowance > type(uint256).max / 2 ? int256(1) : int256(-1));
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
