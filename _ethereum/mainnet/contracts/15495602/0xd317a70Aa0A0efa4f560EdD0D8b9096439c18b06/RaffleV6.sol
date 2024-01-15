//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./RaffleV5.sol";

contract RaffleV6 is RaffleV5 {
    function initializeV6() public reinitializer(6) {
        GENESIS_OFFSET = 0;
        keyNFTClaimed[84060628940425386830944862847235387962585941726956624089304862388272278536193] = true;
        keyNFTClaimed[84060628940425386830944862847235387962585941726956624089304862393769836675073] = true;
    }
}