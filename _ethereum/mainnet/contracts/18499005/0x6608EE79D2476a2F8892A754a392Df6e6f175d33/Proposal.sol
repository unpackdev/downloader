// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./RelayerRegistryProxy.sol";
import "./RelayerRegistry.sol";

contract Proposal {
    address public immutable newRelayerRegistry;
    address public constant relayerRegistryProxyAddr = 0x58E8dCC13BE9780fC42E8723D8EaD4CF46943dF2;

    constructor(address _newRelayerRegistry) public {
        newRelayerRegistry = _newRelayerRegistry;
    }

    function getNullifiedTotal(address payable[15] memory relayers) public view returns (uint256) {
        uint256 nullifiedTotal;

        for (uint8 i = 0; i < relayers.length; i++) {
            nullifiedTotal += IRelayerRegistry(relayerRegistryProxyAddr).getRelayerBalance(relayers[i]);
        }

        return nullifiedTotal;
    }

    function executeProposal() public {
        IRelayerRegistryProxy relayerRegistryProxy = IRelayerRegistryProxy(relayerRegistryProxyAddr);
        relayerRegistryProxy.upgradeTo(newRelayerRegistry);

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

        IRelayerRegistry relayerRegistry = IRelayerRegistry(relayerRegistryProxyAddr);

        uint256 nullifiedTotal = getNullifiedTotal(cheatingRelayers);
        uint256 compensation = nullifiedTotal / 3;

        for (uint i = 0; i < cheatingRelayers.length; i++) {
            relayerRegistry.unregisterRelayer(cheatingRelayers[i]);
        }

        relayerRegistry.registerRelayerAdmin(
            0x4750BCfcC340AA4B31be7e71fa072716d28c29C5,
            "reltor.eth",
            19612626855788464787775 + compensation
        );
        relayerRegistry.registerRelayerAdmin(
            0xa0109274F53609f6Be97ec5f3052C659AB80f012,
            "relayer007.eth",
            15242825423346070140850 + compensation
        );
        relayerRegistry.registerRelayerAdmin(
            0xC49415493eB3Ec64a0F13D8AA5056f1CfC4ce35c,
            "k-relayer.eth",
            11850064862377598277981 + compensation
        );

        relayerRegistry.setOperator(address(0));
    }
}
