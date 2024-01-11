// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "./BondPriceLib.sol";
import "./AccrualBondLib.sol";

contract AccrualBondStorageV1 {
    
    /// @notice address that receives revenue
    address public beneficiary;
    
    /// @notice bond payout token
    address public outputToken;

    /// @notice total amount currently outstanding to bonders
    uint256 public totalDebt;
    
    /// @notice virtual output token reserves used in pricing
    uint256 public virtualOutputReserves;
    
    /// @notice total amount of assets currently exchangeable for bonds
    uint256 public totalAssets;
    
    /// @notice length after bond purchase when bond is fully redeemable
    uint256 public term;
    
    /// @notice tracks how many output tokens have been emitted since the last veBase
    uint256 public cnvEmitted;
    
    /// @notice tracks the amount that policy it allowed to mint
    uint256 public policyMintAllowance;

    /// @notice mapping containing pricing info for exchangeable assets
    mapping(address => BondPriceLib.QuotePriceInfo) public quoteInfo;
    
    /// @notice mapping containing posistions for individual users
    mapping(address => AccrualBondLib.Position[]) public positions;
}
