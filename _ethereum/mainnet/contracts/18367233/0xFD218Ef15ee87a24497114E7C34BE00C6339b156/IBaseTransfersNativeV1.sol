// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./ICoreTransfersNativeV1.sol";
import "./IBaseTransfersV1.sol";

// This interface cannot be implemented on BaseTransfers.sol, but it's accurate
// since BaseTransfers.sol only inherits and overrides methods, and does not define
// additional public/external methods.
interface IBaseTransfersNativeV1 is ICoreTransfersNativeV1, IBaseTransfersV1 {

}
