// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./SeenTypes.sol";
import "./IMarketHandler.sol";
import "./IAuctionBuilder.sol";
import "./IAuctionRunner.sol";
import "./IAuctionEnder.sol";


/**
 * @title IAuctionHandler
 *
 * @notice Handles the creation, running, and disposition of Seen.Haus auctions.
 *
 * The ERC-165 identifier for this interface is: 0xa8190853
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
interface IAuctionHandler is IAuctionBuilder, IAuctionRunner, IAuctionEnder {

}