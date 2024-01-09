// SPDX-License-Identifier: MIT AND AGPL-3.0-or-later

pragma solidity =0.8.9;

interface IUSDV {
    /* ========== ENUMS ========== */

    enum LockTypes {
        USDV,
        VADER
    }

    /* ========== STRUCTS ========== */

    struct Lock {
        LockTypes token;
        uint256 amount;
        uint256 release;
    }

    /* ========== FUNCTIONS ========== */

    function mint(
        address account,
        uint256 vAmount,
        uint256 uAmount,
        uint256 exchangeFee,
        uint256 window
    ) external returns (uint256);

    function burn(
        address account,
        uint256 uAmount,
        uint256 vAmount,
        uint256 exchangeFee,
        uint256 window
    ) external returns (uint256);

    /* ========== EVENTS ========== */

    event ExchangeFeeChanged(uint256 previousExchangeFee, uint256 exchangeFee);
    event DailyLimitChanged(uint256 previousDailyLimit, uint256 dailyLimit);
    event LockClaimed(
        address user,
        LockTypes lockType,
        uint256 lockAmount,
        uint256 lockRelease
    );
    event LockCreated(
        address user,
        LockTypes lockType,
        uint256 lockAmount,
        uint256 lockRelease
    );
    event ValidatorSet(address previous, address current);
    event GuardianSet(address previous, address current);
    event LockStatusSet(bool status);
    event MinterSet(address minter);
}
