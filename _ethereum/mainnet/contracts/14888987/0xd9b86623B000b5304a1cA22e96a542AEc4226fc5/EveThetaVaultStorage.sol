// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

abstract contract EveThetaVaultStorageV1 {
    // Logic contract used to price options
    address public optionsPremiumPricer;
    // Logic contract used to select strike prices
    address public strikeSelection;
    // Premium discount on options we are selling (thousandths place: 000 - 999)
    uint256 public premiumDiscount;
    // Current oToken premium
    uint256 public currentOtokenPremium;
    // Last round id at which the strike was manually overridden
    uint16 public lastStrikeOverrideRound;
    // Price last overridden strike set to
    uint256 public overriddenStrikePrice;
    // Auction duration
    uint256 public auctionDuration;
    // Auction id of current option
    uint256 public optionAuctionID;
    // Amount locked for scheduled withdrawals last week;
    uint256 public lastQueuedWithdrawAmount;
    // Auction will be denominated in USDC if true
    bool public isUsdcAuction;
    // Path for swaps
    bytes public swapPath;
    // LiquidityGauge contract for the vault
    address public liquidityGauge;
}

// We are following Compound's method of upgrading new contract implementations
// When we need to add new storage variables, we create a new version of EveThetaVaultStorage
// e.g. EveThetaVaultStorage<versionNumber>, so finally it would look like
// contract EveThetaVaultStorage is EveThetaVaultStorageV1, EveThetaVaultStorageV2
abstract contract EveThetaVaultStorage is
    EveThetaVaultStorageV1
{

}
