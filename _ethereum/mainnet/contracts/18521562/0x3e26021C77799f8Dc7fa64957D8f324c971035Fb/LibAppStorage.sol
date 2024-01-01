// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * \
 * Junkyard Contract - Razmo
 * Diamond Contract - Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
 * EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
 * /*****************************************************************************
 */

import "./VRFConsumerBaseV2.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./IERC721.sol";

import "./LinkTokenInterface.sol";
import "./IRouterClient.sol";

import "./LibDiamond.sol";

/**
 * @dev Struct for storing the state variables of the contract.
 */
struct AppStorage {
    address botAddress;
    address managerAddress;
    uint256 price;
    // Chainlink CCIP
    IRouterClient CCIPRouter; // The address of the router contract.
    uint64 CCIPdestinationChainSelector; // The chain selector of the destination chaind
    address CCIPReceiver;
    // Fish
    uint256 fishCount;
    // Claim
    address storageAddress;
    address linkTokenAddr;
}

library LibAppStorage {
    /**
     * @notice Provides access to the contract's AppStorage struct.
     * @return s The AppStorage struct of the contract.
     */
    function appStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;

    /**
     * @notice Modifier to restrict access to only contract owner or bots.
     * @dev Checks if the caller is either the contract owner or a bot.
     */
    modifier onlyBotOrOwner() {
        require(s.botAddress == msg.sender || LibDiamond.contractOwner() == msg.sender, "Not allowed");
        _;
    }
}
