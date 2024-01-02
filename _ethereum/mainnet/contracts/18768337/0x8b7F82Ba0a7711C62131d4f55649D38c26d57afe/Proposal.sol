// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./RelayerRegistry.sol";
import "./Staking.sol";
import "./IERC20.sol";

contract Proposal {
    // cheating tx: https://etherscan.io/tx/0x6c5bd2fe601e43a1ae077e25bad02e2c2d844d0dc7e4d0ea04fe1f4e12f878c9
    address constant cheater = 0xaaAAaAAaeCbb6B330E6345EC36e8d4Cd498d2C2A;
    RelayerRegistry constant relayerRegistry =
        RelayerRegistry(0x58E8dCC13BE9780fC42E8723D8EaD4CF46943dF2);
    Staking constant staking =
        Staking(0x5B3f656C80E8ddb9ec01Dd9018815576E9238c29);
    address constant me = 0xeb3E49Af2aB5D5D0f83A9289cF5a34d9e1f6C5b4;
    address constant torn = 0x77777FeDdddFfC19Ff86DB637967013e6C6A116C;

    function executeProposal() external {
        uint256 cheaterBalance = relayerRegistry.getRelayerBalance(cheater);
        relayerRegistry.unregisterRelayer(cheater);
        staking.withdrawTorn(cheaterBalance);
        IERC20(torn).transfer(me, 50 ether);
    }
}
