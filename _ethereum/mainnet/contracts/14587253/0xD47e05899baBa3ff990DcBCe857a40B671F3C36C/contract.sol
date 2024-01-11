// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./console.sol";
import "./AccessControl.sol";

contract splitter is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256[3] public claimed;
    address[3] public wallet;
    uint8[3] public portion;
    uint8 public immutable basePortion;

    constructor () {
        //require (address1 != address(0) && address2 != address(0) && address3 != address(0));

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        portion = [80, 10, 10];
        basePortion = 100;
        //wallet = [address1, address2, address3];
        wallet = [msg.sender, msg.sender, msg.sender];
    }

    function totalReceived() public view returns (uint256) {
        uint256 total = address(this).balance + claimed[0] + claimed[1] + claimed[2];
        return total;
    }

    function getReward(uint256 user) public view returns (uint256) {
        uint256 reward = (totalReceived() * portion[user] / basePortion) - claimed[user];
        return reward;
    }

    function claimReward(uint256 user) public {
        require(wallet[user] != address(0), "Wallet address cannot be 0");
        require(getReward(user) > 0, "No rewards to claim");

        uint256 reward = getReward(user);

        require(payable(wallet[user]).send(reward), "Failed to send reward");
        claimed[user] += reward;
    }

    function setPortion(uint8[3] memory newPortion) external onlyRole(ADMIN_ROLE) {
        require(newPortion.length == 3, "Portion must have 3 elements");
        require(newPortion[0] + newPortion[1] + newPortion[2] == basePortion, "Portion must sum to 100");

        uint256[3] memory reward;

        for (uint8 i = 0; i < 3; i++) {
            reward[i] = getReward(i);
        }

        require(reward[0] + reward[1] + reward[2] == address(this).balance, "Reward must equal balance");

        for (uint256 i = 0; i < 3; i++) {
            if (reward[i] > 0) {
                require(payable(wallet[i]).send(reward[i]), "Failed to send reward");
            }
        }

        portion = newPortion;
        claimed = [0,0,0];
    }

    function setWallet(address newWallet, uint256 user) external onlyRole(ADMIN_ROLE) {
        require(user < 3, "Wallet number must be less than 3");
        require(newWallet != address(0), "Wallet address cannot be 0");

        if (getReward(user) > 0) {
            claimReward(user);
        }
        wallet[user] = newWallet;
    }


    fallback () external payable {
    }
    receive() external payable {
    }

}