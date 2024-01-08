// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";

contract XifraVesting {
    address immutable private xifraWallet;
    address immutable private xifraToken;
    uint256 private listingDate;
    uint256 private tokensWithdrawn;

    uint32 internal constant _1_YEAR_IN_SECONDS = 31536000;
    uint32 internal constant _1_MONTH_IN_SECONDS = 2592000;
    uint32 internal constant _3_MONTH_IN_SECONDS = _1_MONTH_IN_SECONDS * 3;
    uint32 internal constant _6_MONTH_IN_SECONDS = _1_MONTH_IN_SECONDS * 6;
    uint32 internal constant _9_MONTH_IN_SECONDS = _1_MONTH_IN_SECONDS * 9;
    uint32 internal constant _12_MONTH_IN_SECONDS = _1_MONTH_IN_SECONDS * 12;
    uint32 internal constant _15_MONTH_IN_SECONDS = _1_MONTH_IN_SECONDS * 15;
    uint32 internal constant _18_MONTH_IN_SECONDS = _1_MONTH_IN_SECONDS * 18;
    uint32 internal constant _21_MONTH_IN_SECONDS = _1_MONTH_IN_SECONDS * 21;
    uint32 internal constant _24_MONTH_IN_SECONDS = _1_MONTH_IN_SECONDS * 24;
    uint32 internal constant _27_MONTH_IN_SECONDS = _1_MONTH_IN_SECONDS * 27;
    uint32 internal constant _30_MONTH_IN_SECONDS = _1_MONTH_IN_SECONDS * 30;
    uint32 internal constant _33_MONTH_IN_SECONDS = _1_MONTH_IN_SECONDS * 33;
    uint32 internal constant _36_MONTH_IN_SECONDS = _1_MONTH_IN_SECONDS * 36;
    uint32 internal constant _39_MONTH_IN_SECONDS = _1_MONTH_IN_SECONDS * 39;
    uint32 internal constant _42_MONTH_IN_SECONDS = _1_MONTH_IN_SECONDS * 42;
    uint32 internal constant _45_MONTH_IN_SECONDS = _1_MONTH_IN_SECONDS * 45;
    uint32 internal constant _48_MONTH_IN_SECONDS = _1_MONTH_IN_SECONDS * 48;
    
    event onUnlockNewTokens(address _user, uint256 _maxTokensUnlocked);

    constructor(address _token, uint256 _listingDate) {
        xifraToken = _token;
        listingDate = _listingDate;
        xifraWallet = msg.sender;
    }

    function unlockTokens() external {
        require(listingDate > 0, "NoListingDate");
        require(block.timestamp >= listingDate + _1_YEAR_IN_SECONDS, "NotAvailable");

        uint256 maxTokensAllowed = 0;
        uint256 initTime = listingDate + _1_YEAR_IN_SECONDS;
        if ((block.timestamp >= initTime) && (block.timestamp < initTime + _3_MONTH_IN_SECONDS)) {
            maxTokensAllowed = 18750000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + _3_MONTH_IN_SECONDS) && (block.timestamp < initTime + _6_MONTH_IN_SECONDS)) {
            maxTokensAllowed = 37500000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + _6_MONTH_IN_SECONDS) && (block.timestamp < initTime + _9_MONTH_IN_SECONDS)) {
            maxTokensAllowed = 56250000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + _9_MONTH_IN_SECONDS) && (block.timestamp < initTime + _12_MONTH_IN_SECONDS)) {
            maxTokensAllowed = 75000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + _12_MONTH_IN_SECONDS) && (block.timestamp < initTime + _15_MONTH_IN_SECONDS)) {
            maxTokensAllowed = 92500000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + _15_MONTH_IN_SECONDS) && (block.timestamp < initTime + _18_MONTH_IN_SECONDS)) {
            maxTokensAllowed = 110000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + _18_MONTH_IN_SECONDS) && (block.timestamp < initTime + _21_MONTH_IN_SECONDS)) {
            maxTokensAllowed = 127500000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + _21_MONTH_IN_SECONDS) && (block.timestamp < initTime + _24_MONTH_IN_SECONDS)) {
            maxTokensAllowed = 145000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + _24_MONTH_IN_SECONDS) && (block.timestamp < initTime + _27_MONTH_IN_SECONDS)) {
            maxTokensAllowed = 170000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + _27_MONTH_IN_SECONDS) && (block.timestamp < initTime + _30_MONTH_IN_SECONDS)) {
            maxTokensAllowed = 195000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + _30_MONTH_IN_SECONDS) && (block.timestamp < initTime + _33_MONTH_IN_SECONDS)) {
            maxTokensAllowed = 220000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + _33_MONTH_IN_SECONDS) && (block.timestamp < initTime + _36_MONTH_IN_SECONDS)) {
            maxTokensAllowed = 245000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + _36_MONTH_IN_SECONDS) && (block.timestamp < initTime + _39_MONTH_IN_SECONDS)) {
            maxTokensAllowed = 270000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + _39_MONTH_IN_SECONDS) && (block.timestamp < initTime + _42_MONTH_IN_SECONDS)) {
            maxTokensAllowed = 295000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + _42_MONTH_IN_SECONDS) && (block.timestamp < initTime + _45_MONTH_IN_SECONDS)) {
            maxTokensAllowed = 320000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + _45_MONTH_IN_SECONDS) && (block.timestamp < initTime + _48_MONTH_IN_SECONDS)) {
            maxTokensAllowed = 345000000 * 10 ** 18;
        }

        maxTokensAllowed -= tokensWithdrawn;
        require(maxTokensAllowed > 0, "NoTokensToUnlock");

        tokensWithdrawn += maxTokensAllowed;
        require(IERC20(xifraToken).transfer(xifraWallet, maxTokensAllowed));

        emit onUnlockNewTokens(msg.sender, maxTokensAllowed);
    }

    function getTokensInVesting() external view returns(uint256) {
        return IERC20(xifraToken).balanceOf(address(this));
    }

    /**
     * @notice OnlyOwner function. Change the listing date to start the vesting
     * @param _listDate --> New listing date in UnixDateTime UTC format
     */
    function setTokenListDate(uint256 _listDate) external {
        require(msg.sender == xifraWallet, "BadOwner");
        require(block.timestamp <= listingDate, "TokenListedYet");

        listingDate = _listDate;
    }
}