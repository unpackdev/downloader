// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";

contract GmxReader {
    using SafeMath for uint256;

    function getTokenSupply(IERC20 _token, address[] memory _excludedAccounts) public view returns (uint256) {
        uint256 supply = _token.totalSupply();
        for (uint256 i = 0; i < _excludedAccounts.length; i++) {
            address account = _excludedAccounts[i];
            uint256 balance = _token.balanceOf(account);
            supply = supply.sub(balance);
        }
        return supply;
    }

    function getTokenBalances(address _account, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                balances[i] = _account.balance;
                continue;
            }
            balances[i] = IERC20(token).balanceOf(_account);
        }
        return balances;
    }

    function getTokenBalancesWithSupplies(address _account, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256 propsLength = 2;
        uint256[] memory balances = new uint256[](_tokens.length * propsLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                balances[i * propsLength] = _account.balance;
                balances[i * propsLength + 1] = 0;
                continue;
            }
            balances[i * propsLength] = IERC20(token).balanceOf(_account);
            balances[i * propsLength + 1] = IERC20(token).totalSupply();
        }
        return balances;
    }
}
