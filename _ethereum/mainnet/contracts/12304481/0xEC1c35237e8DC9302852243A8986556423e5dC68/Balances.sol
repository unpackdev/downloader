//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

contract Balances {
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function getBalances(address[] calldata tokens, address user)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == ETH) balances[i] = user.balance;
            else balances[i] = IERC20(tokens[i]).balanceOf(user);
        }

        return balances;
    }
}
