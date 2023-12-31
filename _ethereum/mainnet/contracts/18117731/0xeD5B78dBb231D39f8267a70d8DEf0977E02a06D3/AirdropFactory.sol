// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Airdrop.sol";

contract AirdropFactory {
    event AirdropCreated(address indexed airdrop, address indexed token, address indexed owner);

    function createAirdrop(address owner, address token) external returns (address) {
        address airdrop = address(new Airdrop(owner, token));
        emit AirdropCreated(airdrop, token, msg.sender);
        return airdrop;
    }
}