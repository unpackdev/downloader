// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Exchange.sol";

contract XCROWExchange is Exchange {
    string public constant name = "XCROW Exchange";

    string public constant version = "3.1";

    constructor(
        uint256 chainId,
        address[] memory registryAddrs,
        bytes memory customPersonalSignPrefix
    ) Exchange() {
        DOMAIN_SEPARATOR = hash(
            EIP712Domain({
                name: name,
                version: version,
                chainId: chainId,
                verifyingContract: address(this)
            })
        );
        for (uint256 ind = 0; ind < registryAddrs.length; ind++) {
            registries[registryAddrs[ind]] = true;
        }
        if (customPersonalSignPrefix.length > 0) {
            personalSignPrefix = customPersonalSignPrefix;
        }
    }
}
