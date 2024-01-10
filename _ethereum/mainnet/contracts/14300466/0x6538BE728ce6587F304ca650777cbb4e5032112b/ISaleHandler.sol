// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ISaleBuilder.sol";
import "./ISaleRunner.sol";
import "./ISaleEnder.sol";

/**
 * @title ISaleHandler
 *
 * @notice Handles the creation, running, and disposition of Seen.Haus sales.
 *
 * The ERC-165 identifier for this interface is: 0xa9ae54df
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
interface ISaleHandler is ISaleBuilder, ISaleRunner, ISaleEnder {}