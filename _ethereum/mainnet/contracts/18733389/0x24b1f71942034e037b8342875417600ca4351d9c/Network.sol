// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

library Network {
    function getCurrentNetworkId() internal view returns (bytes4) {
        return getNetworkIdFromChainId(uint32(block.chainid));
    }

    function getNetworkIdFromChainId(uint32 chainId) internal pure returns (bytes4) {
        bytes1 version = 0x01;
        bytes1 networkType = 0x01;
        bytes1 extraData = 0x00;
        return bytes4(sha256(abi.encode(version, networkType, chainId, extraData)));
    }

    function isCurrentNetwork(bytes4 networkId) internal view returns (bool) {
        return Network.getCurrentNetworkId() == networkId;
    }
}
