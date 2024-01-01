// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./RelayerRegistryProxy.sol";
import "./RelayerRegistry.sol";
import "./IERC20.sol";

contract Proposal {
    address public immutable newRelayerRegistry;
    address public constant relayerRegistryProxyAddr = 0x58E8dCC13BE9780fC42E8723D8EaD4CF46943dF2;
    address public constant tornTokenAddress = 0x77777FeDdddFfC19Ff86DB637967013e6C6A116C;
    address public constant me = 0xeb3E49Af2aB5D5D0f83A9289cF5a34d9e1f6C5b4;

    event RelayerRegistrationFailed(address relayer, string ensName, uint256 stake);

    constructor(address _newRelayerRegistry) public {
        newRelayerRegistry = _newRelayerRegistry;
    }

    function safeRegisterRelayerAdmin(address relayer, string memory ensName, uint256 newStake) public {
        try IRelayerRegistry(relayerRegistryProxyAddr).registerRelayerAdmin(relayer, ensName, newStake) {} catch {
            emit RelayerRegistrationFailed(relayer, ensName, newStake);
        }
    }

    function executeProposal() public {
        IRelayerRegistryProxy relayerRegistryProxy = IRelayerRegistryProxy(relayerRegistryProxyAddr);
        relayerRegistryProxy.upgradeTo(newRelayerRegistry);

        safeRegisterRelayerAdmin(0x4750BCfcC340AA4B31be7e71fa072716d28c29C5, "reltor.eth", 19612626855788464787775);
        safeRegisterRelayerAdmin(0xa0109274F53609f6Be97ec5f3052C659AB80f012, "relayer007.eth", 15242825423346070140850);
        safeRegisterRelayerAdmin(0xC49415493eB3Ec64a0F13D8AA5056f1CfC4ce35c, "k-relayer.eth", 11850064862377598277981);

        // Compensation for deployment, propose and exercution
        IERC20(tornTokenAddress).transfer(me, 100 ether);
    }
}
