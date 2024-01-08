/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |    DECENTRALISED STAKING PROTOCOL FOR ETHEREUM    |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind Ethereum staking pool protocol, designed to
  *  be community-owned, decentralised, and trustless.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "./RocketBase.sol";
import "./RocketVaultInterface.sol";
import "./RocketDAOProtocolActionsInterface.sol";


import "./SafeMath.sol";
import "./IERC20.sol";


// The Rocket Pool Network DAO Actions - This is a placeholder for the network DAO to come
contract RocketDAOProtocolActions is RocketBase, RocketDAOProtocolActionsInterface { 

    using SafeMath for uint;

    // The namespace for any data stored in the network DAO (do not change)
    string constant daoNameSpace = "dao.protocol.";


    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        // Version
        version = 1;
    }


    /*** Action Methods ************************/

   
}
