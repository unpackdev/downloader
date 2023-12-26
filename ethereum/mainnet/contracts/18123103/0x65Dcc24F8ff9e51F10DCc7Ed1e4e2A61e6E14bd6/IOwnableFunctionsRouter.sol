// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IFunctionsRouter.sol";
import "./IOwnable.sol";

/// @title Chainlink Functions Router interface with Ownability.
interface IOwnableFunctionsRouter is IOwnable, IFunctionsRouter {

}
