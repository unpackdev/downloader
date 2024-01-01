// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DividendToken.sol";
import "./IterableMapping.sol";

abstract contract TokenTracker is DividendToken {
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    struct User {
        bool isExcludedFromDividends;
        bool isExcludedFromFees;
        bool canTransferBeforeTradingIsEnabled;
        bool automatedMarketMakerPairs;
        bool isBlacklisted;
        uint64 lastClaimTimes;
    }

    // minimum tokens to be eligibile for dividends
    uint256 public constant minimumTokenBalanceForDividends = 9_000_000 ether;
    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;
    uint256 public claimWait = 3600;

    mapping(address => User) internal users;

    event ExcludeFromDividends(address indexed account, bool exclude);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(address indexed account, uint256 amount);

    // internal functions
    function _dividendShare(address _account) internal view override returns (uint256 _share) {
        _share = tokenHoldersMap.get(_account);
    }
    
    function _getAccount(address _account)
        internal
        view
        returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        )
    {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index - int256(lastProcessedIndex);
            } else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex
                    ? tokenHoldersMap.keys.length - lastProcessedIndex
                    : 0;

                iterationsUntilProcessed = index + int256(processesUntilEndOfArray);
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = users[account].lastClaimTimes;

        nextClaimTime = lastClaimTime > 0 ? lastClaimTime + claimWait : 0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime - block.timestamp : 0;
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp) {
            return false;
        }

        return block.timestamp - lastClaimTime >= claimWait;
    }

    function _excludeFromDividends(address account, bool exclude) internal {
        require(users[account].isExcludedFromDividends != exclude, "already has been set!");
        users[account].isExcludedFromDividends = exclude;
        uint256 bal = balanceOf(account);
        if (exclude) {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        } else {
            _setBalance(account, bal);
            tokenHoldersMap.set(account, bal);
        }

        emit ExcludeFromDividends(account, exclude);
    }

    function setBalance(address account, uint256 newBalance) internal {
        if (users[account].isExcludedFromDividends) {
            return;
        }
        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        } else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        _processAccount(payable(account));
    }

    function processAccount(address payable account) internal returns (uint256 amount) {
        amount = _withdrawDividendOfUser(account);
        emit Claim(account, amount);
    }

    function _processAccount(address payable account) private returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            // safe casting
            users[account].lastClaimTimes = uint64(block.timestamp);
            return true;
        }

        return false;
    }

    // owner restricted
    function excludeFromDividends(address account, bool exclude) external onlyOwner {
        _excludeFromDividends(account, exclude);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 1800 && newClaimWait <= 86400, "must be updated 1 to 24 hours");
        require(newClaimWait != claimWait, "same claimWait value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    // public functions
    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address account)
        external
        view
        returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256)
    {
        return _getAccount(account);
    }

    function getAccountAtIndex(uint256 index)
        public
        view
        returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256)
    {
        if (index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return _getAccount(account);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if (numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if (canAutoClaim(users[account].lastClaimTimes)) {
                if (_processAccount(payable(account))) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed + (gasLeft - newGasLeft);
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }
}
