/* SPDX-License-Identifier: MIT
    Check more details about $LEAN at https://leantoken.io/
*/
pragma solidity ^0.8.4;

import "./IERC20.sol";

contract JobPlacementAndCommunityWallet {
    IERC20 public token;
    uint today;

    constructor(address erc20_contract) {
        token = IERC20(erc20_contract);
        today = 0;
    }

    function balancing_management() payable public {
        require (block.timestamp >= today + 30.42 days, "you are trying to run a procedure before the time expires");

        address dead_wallet = 0x000000000000000000000000000000000000dEaD;
        address salary_wallet = 0x5dc41aFACA5B5312A90f808F27F25AC3C4FA303d;

        uint256 tokens_to_burn = token.balanceOf(address(this)) / 40;
        uint256 tokens_to_send = (token.balanceOf(address(this))  - tokens_to_burn) / 168;

        today = block.timestamp;

        token.transfer(dead_wallet, tokens_to_burn);
        token.transfer(salary_wallet, tokens_to_send);
    }
}