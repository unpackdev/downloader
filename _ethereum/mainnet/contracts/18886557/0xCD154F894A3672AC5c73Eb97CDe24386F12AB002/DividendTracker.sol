// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./DividendPayingContract.sol";

contract DividendTracker is DividendPayingContract {
    event Claim(
        address indexed account,
        uint256 amount,
        bool indexed automatic
    );

    constructor(address _rewardToken) DividendPayingContract(_rewardToken) {}

    function getAccount(
        address _account
    )
        public
        view
        returns (
            address account,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 balance
        )
    {
        account = _account;

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        balance = holderBalance[account];
    }

    function setBalance(address account, uint256 newBalance) internal {
        _setBalance(account, newBalance);

        processAccount(account, true);
    }

    function processAccount(
        address account,
        bool automatic
    ) internal returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return totalDividendsDistributed;
    }

    function dividendTokenBalanceOf(
        address account
    ) public view returns (uint256) {
        return holderBalance[account];
    }

    function getNumberOfDividends() external view returns (uint256) {
        return totalBalance;
    }
}
