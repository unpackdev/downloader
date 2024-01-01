// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./IPoolCore.sol";
import "./IPoolMarketplace.sol";
import "./IPoolParameters.sol";
import "./IParaProxyInterfaces.sol";
import "./IPoolPositionMover.sol";
import "./IPoolAAPositionMover.sol";
import "./IPoolApeStaking.sol";
import "./IPoolBorrowAndStake.sol";

/**
 * @title IPool
 *
 * @notice Defines the basic interface for an ParaSpace Pool.
 **/
interface IPool is
    IPoolCore,
    IPoolMarketplace,
    IPoolParameters,
    IPoolApeStaking,
    IParaProxyInterfaces,
    IPoolPositionMover,
    IPoolBorrowAndStake,
    IPoolAAPositionMover
{

}
