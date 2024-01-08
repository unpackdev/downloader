// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./TokenStaking.sol";

/// @title Manaage rewards for liquidity mining
contract LiquidityMiningReward is TokenStaking {
    constructor(
        address _MFI,
        address LiquidityToken,
        address _roles
    ) TokenStaking(_MFI, LiquidityToken, _roles) {}
}

// USDC - MFI pair token
// 0x9d640080af7c81911d87632a7d09cc4ab6b133ac

// on ropsten:
// 0xc4c79A0e1C7A9c79f1e943E3a5bEc65396a5434a
