//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./IDiamondCut.sol";
import "./IDiamondLoupe.sol";
import "./IFeeCalculator.sol";
import "./IFeeExternal.sol";
import "./IRouter.sol";
import "./IGovernance.sol";
import "./IUtility.sol";

interface IRouterDiamond is IGovernance, IDiamondCut, IDiamondLoupe, IFeeCalculator, IFeeExternal, IUtility, IRouter {}
