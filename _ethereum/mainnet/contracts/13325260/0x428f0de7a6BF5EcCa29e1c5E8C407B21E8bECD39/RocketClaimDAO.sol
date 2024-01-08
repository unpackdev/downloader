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
import "./RocketRewardsPoolInterface.sol";
import "./RocketClaimDAOInterface.sol";


// RPL Rewards claiming by the DAO
contract RocketClaimDAO is RocketBase, RocketClaimDAOInterface {

    // Events
    event RPLTokensSentByDAOProtocol(string invoiceID, address indexed from, address indexed to, uint256 amount, uint256 time);

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        // Version
        version = 1;
    }

    // Determine if this contract is enabled or not for claims
    function getEnabled() override external view returns (bool) {
        // Init the rewards pool contract
        RocketRewardsPoolInterface rewardsPool = RocketRewardsPoolInterface(getContractAddress("rocketRewardsPool"));
        return rewardsPool.getClaimingContractEnabled("rocketClaimDAO");
    }


    // Spend the network DAOs RPL rewards 
    function spend(string memory _invoiceID, address _recipientAddress, uint256 _amount) override external onlyLatestContract("rocketDAOProtocolProposals", msg.sender) {
        // Load contracts
        RocketVaultInterface rocketVault = RocketVaultInterface(getContractAddress("rocketVault"));
        // Addresses
        IERC20 rplToken = IERC20(getContractAddress("rocketTokenRPL"));
        // Some initial checks
        require(_amount > 0 && _amount <= rocketVault.balanceOfToken("rocketClaimDAO", rplToken), "You cannot send 0 RPL or more than the DAO has in its account");
        // Send now
        rocketVault.withdrawToken(_recipientAddress, rplToken, _amount);
        // Log it
        emit RPLTokensSentByDAOProtocol(_invoiceID, address(this), _recipientAddress, _amount, block.timestamp);
    }
  

}
