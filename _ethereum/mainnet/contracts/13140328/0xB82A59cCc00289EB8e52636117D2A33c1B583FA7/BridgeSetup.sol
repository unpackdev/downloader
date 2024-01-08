// contracts/BridgeSetup.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./BridgeGovernance.sol";

import "./ERC1967Upgrade.sol";

contract BridgeSetup is BridgeSetters, ERC1967Upgrade {
    function setup(
        address implementation,
        uint16 chainId,
        address wormhole,
        uint16 governanceChainId,
        bytes32 governanceContract,
        address tokenImplementation,
        address WETH
    ) public {
        setChainId(chainId);

        setWormhole(wormhole);

        setGovernanceChainId(governanceChainId);
        setGovernanceContract(governanceContract);

        setTokenImplementation(tokenImplementation);

        setWETH(WETH);

        setBridgeImplementation(1, bytes32(0xde98c4b175aa092f3ab2e3c47f5701ec7c104e30d152e33d31a29863c7504379));

        _upgradeTo(implementation);
    }
}
