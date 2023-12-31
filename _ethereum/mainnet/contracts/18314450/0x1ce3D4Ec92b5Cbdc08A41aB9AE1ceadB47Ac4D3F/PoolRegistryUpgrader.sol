// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./UpgraderBase.sol";

contract PoolRegistryUpgrader is UpgraderBase {
    constructor(address _owner) {
        transferOwnership(_owner);
    }

    /// @inheritdoc UpgraderBase
    function _calls() internal pure virtual override returns (bytes[] memory _callsList) {
        _callsList = new bytes[](3);
        _callsList[0] = abi.encodeWithSignature("masterOracle()");
        _callsList[1] = abi.encodeWithSignature("feeCollector()");
        _callsList[2] = abi.encodeWithSignature("governor()");
    }
}

contract PoolRegistryUpgraderV2 is PoolRegistryUpgrader {
    // solhint-disable-next-line no-empty-blocks
    constructor(address _owner) PoolRegistryUpgrader(_owner) {}

    /// @inheritdoc UpgraderBase
    function _calls() internal pure override returns (bytes[] memory _callsList) {
        _callsList = new bytes[](8);
        _callsList[0] = abi.encodeWithSignature("governor()");
        _callsList[1] = abi.encodeWithSignature("masterOracle()");
        _callsList[2] = abi.encodeWithSignature("feeCollector()");
        _callsList[3] = abi.encodeWithSignature("nativeTokenGateway()");
        _callsList[4] = abi.encodeWithSignature("nextPoolId()");
        _callsList[5] = abi.encodeWithSignature("swapper()");
        _callsList[6] = abi.encodeWithSignature("quoter()");
        _callsList[7] = abi.encodeWithSignature("crossChainDispatcher()");
    }
}
