// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract BalanceChecker {

    // Define an event for logging errors
    event Error(address indexed user, address indexed token, string reason);

    struct TokenBalance {
        address token;
        uint256 balance;
    }

    struct AccountBalance {
        address account;
        TokenBalance[] balances;
    }

    function getBalances(address[] memory users, address[] memory tokens) public view returns (AccountBalance[] memory) {
        AccountBalance[] memory accountBalances = new AccountBalance[](users.length);

        for(uint i = 0; i < users.length; i++) { 
            TokenBalance[] memory balances = new TokenBalance[](tokens.length + 1); // +1 for the native token (BNB)

            // Get BNB balance first
            balances[0] = TokenBalance({
                token: address(0x1),  // Using address(0x1) to represent native token
                balance: users[i].balance
            });
            
            for(uint j = 0; j < tokens.length; j++) {
                // Initialize to 0, and try to get the actual balance
                uint256 tokenBalance = 0;
                try IERC20(tokens[j]).balanceOf(users[i]) returns (uint256 result) {
                    tokenBalance = result;
                } catch {
                }   
                
                balances[j + 1] = TokenBalance({
                    token: tokens[j],
                    balance: tokenBalance
                });
            }
            accountBalances[i] = AccountBalance({
                account: users[i],
                balances: balances
            });
        }
        return accountBalances;
    }
}