// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IMarketConfig.sol";
import "./IMarketConfigAdditional.sol";
import "./IMarketClerk.sol";

/**
 * @title IMarketController
 *
 * @notice Manages configuration and consignments used by the Seen.Haus contract suite.
 *
 * The ERC-165 identifier for this interface is: 0xbb8dba77
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
interface IMarketController is IMarketClerk, IMarketConfig, IMarketConfigAdditional {}