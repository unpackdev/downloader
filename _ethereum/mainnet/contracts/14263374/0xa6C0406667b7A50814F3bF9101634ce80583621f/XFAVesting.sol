// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";

contract XFAVesting {
    address immutable private wallet;
    address immutable private token;
    uint256 immutable private tokenListingDate;
    uint256 private tokensWithdrawn;
   
    event onUnlockNewTokens(address _user, uint256 _maxTokensUnlocked);
    event onEmergencyWithdraw();

    constructor(address _token, uint256 _listingDate) {
        token = _token;
        tokenListingDate = _listingDate;
        wallet = msg.sender;
    }

    function unlockTokens() external {
        require(tokenListingDate > 0, "NoListingDate");
        require(block.timestamp >= tokenListingDate + 360 days, "NotAvailable");

        uint256 maxTokensAllowed = 0;
        uint256 initTime = tokenListingDate + 360 days;
        if ((block.timestamp >= initTime) && (block.timestamp < initTime + 90 days)) {
            maxTokensAllowed = 18750000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 90 days) && (block.timestamp < initTime + 180 days)) {
            maxTokensAllowed = 37500000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 180 days) && (block.timestamp < initTime + 270 days)) {
            maxTokensAllowed = 56250000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 270 days) && (block.timestamp < initTime + 360 days)) {
            maxTokensAllowed = 75000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 360 days) && (block.timestamp < initTime + 450 days)) {
            maxTokensAllowed = 92500000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 450 days) && (block.timestamp < initTime + 540 days)) {
            maxTokensAllowed = 110000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 540 days) && (block.timestamp < initTime + 630 days)) {
            maxTokensAllowed = 127500000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 630 days) && (block.timestamp < initTime + 720 days)) {
            maxTokensAllowed = 145000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 720 days) && (block.timestamp < initTime + 810 days)) {
            maxTokensAllowed = 170000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 810 days) && (block.timestamp < initTime + 900 days)) {
            maxTokensAllowed = 195000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 900 days) && (block.timestamp < initTime + 990 days)) {
            maxTokensAllowed = 220000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 990 days) && (block.timestamp < initTime + 1080 days)) {
            maxTokensAllowed = 245000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 1080 days) && (block.timestamp < initTime + 1170 days)) {
            maxTokensAllowed = 270000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 1170 days) && (block.timestamp < initTime + 1260 days)) {
            maxTokensAllowed = 295000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 1260 days) && (block.timestamp < initTime + 1350 days)) {
            maxTokensAllowed = 320000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 1350 days) && (block.timestamp < initTime + 1440 days)) {
            maxTokensAllowed = 345000000 * 10 ** 18;
        }

        maxTokensAllowed -= tokensWithdrawn;
        require(maxTokensAllowed > 0, "NoTokensToUnlock");

        tokensWithdrawn += maxTokensAllowed;
        require(IERC20(token).transfer(wallet, maxTokensAllowed));

        emit onUnlockNewTokens(msg.sender, maxTokensAllowed);
    }

    function getTokensInVesting() external view returns(uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function emegercyWithdraw() external {
        require(msg.sender == wallet, "OnlyOwner");

        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(wallet, balance);

        emit onEmergencyWithdraw();
    }
}