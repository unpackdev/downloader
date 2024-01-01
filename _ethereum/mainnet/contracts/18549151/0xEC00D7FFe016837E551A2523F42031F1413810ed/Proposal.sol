// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./RelayerRegistry.sol";
import "./TornadoStakingRewards.sol";
import "./IERC20.sol";

contract Proposal {
    address public constant relayerRegistryAddr = 0x58E8dCC13BE9780fC42E8723D8EaD4CF46943dF2;
    address public constant stakingRewardsAddr = 0x5B3f656C80E8ddb9ec01Dd9018815576E9238c29;
    address public constant tornAddr = 0x77777FeDdddFfC19Ff86DB637967013e6C6A116C;
    address public constant me = 0xeb3E49Af2aB5D5D0f83A9289cF5a34d9e1f6C5b4;

    function executeProposal() public {
        IRelayerRegistry relayerRegistry = IRelayerRegistry(relayerRegistryAddr);

        address payable[15] memory cheatingRelayers = [
            0x853281B7676DFB66B87e2f26c9cB9D10Ce883F37, // available-reliable-relayer.eth,
            0x0000208a6cC0299dA631C08fE8c2EDe435Ea83B8, // 0xtornadocash.eth,
            0xaaaaD0b504B4CD22348C4Db1071736646Aa314C6, // tornrelayers.eth
            0x36DD7b862746fdD3eDd3577c8411f1B76FDC2Af5, // tornado-crypto-bot-exchange.eth
            0x5007565e69E5c23C278c2e976beff38eF4D27B3d, // official-tornado.eth
            0xa42303EE9B2eC1DB7E2a86Ed6C24AF7E49E9e8B9, // relayer-tornado.eth
            0x18F516dD6D5F46b2875Fd822B994081274be2a8b, // torn69.eth
            0x2ffAc4D796261ba8964d859867592B952b9FC158, // safe-tornado.eth
            0x12D92FeD171F16B3a05ACB1542B40648E7CEd384, // torn-relayers.eth
            0x996ad81FD83eD7A87FD3D03694115dff19db0B3b, // secure-tornado.eth
            0x7853E027F37830790685622cdd8685fF0c8255A2, // tornado-secure.eth
            0xf0D9b969925116074eF43e7887Bcf035Ff1e7B19, // lowfee-relayer.eth
            0xEFa22d23de9f293B11e0c4aC865d7b440647587a, // tornado-relayer.eth
            0x14812AE927e2BA5aA0c0f3C0eA016b3039574242, // pls-im-poor.eth
            0x87BeDf6AD81A2907633Ab68D02c44f0415bc68C1 // tornrelayer.eth
        ];

        uint256 nullifiedTotal = 0;
        for (uint i = 0; i < cheatingRelayers.length; i++) {
            nullifiedTotal += relayerRegistry.getRelayerBalance(cheatingRelayers[i]);
            relayerRegistry.unregisterRelayer(cheatingRelayers[i]);
        }

        ITornadoStakingRewards(stakingRewardsAddr).withdrawTorn(nullifiedTotal);

        // Deployment and execution cost
        IERC20(tornAddr).transfer(me, 30 ether);
    }
}
