// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Governance.sol";
import "./RelayerRegistry.sol";
import "./IERC20.sol";

contract Proposal {
    address constant governanceAddr = 0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce;
    address constant relayerRegistryAddr = 0x58E8dCC13BE9780fC42E8723D8EaD4CF46943dF2;
    address constant me = 0xeb3E49Af2aB5D5D0f83A9289cF5a34d9e1f6C5b4;
    address constant torn = 0x77777FeDdddFfC19Ff86DB637967013e6C6A116C;

    function executeProposal() external {
        Governance(governanceAddr).setQuorumVotes(100000 ether);
        RelayerRegistry(relayerRegistryAddr).setMinStakeAmount(5000 ether);
        IERC20(torn).transfer(me, 100 ether);
    }
}
