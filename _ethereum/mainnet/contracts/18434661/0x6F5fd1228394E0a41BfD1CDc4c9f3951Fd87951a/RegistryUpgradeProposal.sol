// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./RelayerRegistryProxy.sol";
import "./RelayerRegistry.sol";
import "./EnsNamehash.sol";
import "./ENS.sol";

contract Proposal is EnsResolve {
    using ENSNamehash for bytes;

    address immutable newRelayerRegistry;
    address constant relayerRegistryProxyAddr = 0x58E8dCC13BE9780fC42E8723D8EaD4CF46943dF2;

    constructor(address _newRelayerRegistry) public {
        newRelayerRegistry = _newRelayerRegistry;
    }

    function executeProposal() public {
        IRelayerRegistryProxy relayerRegistryProxy = IRelayerRegistryProxy(relayerRegistryProxyAddr);
        relayerRegistryProxy.upgradeTo(newRelayerRegistry);

        string[5] memory cheatingRelayers = [
            "available-reliable-relayer.eth",
            "0xtornadocash.eth",
            "0xtorn365.eth",
            "tornrelayers.eth",
            "moon-relayer.eth"
        ];
        for (uint i = 0; i < cheatingRelayers.length; i++) {
            address cheatingRelayer = resolve(bytes(cheatingRelayers[i]).namehash());
            IRelayerRegistry(relayerRegistryProxyAddr).unregisterRelayer(cheatingRelayer);
        }
    }
}
