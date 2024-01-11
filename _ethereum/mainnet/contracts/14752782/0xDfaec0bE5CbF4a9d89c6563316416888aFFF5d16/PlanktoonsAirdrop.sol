//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*

    Planktoons airdrop contract
        https://planktoons.io

*/

import "./MerkleAirdrop.sol";

contract PlanktoonsAirdrop is MerkleAirdrop {
    string public constant name = "PlanktoonsAirdrop";
}
