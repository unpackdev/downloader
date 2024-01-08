// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IDerivativeMain.sol";
import "./IDerivativeDeployment.sol";

/**
 * @title Interface that a derivative MUST have in order to be used in the pools
 */
interface IDerivative is IDerivativeDeployment, IDerivativeMain {

}
