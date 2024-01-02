// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Initializable.sol";

abstract contract AsterizmChainEnv is Initializable {

    uint8 constant private CHAIN_TYPE_EVM = 1;
    uint8 constant private CHAIN_TYPE_TVM = 2;

    struct ChainType {
        bool exists;
    }

    mapping(uint8 => ChainType) private chainTypes;

    /// Contract initializer (constructor)
    function __AsterizmChainEnv_init() initializer public {
        chainTypes[CHAIN_TYPE_EVM].exists = true;
        chainTypes[CHAIN_TYPE_TVM].exists = true;
    }

    /// Check is chain type awailable
    /// @param _chainType uint8  Chain type
    /// @return bool  Chain type awailable flag
    function _isChainTypeAwailable(uint8 _chainType) internal view returns(bool) {
        return chainTypes[_chainType].exists;
    }
}
