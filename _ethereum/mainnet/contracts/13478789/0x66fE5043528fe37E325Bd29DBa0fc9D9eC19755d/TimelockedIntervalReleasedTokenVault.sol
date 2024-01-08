// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "./TimelockedTokenVault.sol";

/**
 * Contract that extends the TimelockedTokenVault with the support to release the capital
 * based on a predefiend interval
 */
contract TimelockedIntervalReleasedTokenVault is TimelockedTokenVault {
    using SafeERC20 for IERC20;

    // the interval
    uint256 private immutable _interval;

    /**
     * @dev Initalizes a new instanc of the TimelockedIntervaldReleased Vault
     * @param beneficiary_ the beneficary who gets the holdings
     * @param interval_ in seconds
     * @param duration_ in seconds
     */
    constructor(
        address beneficiary_,
        uint256 duration_,
        uint256 interval_
    ) TimelockedTokenVault(beneficiary_, duration_) {
        _interval = interval_;
    }

    /**
     * @return the interval within which capital will be released
     */
    function interval() public view returns (uint256) {
        return _interval;
    }

    /**
     * @return returns the available amount to collect for the current time
     */
    function availableAmount() public view returns (uint256) {
        require(_started, 'Lock not started');
        uint256 tokensToRetrieve = 0;
        if (block.timestamp >= _startDate + _duration) {
            tokensToRetrieve = _token.balanceOf(address(this));
        } else {
            uint256 parts = _duration / _interval;
            uint256 tokensByPart = _startBalance / parts;
            uint256 timeSinceStart = block.timestamp - _startDate;
            uint256 pastParts = timeSinceStart / _interval;
            uint256 tokensToRetrieveSinceStart = pastParts * tokensByPart;
            tokensToRetrieve = tokensToRetrieveSinceStart - _retrievedTokens;
        }
        return tokensToRetrieve;
    }

    /**
     * @dev payout the locked amount of token
     */
    function retrieveLockedTokens() public override onlyOwner {
        require(_started, 'Lock not started');
        uint256 amountToTransfer = availableAmount();
        require(amountToTransfer > 0, 'No tokens available for retrieving at this moment.');
        _retrievedTokens = _retrievedTokens + amountToTransfer;
        _token.safeTransfer(beneficiary(), amountToTransfer);
    }
}
