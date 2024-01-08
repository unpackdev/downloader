// lib/IDXStrategist.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CErc20.sol";
import "./CEther.sol";
import "./Comptroller.sol";
import "./CompoundVault.sol";
import "./IERC20Upgradeable.sol";



library CVaults{

struct  CompVault {
        uint256 id;
        uint256 tier;
        uint256 lastClaimBlock;
        uint256 fees;
        uint256 feeBase;
        uint256 mentissa;
        uint256 accumulatedCompPerShare;
        CompoundVault logic;
        IERC20Upgradeable asset;
        CErc20 collateral;
        IERC20Upgradeable protocolAsset;
        address protocollCollateral;
        address creator;
    }



}
