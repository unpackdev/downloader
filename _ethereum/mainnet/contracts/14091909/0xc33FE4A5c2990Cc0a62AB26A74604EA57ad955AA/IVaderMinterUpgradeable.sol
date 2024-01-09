// SPDX-License-Identifier: MIT AND AGPL-3.0-or-later

pragma solidity =0.8.9;

import "./VaderMinterStorage.sol";

interface IVaderMinterUpgradeable {
    /* ========== FUNCTIONS ========== */
    function mint(uint256 vAmount, uint256 uAmountMinOut)
        external
        returns (uint256 uAmount);

    function burn(uint256 uAmount, uint256 vAmountMinOut)
        external
        returns (uint256 vAmount);

    function partnerMint(uint256 vAmount, uint256 uAmountMinOut)
        external
        returns (uint256 uAmount);

    function partnerBurn(uint256 uAmount, uint256 vAmountMinOut)
        external
        returns (uint256 vAmount);

    /* ========== EVENTS ========== */

    event DailyLimitsChanged(Limits previousLimits, Limits nextLimits);
    event WhitelistPartner(
        address partner,
        uint256 mintLimit,
        uint256 burnLimit,
        uint256 fee
    );
    event RemovePartner(address partner);
    event SetPartnerFee(address indexed partner, uint256 fee);
    event IncreasePartnerMintLimit(address indexed partner, uint256 mintLimit);
    event DecreasePartnerMintLimit(address indexed partner, uint256 mintLimit);
    event IncreasePartnerBurnLimit(address indexed partner, uint256 burnLimit);
    event DecreasePartnerBurnLimit(address indexed partner, uint256 burnLimit);
    event SetPartnerLockDuration(address indexed partner, uint256 lockDuration);
}
