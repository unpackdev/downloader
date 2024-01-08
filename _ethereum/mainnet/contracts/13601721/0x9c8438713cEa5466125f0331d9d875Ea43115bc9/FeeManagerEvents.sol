// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./Initializable.sol";

import "./AccessControl.sol";

import "./IFeeManager.sol";
import "./IPoolManager.sol";
import "./IStableMaster.sol";
import "./IPerpetualManager.sol";

/// @title FeeManagerEvents
/// @author Angle Core Team
/// @dev This file contains all the events that are triggered by the `FeeManager` contract
contract FeeManagerEvents {
    event UserAndSLPFeesUpdated(
        uint256 _collatRatio,
        uint64 _bonusMalusMint,
        uint64 _bonusMalusBurn,
        uint64 _slippage,
        uint64 _slippageFee
    );

    event FeeMintUpdated(uint256[] _xBonusMalusMint, uint64[] _yBonusMalusMint);

    event FeeBurnUpdated(uint256[] _xBonusMalusBurn, uint64[] _yBonusMalusBurn);

    event SlippageUpdated(uint256[] _xSlippage, uint64[] _ySlippage);

    event SlippageFeeUpdated(uint256[] _xSlippageFee, uint64[] _ySlippageFee);

    event HaFeesUpdated(uint64 _haFeeDeposit, uint64 _haFeeWithdraw);
}
