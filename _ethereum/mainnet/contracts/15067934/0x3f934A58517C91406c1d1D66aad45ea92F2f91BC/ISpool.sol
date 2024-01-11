// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./ISpoolExternal.sol";
import "./ISpoolReallocation.sol";
import "./ISpoolDoHardWork.sol";
import "./ISpoolStrategy.sol";
import "./ISpoolBase.sol";

/// @notice Utility Interface for central Spool implementation
interface ISpool is ISpoolExternal, ISpoolReallocation, ISpoolDoHardWork, ISpoolStrategy, ISpoolBase {}
