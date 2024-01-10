// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IVaderMinter {
    struct Limits {
        uint256 fee;
        uint256 mintLimit;
        uint256 burnLimit;
    }

    event PublicMintCapChanged(
        uint256 previousPublicMintCap,
        uint256 publicMintCap
    );

    event PublicMintFeeChanged(
        uint256 previousPublicMintFee,
        uint256 publicMintFee
    );

    event PartnerMintCapChanged(
        uint256 previousPartnerMintCap,
        uint256 partnerMintCap
    );

    event PartnerMintFeeChanged(
        uint256 previousPartnercMintFee,
        uint256 partnerMintFee
    );

    event DailyLimitsChanged(Limits previousLimits, Limits nextLimits);
    event WhitelistPartner(
        address partner,
        uint256 mintLimit,
        uint256 burnLimit,
        uint256 fee
    );

    function lbt() external view returns (address);

    // The 24 hour limits on USDV mints that are available for public minting and burning as well as the fee.
    function dailyLimits() external view returns (Limits memory);

    // The current cycle end timestamp
    function cycleTimestamp() external view returns (uint);

    // The current cycle cumulative mints
    function cycleMints() external view returns (uint);

    // The current cycle cumulative burns
    function cycleBurns() external view returns (uint);

    function partnerLimits(address) external view returns (Limits memory);

    // USDV Contract for Mint / Burn Operations
    function usdv() external view returns (address);

    function partnerMint(uint256 vAmount, uint256 uAmountMinOut) external returns (uint256 uAmount);

    function partnerBurn(uint256 uAmount, uint256 vAmountMinOut) external returns (uint256 vAmount);
}
