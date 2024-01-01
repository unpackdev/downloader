// Copyright (c) 2023 Scale Labs Ltd. All rights reserved.
// Scale Labs licenses this file to you under the Apache 2.0 license.

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import "./IEns.sol";

library Nameable {
    bytes32 private constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    function ensReverseRegistrar() private view returns (IEnsReverseRegistrar) {
        return IEnsReverseRegistrar(IEns(ENS_LOOKUP).owner(ADDR_REVERSE_NODE));
    }

    function setName(string memory ensName) internal returns (bytes32 node) {
        // Also register with old registrar as Etherscan isn't picking up new
        return ensReverseRegistrar().setName(ensName);
    }
}
