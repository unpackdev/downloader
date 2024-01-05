// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library UserLibrary {

    struct User {
        uint referralCount;
        uint directReferrerIncome;
        uint lostIncome;
        uint currentPlan;
        uint investmentCount;
        address referrer;
    }

    function exists(User storage self) internal view returns (bool) {
        return self.investmentCount > 0;
    }
}