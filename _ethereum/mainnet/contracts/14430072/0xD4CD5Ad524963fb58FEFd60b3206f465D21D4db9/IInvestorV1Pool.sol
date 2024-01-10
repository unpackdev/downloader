// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IInvestorV1PoolImmutables.sol";
import "./IInvestorV1PoolState.sol";
import "./IInvestorV1PoolDerivedState.sol";
import "./IInvestorV1PoolActions.sol";
import "./IInvestorV1PoolOperatorActions.sol";
import "./IInvestorV1PoolEvents.sol";

interface IInvestorV1Pool is 
    IInvestorV1PoolImmutables,
    IInvestorV1PoolState,
    IInvestorV1PoolDerivedState,
    IInvestorV1PoolActions,
    IInvestorV1PoolOperatorActions,
    IInvestorV1PoolEvents 
{

}